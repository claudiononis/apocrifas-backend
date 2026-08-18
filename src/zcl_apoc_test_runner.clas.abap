CLASS zcl_apoc_test_runner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_apoc_test_runner IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    CONSTANTS:
      c_supplier TYPE i_supplier-supplier
        VALUE '400000'.

    out->write(
      '========================================'
    ).

    out->write(
      'BUSQUEDA CUIT REAL DE SUPPLIER 400000'
    ).

    out->write(
      '========================================'
    ).

    SELECT SINGLE
           Supplier,
           TaxNumber1
      FROM I_Supplier
      WHERE Supplier = @c_supplier
      INTO @DATA(ls_supplier).

    IF sy-subrc <> 0.

      out->write(
        'Supplier 400000 no encontrado en I_Supplier'
      ).

      RETURN.

    ENDIF.

    out->write(
      |Supplier...: { ls_supplier-Supplier }|
    ).

    out->write(
      |TaxNumber1..: { ls_supplier-TaxNumber1 }|
    ).

    out->write(
      '----------------------------------------'
    ).

    IF ls_supplier-TaxNumber1 IS INITIAL.

      out->write(
        'Supplier existe pero TaxNumber1 esta vacio'
      ).

    ELSE.

      out->write(
        'CUIT CANDIDATO ENCONTRADO'
      ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
