CLASS zcl_apoc_writer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_result,
        run_id                TYPE sysuuid_x16,
        total_staging         TYPE i,
        total_con_match       TYPE i,
        total_sin_match       TYPE i,
        total_simulados       TYPE i,
        total_bloqueados      TYPE i,
        total_already_blocked TYPE i,
        total_errores         TYPE i,
        status                TYPE string,
        message               TYPE string,
      END OF ty_result.

    METHODS execute
      IMPORTING
        iv_run_id        TYPE sysuuid_x16
        iv_test_mode     TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rs_result) TYPE ty_result.

ENDCLASS.



CLASS zcl_apoc_writer IMPLEMENTATION.

  METHOD execute.

    DATA:
      lv_timestamp TYPE timestampl.

    rs_result-run_id = iv_run_id.


    "------------------------------------------------------------
    " 1. Leer staging de la corrida
    "------------------------------------------------------------
    SELECT
      FROM zapoc_stg
      FIELDS
        run_id,
        line_number,
        cuit,
        supplier,
        condition_date,
        publication_date,
        description
      WHERE run_id = @iv_run_id
      ORDER BY line_number
      INTO TABLE @DATA(lt_stg).


    rs_result-total_staging =
      lines( lt_stg ).


    "------------------------------------------------------------
    " 2. Sin registros
    "------------------------------------------------------------
    IF lt_stg IS INITIAL.

      rs_result-status =
        'SIN_DATOS'.

      rs_result-message =
        'No existen registros en staging para la corrida'.

      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 3. Cliente API Business Partner
    "
    " IMPORTANTE:
    " En Modo Test nunca se utiliza BLOCK_SUPPLIER.
    "------------------------------------------------------------
    DATA(lo_bp_client) =
      NEW zcl_apoc_bp_client( ).


    "------------------------------------------------------------
    " 4. Procesar registros
    "------------------------------------------------------------
    LOOP AT lt_stg INTO DATA(ls_stg).


      "----------------------------------------------------------
      " 4.1 Sin Supplier
      "
      " Parser/Matcher ya dejó el motivo en ZAPOC_LOG.
      " Writer no debe hacer nada.
      "----------------------------------------------------------
      IF ls_stg-supplier IS INITIAL.

        rs_result-total_sin_match += 1.

        CONTINUE.

      ENDIF.


      rs_result-total_con_match += 1.


      "----------------------------------------------------------
      " 4.2 ¿Ya fue bloqueado anteriormente por APOC?
      "----------------------------------------------------------
      SELECT SINGLE
             supplier
        FROM zapoc_ctl
        WHERE supplier = @ls_stg-supplier
        INTO @DATA(lv_existing_supplier).


      IF sy-subrc = 0.

        rs_result-total_already_blocked += 1.


        UPDATE zapoc_log
          SET resultado = 'ALREADY_BLOCKED',
              mensaje   = 'Proveedor ya bloqueado por APOC'
          WHERE run_id      = @iv_run_id
            AND line_number = @ls_stg-line_number.


        CONTINUE.

      ENDIF.


      "----------------------------------------------------------
      " 4.3 MODO TEST
      "
      " NO API
      " NO ZAPOC_CTL
      "----------------------------------------------------------
      IF iv_test_mode = abap_true.

        rs_result-total_simulados += 1.


        UPDATE zapoc_log
          SET resultado = 'WOULD_BLOCK',
              mensaje   = 'Proveedor seria bloqueado'
          WHERE run_id      = @iv_run_id
            AND line_number = @ls_stg-line_number.


        CONTINUE.

      ENDIF.


      "----------------------------------------------------------
      " 4.4 MODO REAL
      "
      " Ejecutar bloqueo global real:
      "
      " PostingIsBlocked    = X
      " PurchasingIsBlocked = X
      "----------------------------------------------------------
      DATA(ls_api_result) =
        lo_bp_client->block_supplier(
          iv_supplier = ls_stg-supplier
        ).


      "----------------------------------------------------------
      " 4.5 Error API
      "----------------------------------------------------------
      IF ls_api_result-ok = abap_false.

        rs_result-total_errores += 1.


        UPDATE zapoc_log
          SET resultado = 'BLOCK_ERROR',
              mensaje   = @ls_api_result-message
          WHERE run_id      = @iv_run_id
            AND line_number = @ls_stg-line_number.


        CONTINUE.

      ENDIF.


      "----------------------------------------------------------
      " 4.6 La API informa que el proveedor ya tenía
      "     ambos bloqueos activos.
      "
      " Esto puede ocurrir aunque todavía no estuviera
      " registrado en ZAPOC_CTL.
      "
      " En ese caso lo registramos en control para que
      " futuras corridas no vuelvan a llamar a la API.
      "----------------------------------------------------------
      IF ls_api_result-status = 'ALREADY_BLOCKED_API'.

        GET TIME STAMP FIELD lv_timestamp.


        DATA(ls_ctl_api) =
          VALUE zapoc_ctl(
            supplier            = ls_stg-supplier
            cuit                = ls_stg-cuit
            condition_date      = ls_stg-condition_date
            block_date          = sy-datum
            run_id              = iv_run_id
            source_line         = ls_stg-line_number
            posting_blocked     = abap_true
            purchasing_blocked  = abap_true
            created_by          = sy-uname
            created_at          = lv_timestamp
            last_changed_at     = lv_timestamp
          ).


        INSERT zapoc_ctl
          FROM @ls_ctl_api.


        rs_result-total_already_blocked += 1.


        UPDATE zapoc_log
          SET resultado = 'ALREADY_BLOCKED',
              mensaje   = 'Proveedor ya tenia bloqueo global activo'
          WHERE run_id      = @iv_run_id
            AND line_number = @ls_stg-line_number.


        CONTINUE.

      ENDIF.


      "----------------------------------------------------------
      " 4.7 Bloqueo aplicado y verificado por BP_CLIENT
      "----------------------------------------------------------
      IF ls_api_result-status = 'BLOCKED'.

        GET TIME STAMP FIELD lv_timestamp.


        DATA(ls_ctl) =
          VALUE zapoc_ctl(
            supplier            = ls_stg-supplier
            cuit                = ls_stg-cuit
            condition_date      = ls_stg-condition_date
            block_date          = sy-datum
            run_id              = iv_run_id
            source_line         = ls_stg-line_number
            posting_blocked     = abap_true
            purchasing_blocked  = abap_true
            created_by          = sy-uname
            created_at          = lv_timestamp
            last_changed_at     = lv_timestamp
          ).


        "--------------------------------------------------------
        " Registrar proveedor bloqueado por APOC
        "--------------------------------------------------------
        INSERT zapoc_ctl
          FROM @ls_ctl.


        IF sy-subrc = 0.

          rs_result-total_bloqueados += 1.


          UPDATE zapoc_log
            SET resultado = 'BLOCKED',
                mensaje   = 'Proveedor bloqueado correctamente'
            WHERE run_id      = @iv_run_id
              AND line_number = @ls_stg-line_number.


        ELSE.

          "------------------------------------------------------
          " El Supplier ya fue modificado por API.
          "
          " Antes de considerar error verificamos si otra
          " ejecución concurrente alcanzó a crear ZAPOC_CTL.
          "------------------------------------------------------
          SELECT SINGLE
                 supplier
            FROM zapoc_ctl
            WHERE supplier = @ls_stg-supplier
            INTO @DATA(lv_ctl_after).


          IF sy-subrc = 0.

            rs_result-total_bloqueados += 1.


            UPDATE zapoc_log
              SET resultado = 'BLOCKED',
                  mensaje   = 'Proveedor bloqueado y registrado'
              WHERE run_id      = @iv_run_id
                AND line_number = @ls_stg-line_number.


          ELSE.

            rs_result-total_errores += 1.


            UPDATE zapoc_log
              SET resultado = 'CONTROL_ERROR',
                  mensaje   = 'Proveedor bloqueado pero no pudo registrarse en control'
              WHERE run_id      = @iv_run_id
                AND line_number = @ls_stg-line_number.

          ENDIF.

        ENDIF.


        CONTINUE.

      ENDIF.


      "----------------------------------------------------------
      " 4.8 Estado inesperado del BP_CLIENT
      "----------------------------------------------------------
      rs_result-total_errores += 1.


      UPDATE zapoc_log
        SET resultado = 'BLOCK_ERROR',
            mensaje   = 'Respuesta inesperada del servicio de proveedores'
        WHERE run_id      = @iv_run_id
          AND line_number = @ls_stg-line_number.

    ENDLOOP.


    "------------------------------------------------------------
    " 5. Resultado general - MODO TEST
    "------------------------------------------------------------
    IF iv_test_mode = abap_true.

      rs_result-total_bloqueados = 0.


      rs_result-status =
        'SIMULADO'.


      rs_result-message =
        |Simulacion finalizada. | &&
        |Serian bloqueados: { rs_result-total_simulados }. | &&
        |Ya bloqueados: { rs_result-total_already_blocked }.|.


      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 6. Resultado general - MODO REAL
    "------------------------------------------------------------
    IF rs_result-total_errores = 0.

      rs_result-status =
        'COMPLETADO'.


      rs_result-message =
        |Procesamiento real finalizado. | &&
        |Bloqueados: { rs_result-total_bloqueados }. | &&
        |Ya bloqueados: { rs_result-total_already_blocked }.|.


    ELSEIF rs_result-total_bloqueados > 0
        OR rs_result-total_already_blocked > 0.

      rs_result-status =
        'PARCIAL'.


      rs_result-message =
        |Procesamiento finalizado con errores. | &&
        |Bloqueados: { rs_result-total_bloqueados }. | &&
        |Ya bloqueados: { rs_result-total_already_blocked }. | &&
        |Errores: { rs_result-total_errores }.|.


    ELSE.

      rs_result-status =
        'ERROR'.


      rs_result-message =
        |No se pudieron bloquear proveedores. | &&
        |Errores: { rs_result-total_errores }.|.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
