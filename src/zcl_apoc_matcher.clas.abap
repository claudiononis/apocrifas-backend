CLASS zcl_apoc_matcher DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_match,
        cuit       TYPE string,
        supplier   TYPE string,
        status     TYPE string,
      END OF ty_match.

    TYPES ty_matches TYPE STANDARD TABLE OF ty_match WITH EMPTY KEY.

    METHODS match
      IMPORTING
        it_lines          TYPE zcl_apoc_parser=>ty_lines
      RETURNING
        VALUE(rt_matches) TYPE ty_matches.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_matcher IMPLEMENTATION.

  METHOD match.

    LOOP AT it_lines INTO DATA(ls_line).

      IF ls_line-status <> 'VALID'.
        CONTINUE.
      ENDIF.

      DATA lv_supplier TYPE i_supplier-Supplier.

      CLEAR lv_supplier.

      SELECT SINGLE
             Supplier
        FROM I_Supplier
        WHERE TaxNumber1 = @ls_line-cuit
        INTO @lv_supplier.

      IF sy-subrc = 0.

        APPEND VALUE ty_match(
          cuit     = ls_line-cuit
          supplier = lv_supplier
          status   = 'FOUND'
        ) TO rt_matches.

      ELSE.

        APPEND VALUE ty_match(
          cuit     = ls_line-cuit
          supplier = ''
          status   = 'NOT_FOUND'
        ) TO rt_matches.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
