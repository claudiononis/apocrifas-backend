CLASS zcl_apoc_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_serializable_object.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single_tx_uncontr.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.

    METHODS process_pending
      RETURNING
        VALUE(rv_log) TYPE string.

ENDCLASS.


CLASS zcl_apoc_job IMPLEMENTATION.


  METHOD if_bgmc_op_single_tx_uncontr~execute.

    process_pending( ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    out->write(
      process_pending( )
    ).

  ENDMETHOD.


  METHOD process_pending.

    "------------------------------------------------------------
    " 1. Buscar corridas pendientes
    "------------------------------------------------------------
    SELECT
      FROM zapoc_run
      FIELDS
        run_id,
        modo_test,
        contenido,
        file_content,
        file_name
      WHERE estado = 'PENDIENTE'
      INTO TABLE @DATA(lt_runs).


    "------------------------------------------------------------
    " 2. Nada para procesar
    "------------------------------------------------------------
    IF lt_runs IS INITIAL.

      rv_log = 'No hay corridas APOC PENDIENTES'.

      RETURN.

    ENDIF.


    DATA(lo_processor) =
      NEW zcl_apoc_processor( ).

    DATA(lo_writer) =
      NEW zcl_apoc_writer( ).


    "------------------------------------------------------------
    " 3. Procesar cada corrida pendiente
    "------------------------------------------------------------
    LOOP AT lt_runs INTO DATA(ls_run).

      TRY.

          "------------------------------------------------------
          " Marcar corrida como procesando
          "------------------------------------------------------
          GET TIME STAMP FIELD DATA(lv_start_ts).

          UPDATE zapoc_run
            SET estado          = 'PROCESANDO',
                mensaje_error   = '',
                last_changed_at = @lv_start_ts
            WHERE run_id        = @ls_run-run_id.

          COMMIT WORK.


          "------------------------------------------------------
          " 4. Obtener contenido textual
          "
          " Puede venir:
          " - de CONTENIDO
          " - de FILE_CONTENT (XSTRING)
          "------------------------------------------------------
          DATA lv_content TYPE string.

          CLEAR lv_content.


          IF ls_run-file_content IS NOT INITIAL.

            TRY.

                DATA(lo_converter) =
                  cl_abap_conv_codepage=>create_in( ).

                lv_content =
                  lo_converter->convert(
                    ls_run-file_content
                  ).

              CATCH cx_root.

                "------------------------------------------------
                " Si falla conversión del archivo, usar CONTENIDO
                "------------------------------------------------
                lv_content = ls_run-contenido.

            ENDTRY.

          ELSE.

            lv_content = ls_run-contenido.

          ENDIF.


          "------------------------------------------------------
          " 5. Validar contenido
          "------------------------------------------------------
          IF lv_content IS INITIAL.

            GET TIME STAMP FIELD DATA(lv_empty_ts).

            UPDATE zapoc_run
              SET estado          = 'ERROR',
                  mensaje_error   = 'La corrida no contiene datos para procesar',
                  last_changed_at = @lv_empty_ts
              WHERE run_id        = @ls_run-run_id.

            COMMIT WORK.

            rv_log =
              |{ rv_log }RUN sin contenido: { ls_run-run_id } / |.

            CONTINUE.

          ENDIF.


          "------------------------------------------------------
          " 6. Ejecutar procesamiento principal
          "
          " PROCESSOR
          "   -> INGESTA
          "      -> PARSER
          "      -> MATCHER
          "      -> ZAPOC_STG
          "   -> actualiza ZAPOC_RUN
          "------------------------------------------------------
          DATA(ls_process_result) =
            lo_processor->process(
              iv_run_id  = ls_run-run_id
              iv_content = lv_content
            ).


          "------------------------------------------------------
          " 7. Si Processor falló, no ejecutar Writer
          "------------------------------------------------------
          IF ls_process_result-status <> 'TERMINADO'.

            GET TIME STAMP FIELD DATA(lv_process_error_ts).

            UPDATE zapoc_run
              SET estado          = 'ERROR',
                  mensaje_error   = @ls_process_result-message,
                  last_changed_at = @lv_process_error_ts
              WHERE run_id        = @ls_run-run_id.

            COMMIT WORK.

            rv_log =
              |{ rv_log }RUN ERROR PROCESSOR: { ls_run-run_id } / |.

            CONTINUE.

          ENDIF.


          "------------------------------------------------------
          " 8. Ejecutar Writer
          "
          " MODO_TEST = X
          "   -> simulación
          "   -> NO modifica Supplier
          "
          " MODO_TEST = vacío
          "   -> actualmente Writer devuelve NO_IMPLEMENTADO
          "   -> tampoco modifica Supplier
          "------------------------------------------------------
          DATA(ls_writer_result) =
            lo_writer->execute(
              iv_run_id    = ls_run-run_id
              iv_test_mode = ls_run-modo_test
            ).


          "------------------------------------------------------
          " 9. Resolver estado final
          "------------------------------------------------------
          GET TIME STAMP FIELD DATA(lv_end_ts).


          IF ls_run-modo_test = abap_true.

            "----------------------------------------------------
            " TEST: el resultado esperado es SIMULADO
            "----------------------------------------------------
            IF ls_writer_result-status = 'SIMULADO'.

              UPDATE zapoc_run
                SET estado          = 'TERMINADO',
                    mensaje_error   = '',
                    last_changed_at = @lv_end_ts
                WHERE run_id        = @ls_run-run_id.

              COMMIT WORK.

              rv_log =
                |{ rv_log }| &&
                |RUN TEST OK: { ls_run-run_id } | &&
                |registros={ ls_process_result-total_registros } | &&
                |validos={ ls_process_result-total_validos } | &&
                |match={ ls_process_result-total_match } | &&
                |simulados={ ls_writer_result-total_simulados } / |.

            ELSE.

              UPDATE zapoc_run
                SET estado          = 'ERROR',
                    mensaje_error   = @ls_writer_result-message,
                    last_changed_at = @lv_end_ts
                WHERE run_id        = @ls_run-run_id.

              COMMIT WORK.

              rv_log =
                |{ rv_log }RUN ERROR WRITER TEST: { ls_run-run_id } / |.

            ENDIF.


          ELSE.

            "----------------------------------------------------
            " REAL:
            "
            " El bloqueo todavía NO está implementado.
            " Nunca debemos marcar TERMINADO como si hubiéramos
            " bloqueado proveedores.
            "----------------------------------------------------
            IF ls_writer_result-status = 'NO_IMPLEMENTADO'.

              UPDATE zapoc_run
                SET estado          = 'NO_IMPLEMENTADO',
                    mensaje_error   = @ls_writer_result-message,
                    last_changed_at = @lv_end_ts
                WHERE run_id        = @ls_run-run_id.

              COMMIT WORK.

              rv_log =
                |{ rv_log }| &&
                |RUN REAL NO IMPLEMENTADO: { ls_run-run_id } / |.

            ELSE.

              UPDATE zapoc_run
                SET estado          = 'ERROR',
                    mensaje_error   = @ls_writer_result-message,
                    last_changed_at = @lv_end_ts
                WHERE run_id        = @ls_run-run_id.

              COMMIT WORK.

              rv_log =
                |{ rv_log }RUN ERROR WRITER REAL: { ls_run-run_id } / |.

            ENDIF.

          ENDIF.


        CATCH cx_root INTO DATA(lx_error).

          "------------------------------------------------------
          " 10. Error inesperado
          "------------------------------------------------------
          DATA(lv_error_message) =
            lx_error->get_text( ).

          GET TIME STAMP FIELD DATA(lv_error_ts).

          UPDATE zapoc_run
            SET estado          = 'ERROR',
                mensaje_error   = @lv_error_message,
                last_changed_at = @lv_error_ts
            WHERE run_id        = @ls_run-run_id.

          COMMIT WORK.

          rv_log =
            |{ rv_log }| &&
            |RUN EXCEPTION: { ls_run-run_id } | &&
            |{ lv_error_message } / |.

      ENDTRY.

    ENDLOOP.


    "------------------------------------------------------------
    " 11. Fin
    "------------------------------------------------------------
    IF rv_log IS INITIAL.

      rv_log = 'Procesamiento APOC finalizado'.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
