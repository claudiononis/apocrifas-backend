CLASS zcl_apoc_bg_test_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_bg_test_runner IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA lv_run_id    TYPE sysuuid_x16.
    DATA lv_timestamp TYPE timestampl.
    DATA lv_content   TYPE string.


    "------------------------------------------------------------
    " 1. Generar RUN_ID
    "------------------------------------------------------------
    TRY.

        lv_run_id =
          cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).

        out->write(
          |ERROR UUID: { lx_uuid->get_text( ) }|
        ).

        RETURN.

    ENDTRY.


    "------------------------------------------------------------
    " 2. Preparar CSV de prueba
    "------------------------------------------------------------
    lv_content =
      |# TEST bgPF APOC{ cl_abap_char_utilities=>newline }| &&
      |30712345678,01/08/2026,05/08/2026,Proveedor test{ cl_abap_char_utilities=>newline }| &&
      |2012345678,02/08/2026,06/08/2026,CUIT invalido|.


    "------------------------------------------------------------
    " 3. Obtener estructura compatible con ZAPOC_RUN
    "------------------------------------------------------------
    SELECT SINGLE
           *
      FROM zapoc_run
      WHERE run_id = @lv_run_id
      INTO @DATA(ls_run).


    CLEAR ls_run.

    GET TIME STAMP FIELD lv_timestamp.


    "------------------------------------------------------------
    " 4. Crear corrida PENDIENTE en modo TEST
    "------------------------------------------------------------
    ls_run-run_id          = lv_run_id.
    ls_run-modo_test       = abap_true.
    ls_run-estado          = 'PENDIENTE'.
    ls_run-contenido       = lv_content.
    ls_run-file_name       = 'bgpf_test.csv'.
    ls_run-mime_type       = 'text/csv'.
    ls_run-created_by      = sy-uname.
    ls_run-created_at      = lv_timestamp.
    ls_run-last_changed_at = lv_timestamp.


    INSERT zapoc_run
      FROM @ls_run.

    IF sy-subrc <> 0.

      out->write(
        |ERROR creando ZAPOC_RUN. SY-SUBRC={ sy-subrc }|
      ).

      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 5. Confirmar creación antes de encolar bgPF
    "------------------------------------------------------------
    COMMIT WORK.


    out->write(
      |========================================|
    ).

    out->write(
      |TEST bgPF APOC|
    ).

    out->write(
      |========================================|
    ).

    out->write(
      |RUN_ID creado: { lv_run_id }|
    ).

    out->write(
      |Estado inicial: PENDIENTE|
    ).


    "------------------------------------------------------------
    " 6. Encolar ZCL_APOC_JOB mediante bgPF
    "
    " Mismo patrón utilizado por Padrón Embargo.
    "------------------------------------------------------------
    TRY.

        DATA(lo_bgpf) =
          cl_bgmc_process_factory=>get_default( )->create( ).

        lo_bgpf->set_operation_tx_uncontrolled(
          NEW zcl_apoc_job( )
        ).

        lo_bgpf->save_for_execution( ).


      CATCH cx_bgmc INTO DATA(lx_bgmc).

        out->write(
          |ERROR bgPF: { lx_bgmc->get_text( ) }|
        ).

        RETURN.

    ENDTRY.


    "------------------------------------------------------------
    " 7. Commit de la solicitud bgPF
    "------------------------------------------------------------
    COMMIT WORK.


    out->write(
      |bgPF encolado correctamente.|
    ).

    out->write(
      |El procesamiento es asincrónico.|
    ).

    out->write(
      |Esperar unos segundos y volver a ejecutar esta clase | &&
      |o consultar ZAPOC_RUN para verificar el estado.|
    ).


    "------------------------------------------------------------
    " 8. Leer estado inmediatamente
    "
    " Puede seguir PENDIENTE porque bgPF es asincrónico.
    "------------------------------------------------------------
    SELECT SINGLE
           estado,
           total_registros,
           total_validos,
           total_match,
           total_errores,
           mensaje_error
      FROM zapoc_run
      WHERE run_id = @lv_run_id
      INTO @DATA(ls_after).


    IF sy-subrc = 0.

      out->write(
        |----------------------------------------|
      ).

      out->write(
        |ESTADO INMEDIATO|
      ).

      out->write(
        |Estado.........: { ls_after-estado }|
      ).

      out->write(
        |Total registros: { ls_after-total_registros }|
      ).

      out->write(
        |Total validos..: { ls_after-total_validos }|
      ).

      out->write(
        |Total match....: { ls_after-total_match }|
      ).

      out->write(
        |Total errores..: { ls_after-total_errores }|
      ).

      out->write(
        |Mensaje error..: { ls_after-mensaje_error }|
      ).

    ENDIF.


    out->write(
      |----------------------------------------|
    ).

    out->write(
      |RUN_ID PARA CONTROL: { lv_run_id }|
    ).

  ENDMETHOD.

ENDCLASS.
