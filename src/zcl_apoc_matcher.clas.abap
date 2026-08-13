CLASS zcl_apoc_matcher DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_cuit TYPE i_supplier-taxnumber1.
    TYPES ty_cuits TYPE STANDARD TABLE OF ty_cuit WITH EMPTY KEY.
    TYPES: BEGIN OF ty_match, cuit TYPE i_supplier-taxnumber1, supplier TYPE i_supplier-supplier, END OF ty_match,
           ty_matches TYPE STANDARD TABLE OF ty_match WITH EMPTY KEY.
    METHODS match IMPORTING it_cuits TYPE ty_cuits RETURNING VALUE(rt_matches) TYPE ty_matches.
ENDCLASS.
CLASS zcl_apoc_matcher IMPLEMENTATION.
  METHOD match.
    IF it_cuits IS INITIAL. RETURN. ENDIF.
    SELECT TaxNumber1 AS cuit, Supplier AS supplier
      FROM I_Supplier
      FOR ALL ENTRIES IN @it_cuits
      WHERE TaxNumber1 = @it_cuits-table_line
      INTO TABLE @rt_matches.
  ENDMETHOD.
ENDCLASS.
