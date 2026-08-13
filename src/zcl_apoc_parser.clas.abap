CLASS zcl_apoc_parser DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_linea,
             source_line      TYPE i,
             cuit             TYPE c LENGTH 11,
             condition_date   TYPE c LENGTH 10,
             publication_date TYPE c LENGTH 10,
             description      TYPE string,
             raw_line         TYPE string,
             valid_cuit       TYPE abap_boolean,
           END OF ty_linea,
           ty_lineas TYPE STANDARD TABLE OF ty_linea WITH EMPTY KEY.
    METHODS parse IMPORTING iv_content TYPE string RETURNING VALUE(rt_lines) TYPE ty_lineas.
ENDCLASS.

CLASS zcl_apoc_parser IMPLEMENTATION.
  METHOD parse.
    DATA lv_norm TYPE string.
    DATA lt_raw TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    lv_norm = iv_content.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_norm WITH cl_abap_char_utilities=>newline.
    SPLIT lv_norm AT cl_abap_char_utilities=>newline INTO TABLE lt_raw.
    LOOP AT lt_raw INTO DATA(lv_raw).
      DATA(lv_source_line) = sy-tabix.
      DATA(lv_trimmed) = lv_raw.
      SHIFT lv_trimmed LEFT DELETING LEADING space.
      SHIFT lv_trimmed RIGHT DELETING TRAILING space.
      IF lv_trimmed IS INITIAL OR lv_trimmed(1) = '#'.
        CONTINUE.
      ENDIF.
      DATA lt_cols TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      SPLIT lv_raw AT ',' INTO TABLE lt_cols.
      DATA: lv_cuit TYPE string, lv_cond TYPE string, lv_pub TYPE string, lv_desc TYPE string.
      READ TABLE lt_cols INDEX 1 INTO lv_cuit.
      READ TABLE lt_cols INDEX 2 INTO lv_cond.
      READ TABLE lt_cols INDEX 3 INTO lv_pub.
      IF lines( lt_cols ) >= 4.
        LOOP AT lt_cols INTO DATA(lv_col) FROM 4.
          IF lv_desc IS INITIAL. lv_desc = lv_col. ELSE. lv_desc = |{ lv_desc },{ lv_col }|. ENDIF.
        ENDLOOP.
      ENDIF.
      CONDENSE lv_cuit NO-GAPS.
      SHIFT lv_cond LEFT DELETING LEADING space. SHIFT lv_cond RIGHT DELETING TRAILING space.
      SHIFT lv_pub LEFT DELETING LEADING space. SHIFT lv_pub RIGHT DELETING TRAILING space.
      DATA(lv_valid) = abap_true.
      IF strlen( lv_cuit ) <> 11.
        lv_valid = abap_false.
      ELSE.
        FIND FIRST OCCURRENCE OF REGEX '[^0-9]' IN lv_cuit.
        IF sy-subrc = 0. lv_valid = abap_false. ENDIF.
      ENDIF.
      APPEND VALUE #( source_line = lv_source_line cuit = lv_cuit condition_date = lv_cond
                      publication_date = lv_pub description = lv_desc raw_line = lv_raw valid_cuit = lv_valid ) TO rt_lines.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
