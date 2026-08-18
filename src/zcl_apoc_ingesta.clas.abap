CLASS zcl_apoc_ingesta DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_result,
        total_registros TYPE i,
        total_validos   TYPE i,
        total_match     TYPE i,
        total_no_match  TYPE i,
      END OF ty_result.

    METHODS execute
      IMPORTING
        iv_run_id        TYPE sysuuid_x16
        iv_content       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_ingesta IMPLEMENTATION.

  METHOD execute.

    DATA(lo_parser) =
      NEW zcl_apoc_parser( ).

    DATA(lo_matcher) =
      NEW zcl_apoc_matcher( ).


    "------------------------------------------------------------
    " 1. Parsear archivo
    "------------------------------------------------------------
    DATA(lt_lines) =
      lo_parser->parse(
        iv_content = iv_content
      ).


    "------------------------------------------------------------
    " 2. Buscar proveedores
    "------------------------------------------------------------
    DATA(lt_matches) =
      lo_matcher->match(
        it_lines = lt_lines
      ).


    rs_result-total_registros =
      lines( lt_lines ).


    "------------------------------------------------------------
    " 3. Contar registros válidos
    "------------------------------------------------------------
    LOOP AT lt_lines INTO DATA(ls_line_count).

      IF ls_line_count-status = 'VALID'.
        rs_result-total_validos += 1.
      ENDIF.

    ENDLOOP.


    "------------------------------------------------------------
    " 4. Obtener estructuras compatibles con tablas
    "
    " Usamos inferencia SQL porque en este tenant ya vimos
    " que las tablas no siempre son aceptadas directamente
    " como TYPE ABAP.
    "------------------------------------------------------------
    SELECT SINGLE
           *
      FROM zapoc_stg
      WHERE run_id = @iv_run_id
      INTO @DATA(ls_stg).


    SELECT SINGLE
           *
      FROM zapoc_log
      WHERE run_id = @iv_run_id
      INTO @DATA(ls_log).


    "------------------------------------------------------------
    " 5. Limpiar una eventual ejecución previa del mismo RUN
    "------------------------------------------------------------
    DELETE FROM zapoc_stg
      WHERE run_id = @iv_run_id.

    DELETE FROM zapoc_log
      WHERE run_id = @iv_run_id.


    "------------------------------------------------------------
    " 6. Procesar cada línea
    "------------------------------------------------------------
    LOOP AT lt_lines INTO DATA(ls_line).

      DATA lv_supplier TYPE string.
      DATA lv_resultado TYPE string.
      DATA lv_mensaje TYPE string.
      DATA lv_timestamp TYPE timestampl.

      CLEAR:
        lv_supplier,
        lv_resultado,
        lv_mensaje.


      "----------------------------------------------------------
      " 6.1 Registro inválido detectado por Parser
      "----------------------------------------------------------
      IF ls_line-status <> 'VALID'.

        lv_resultado = 'INVALID_CUIT'.
        lv_mensaje   = 'CUIT invalido'.


      ELSE.

        "--------------------------------------------------------
        " 6.2 Buscar resultado del Matcher
        "--------------------------------------------------------
        READ TABLE lt_matches
          INTO DATA(ls_match)
          WITH KEY cuit = ls_line-cuit.


        IF sy-subrc = 0.

          IF ls_match-status = 'FOUND'.

            lv_supplier = ls_match-supplier.

            lv_resultado = 'FOUND'.
            lv_mensaje   = 'Proveedor encontrado'.

            rs_result-total_match += 1.

          ELSE.

            lv_resultado = 'NOT_FOUND'.
            lv_mensaje   = 'Proveedor no encontrado'.

            rs_result-total_no_match += 1.

          ENDIF.


        ELSE.

          lv_resultado = 'NOT_FOUND'.
          lv_mensaje   = 'Proveedor no encontrado'.

          rs_result-total_no_match += 1.

        ENDIF.

      ENDIF.


      "----------------------------------------------------------
      " 6.3 Grabar staging
      "----------------------------------------------------------
      CLEAR ls_stg.

      ls_stg-run_id           = iv_run_id.
      ls_stg-line_number      = ls_line-line_number.
      ls_stg-cuit             = ls_line-cuit.
      ls_stg-supplier         = lv_supplier.
      ls_stg-condition_date   = ls_line-condition_date.
      ls_stg-publication_date = ls_line-publication_date.
      ls_stg-description      = ls_line-description.


      INSERT zapoc_stg
        FROM @ls_stg.


      "----------------------------------------------------------
      " 6.4 Grabar log visible desde RAP/Fiori
      "----------------------------------------------------------
      CLEAR ls_log.

      GET TIME STAMP FIELD lv_timestamp.

      ls_log-run_id      = iv_run_id.
      ls_log-line_number = ls_line-line_number.
      ls_log-cuit        = ls_line-cuit.
      ls_log-supplier    = lv_supplier.
      ls_log-resultado   = lv_resultado.
      ls_log-mensaje     = lv_mensaje.
      ls_log-created_at  = lv_timestamp.


      INSERT zapoc_log
        FROM @ls_log.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
