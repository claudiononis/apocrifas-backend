CLASS zcl_apoc_ingesta DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_summary, total_rows TYPE i, valid_rows TYPE i, invalid TYPE i, found TYPE i, not_found TYPE i, END OF ty_summary.
    METHODS ingest IMPORTING iv_run_id TYPE sysuuid_x16 iv_content TYPE string RETURNING VALUE(rs_summary) TYPE ty_summary.
ENDCLASS.
CLASS zcl_apoc_ingesta IMPLEMENTATION.
  METHOD ingest.
    DELETE FROM zapoc_stg WHERE run_id = @iv_run_id.
    DELETE FROM zapoc_log WHERE run_id = @iv_run_id.
    DATA(lt_lines) = NEW zcl_apoc_parser( )->parse( iv_content ).
    rs_summary-total_rows = lines( lt_lines ).
    DATA lt_cuits TYPE zcl_apoc_matcher=>ty_cuits.
    LOOP AT lt_lines INTO DATA(ls_line) WHERE valid_cuit = abap_true.
      rs_summary-valid_rows += 1. APPEND CONV #( ls_line-cuit ) TO lt_cuits.
    ENDLOOP.
    SORT lt_cuits. DELETE ADJACENT DUPLICATES FROM lt_cuits.
    DATA(lt_matches) = NEW zcl_apoc_matcher( )->match( lt_cuits ).
    DATA lt_match_idx TYPE HASHED TABLE OF zcl_apoc_matcher=>ty_match WITH UNIQUE KEY cuit.
    lt_match_idx = CORRESPONDING #( lt_matches ).
    DATA lt_stg TYPE STANDARD TABLE OF zapoc_stg.
    DATA lt_log TYPE STANDARD TABLE OF zapoc_log.
    GET TIME STAMP FIELD DATA(lv_ts).
    LOOP AT lt_lines INTO ls_line.
      IF ls_line-valid_cuit = abap_false.
        rs_summary-invalid += 1.
        APPEND VALUE #( run_id = iv_run_id line_number = ls_line-source_line cuit = ls_line-cuit
                        resultado = 'CUIT_INVALIDO' mensaje = 'CUIT invalido: se esperan 11 digitos.' created_at = lv_ts ) TO lt_log.
        CONTINUE.
      ENDIF.
      READ TABLE lt_match_idx INTO DATA(ls_match) WITH TABLE KEY cuit = ls_line-cuit.
      IF sy-subrc <> 0.
        rs_summary-not_found += 1.
        APPEND VALUE #( run_id = iv_run_id line_number = ls_line-source_line cuit = ls_line-cuit
                        resultado = 'NO_ENCONTRADO' mensaje = 'CUIT sin proveedor correspondiente en I_Supplier.' created_at = lv_ts ) TO lt_log.
        CONTINUE.
      ENDIF.
      rs_summary-found += 1.
      APPEND VALUE #( run_id = iv_run_id line_number = ls_line-source_line cuit = ls_line-cuit supplier = ls_match-supplier
                      condition_date = ls_line-condition_date publication_date = ls_line-publication_date
                      description = ls_line-description ) TO lt_stg.
    ENDLOOP.
    IF lt_stg IS NOT INITIAL. INSERT zapoc_stg FROM TABLE @lt_stg. ENDIF.
    IF lt_log IS NOT INITIAL. INSERT zapoc_log FROM TABLE @lt_log. ENDIF.
  ENDMETHOD.
ENDCLASS.
