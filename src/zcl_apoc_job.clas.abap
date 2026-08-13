CLASS zcl_apoc_job DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single_tx_uncontr.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    METHODS process_pending RETURNING VALUE(rv_log) TYPE string.
ENDCLASS.
CLASS zcl_apoc_job IMPLEMENTATION.
  METHOD if_bgmc_op_single_tx_uncontr~execute. process_pending( ). ENDMETHOD.
  METHOD if_oo_adt_classrun~main. out->write( process_pending( ) ). ENDMETHOD.
  METHOD process_pending.
    SELECT run_id, modo_test, contenido, file_content FROM zapoc_run WHERE estado = 'PENDIENTE' INTO TABLE @DATA(lt_runs).
    IF lt_runs IS INITIAL. rv_log = 'No hay corridas APOC PENDIENTES'. RETURN. ENDIF.
    DATA(lo_ingesta) = NEW zcl_apoc_ingesta( ). DATA(lo_processor) = NEW zcl_apoc_processor( ).
    LOOP AT lt_runs INTO DATA(ls_run).
      TRY.
          UPDATE zapoc_run SET estado = 'PROCESANDO' WHERE run_id = @ls_run-run_id. COMMIT WORK.
          DATA lv_text TYPE string.
          IF ls_run-file_content IS NOT INITIAL.
            lv_text = cl_abap_conv_codepage=>create_in( )->convert( ls_run-file_content ).
          ELSE. lv_text = ls_run-contenido. ENDIF.
          DATA(ls_ing) = lo_ingesta->ingest( iv_run_id = ls_run-run_id iv_content = lv_text ).
          DATA(ls_res) = lo_processor->process( iv_run_id = ls_run-run_id iv_test_mode = abap_true ).
          GET TIME STAMP FIELD DATA(lv_ts).
          UPDATE zapoc_run SET estado = 'TERMINADO', total_registros = @ls_ing-total_rows, total_validos = @ls_ing-valid_rows,
            total_match = @ls_ing-found, total_no_encontr = @ls_ing-not_found, total_errores = @ls_ing-invalid,
            total_bloqueables = @ls_res-to_block, last_changed_at = @lv_ts WHERE run_id = @ls_run-run_id.
          COMMIT WORK.
          rv_log = |{ rv_log } run procesado;|.
        CATCH cx_root INTO DATA(lx).
          GET TIME STAMP FIELD DATA(lv_err_ts). DATA(lv_msg) = lx->get_text( ).
          UPDATE zapoc_run SET estado = 'ERROR', mensaje_error = @lv_msg, last_changed_at = @lv_err_ts WHERE run_id = @ls_run-run_id.
          COMMIT WORK.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
