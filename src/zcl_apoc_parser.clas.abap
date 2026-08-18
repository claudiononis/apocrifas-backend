CLASS zcl_apoc_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_line,
        line_number      TYPE i,
        cuit             TYPE string,
        condition_date   TYPE string,
        publication_date TYPE string,
        description      TYPE string,
        raw_line         TYPE string,
        status           TYPE string,
      END OF ty_line.

    TYPES ty_lines TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    METHODS parse
      IMPORTING
        iv_content      TYPE string
      RETURNING
        VALUE(rt_lines) TYPE ty_lines.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_parser IMPLEMENTATION.

  METHOD parse.

    DATA lv_content TYPE string.
    DATA lt_raw     TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    lv_content = iv_content.

    REPLACE ALL OCCURRENCES OF
      cl_abap_char_utilities=>cr_lf
      IN lv_content
      WITH cl_abap_char_utilities=>newline.

    SPLIT lv_content
      AT cl_abap_char_utilities=>newline
      INTO TABLE lt_raw.

    LOOP AT lt_raw INTO DATA(lv_raw).

      DATA(lv_line_number) = sy-tabix.

      DATA lv_line TYPE string.
      lv_line = lv_raw.

      SHIFT lv_line LEFT DELETING LEADING space.
      SHIFT lv_line RIGHT DELETING TRAILING space.

      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lv_line+0(1) = '#'.
        CONTINUE.
      ENDIF.

      DATA lt_columns TYPE STANDARD TABLE OF string WITH EMPTY KEY.

      SPLIT lv_raw AT ',' INTO TABLE lt_columns.

      DATA lv_cuit             TYPE string.
      DATA lv_condition_date   TYPE string.
      DATA lv_publication_date TYPE string.
      DATA lv_description      TYPE string.
      DATA lv_status           TYPE string.

      READ TABLE lt_columns INDEX 1 INTO lv_cuit.
      READ TABLE lt_columns INDEX 2 INTO lv_condition_date.
      READ TABLE lt_columns INDEX 3 INTO lv_publication_date.
      READ TABLE lt_columns INDEX 4 INTO lv_description.

      CONDENSE lv_cuit NO-GAPS.

      SHIFT lv_condition_date LEFT DELETING LEADING space.
      SHIFT lv_condition_date RIGHT DELETING TRAILING space.

      SHIFT lv_publication_date LEFT DELETING LEADING space.
      SHIFT lv_publication_date RIGHT DELETING TRAILING space.

      lv_status = 'VALID'.

      IF strlen( lv_cuit ) <> 11.

        lv_status = 'INVALID_CUIT'.

      ELSE.

        FIND FIRST OCCURRENCE OF REGEX '[^0-9]'
          IN lv_cuit.

        IF sy-subrc = 0.
          lv_status = 'INVALID_CUIT'.
        ENDIF.

      ENDIF.

      APPEND VALUE ty_line(
        line_number      = lv_line_number
        cuit             = lv_cuit
        condition_date   = lv_condition_date
        publication_date = lv_publication_date
        description      = lv_description
        raw_line         = lv_raw
        status           = lv_status
      ) TO rt_lines.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
