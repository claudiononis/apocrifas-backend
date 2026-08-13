CLASS zcl_apoc_writer DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS block_supplier IMPORTING iv_supplier TYPE i_supplier-supplier RETURNING VALUE(rv_message) TYPE string.
ENDCLASS.
CLASS zcl_apoc_writer IMPLEMENTATION.
  METHOD block_supplier.
    rv_message = |WRITE_DISABLED: no se modifico BP { iv_supplier }|.
  ENDMETHOD.
ENDCLASS.
