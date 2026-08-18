CLASS ltc_parser DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS parse_csv
      FOR TESTING.

ENDCLASS.


CLASS ltc_parser IMPLEMENTATION.

  METHOD parse_csv.

    DATA(lo_parser) = NEW zcl_apoc_parser( ).

    DATA(lv_csv) =
      |# comentario{ cl_abap_char_utilities=>newline }| &&
      |30712345678,2026-08-01,2026-08-05,Proveedor uno{ cl_abap_char_utilities=>newline }| &&
      |2012345678,2026-08-02,2026-08-06,CUIT corto{ cl_abap_char_utilities=>newline }| &&
      |30A12345678,2026-08-03,2026-08-07,CUIT con letra|.

    DATA(lt_result) = lo_parser->parse( lv_csv ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 3 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-line_number
      exp = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-cuit
      exp = '30712345678' ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-status
      exp = 'VALID' ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 2 ]-line_number
      exp = 3 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 2 ]-status
      exp = 'INVALID_CUIT' ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 3 ]-line_number
      exp = 4 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 3 ]-status
      exp = 'INVALID_CUIT' ).

  ENDMETHOD.

ENDCLASS.
