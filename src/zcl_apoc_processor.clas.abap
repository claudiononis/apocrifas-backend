CLASS zcl_apoc_processor DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_summary, processed TYPE i, to_block TYPE i, errors TYPE i, END OF ty_summary.
    METHODS process IMPORTING iv_run_id TYPE sysuuid_x16 iv_test_mode TYPE abap_boolean DEFAULT abap_true
                    RETURNING VALUE(rs_summary) TYPE ty_summary.
ENDCLASS.
CLASS zcl_apoc_processor IMPLEMENTATION.
  METHOD process.
    SELECT * FROM zapoc_stg WHERE run_id = @iv_run_id INTO TABLE @DATA(lt_stg).
    rs_summary-processed = lines( lt_stg ).
    GET TIME STAMP FIELD DATA(lv_ts).
    DATA lt_log TYPE STANDARD TABLE OF zapoc_log.
    LOOP AT lt_stg INTO DATA(ls_stg).
      rs_summary-to_block += 1.
      APPEND VALUE #( run_id = iv_run_id line_number = ls_stg-line_number cuit = ls_stg-cuit supplier = ls_stg-supplier
                      resultado = 'TEST_OK' mensaje = 'Demo: candidato a bloqueo central. Business Partner NO modificado.'
                      created_at = lv_ts ) TO lt_log.
    ENDLOOP.
    IF lt_log IS NOT INITIAL. MODIFY zapoc_log FROM TABLE @lt_log. ENDIF.
  ENDMETHOD.
ENDCLASS.
