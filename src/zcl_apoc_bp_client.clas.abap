CLASS zcl_apoc_bp_client DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_supplier_status,
        supplier              TYPE c LENGTH 10,
        found                 TYPE abap_boolean,
        posting_is_blocked    TYPE abap_boolean,
        purchasing_is_blocked TYPE abap_boolean,
        message               TYPE string,
      END OF ty_supplier_status.

    TYPES:
      BEGIN OF ty_result,
        supplier     TYPE c LENGTH 10,
        ok           TYPE abap_boolean,
        status       TYPE string,
        message      TYPE string,
        message_tech TYPE string,
      END OF ty_result.


    METHODS read_supplier
      IMPORTING
        iv_supplier      TYPE c
      RETURNING
        VALUE(rs_status) TYPE ty_supplier_status.


    METHODS set_block_status
      IMPORTING
        iv_supplier              TYPE c
        iv_posting_is_blocked    TYPE abap_boolean
        iv_purchasing_is_blocked TYPE abap_boolean
      RETURNING
        VALUE(rs_result)         TYPE ty_result.


    METHODS block_supplier
      IMPORTING
        iv_supplier      TYPE c
      RETURNING
        VALUE(rs_result) TYPE ty_result.


  PRIVATE SECTION.

    CONSTANTS:
      c_comm_scenario TYPE c LENGTH 30
        VALUE 'ZCS_PADRON_BP_API',

      c_comm_system TYPE c LENGTH 30
        VALUE 'Z_PADRON_SELF_API',

      c_service_id TYPE c LENGTH 30
        VALUE 'ZOS_PADRON_BP_API_REST'.


    TYPES:
      BEGIN OF ty_supplier_key,
        supplier TYPE
          zscm_api_business_partner=>tys_a_supplier_type-supplier,
      END OF ty_supplier_key.


    METHODS get_http_client
      RETURNING
        VALUE(ro_client) TYPE REF TO if_web_http_client
      RAISING
        cx_static_check.


    METHODS get_proxy
      RETURNING
        VALUE(ro_proxy) TYPE REF TO /iwbep/if_cp_client_proxy
      RAISING
        cx_static_check.

ENDCLASS.



CLASS zcl_apoc_bp_client IMPLEMENTATION.


  METHOD get_http_client.

    DATA(lo_destination) =
      cl_http_destination_provider=>create_by_comm_arrangement(
        comm_scenario  = CONV #( c_comm_scenario )
        comm_system_id = CONV #( c_comm_system )
        service_id     = CONV #( c_service_id )
      ).

    ro_client =
      cl_web_http_client_manager=>create_by_http_destination(
        lo_destination
      ).

  ENDMETHOD.



  METHOD get_proxy.

    ro_proxy =
      /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
        is_proxy_model_key = VALUE #(
          repository_id       = 'DEFAULT'
          proxy_model_id      = 'ZSCM_API_BUSINESS_PARTNER'
          proxy_model_version = '0001'
        )
        io_http_client           = get_http_client( )
        iv_relative_service_root = '/'
      ).

  ENDMETHOD.



  METHOD read_supplier.

    rs_status-supplier = iv_supplier.

    TRY.

        DATA(lo_proxy) =
          get_proxy( ).

        DATA(lo_request) =
          lo_proxy->create_resource_for_entity_set(
            'A_SUPPLIER'
          )->create_request_for_read( ).

        DATA(lo_filter_factory) =
          lo_request->create_filter_factory( ).

        DATA lt_supplier_range TYPE RANGE OF
          zscm_api_business_partner=>tys_a_supplier_type-supplier.

        APPEND VALUE #(
          sign   = 'I'
          option = 'EQ'
          low    = iv_supplier
        ) TO lt_supplier_range.

        DATA(lo_filter) =
          lo_filter_factory->create_by_range(
            iv_property_path = 'SUPPLIER'
            it_range         = lt_supplier_range
          ).

        lo_request->set_filter(
          lo_filter
        ).

        lo_request->set_top( 1 ).

        DATA lt_suppliers TYPE STANDARD TABLE OF
          zscm_api_business_partner=>tys_a_supplier_type.

        lo_request->execute( )->get_business_data(
          IMPORTING
            et_business_data = lt_suppliers
        ).

        IF lt_suppliers IS INITIAL.

          rs_status-found   = abap_false.
          rs_status-message = 'Proveedor no encontrado'.

          RETURN.

        ENDIF.

        READ TABLE lt_suppliers
          INDEX 1
          INTO DATA(ls_supplier).

        rs_status-found =
          abap_true.

        rs_status-supplier =
          ls_supplier-supplier.

        rs_status-posting_is_blocked =
          ls_supplier-posting_is_blocked.

        rs_status-purchasing_is_blocked =
          ls_supplier-purchasing_is_blocked.

        rs_status-message =
          'Proveedor encontrado'.


      CATCH cx_root INTO DATA(lx).

        rs_status-found =
          abap_false.

        rs_status-message =
          |Error leyendo proveedor: { lx->get_text( ) }|.

    ENDTRY.

  ENDMETHOD.



  METHOD set_block_status.

    rs_result-supplier =
      iv_supplier.

    TRY.

        "--------------------------------------------------------
        " 1. Verificar que el Supplier exista
        "--------------------------------------------------------
        DATA(ls_before) =
          read_supplier(
            iv_supplier = iv_supplier
          ).

        IF ls_before-found = abap_false.

          rs_result-ok =
            abap_false.

          rs_result-status =
            'NOT_FOUND'.

          rs_result-message =
            ls_before-message.

          RETURN.

        ENDIF.


        "--------------------------------------------------------
        " 2. Si ya tiene exactamente el estado solicitado,
        "    no enviamos PATCH
        "--------------------------------------------------------
        IF ls_before-posting_is_blocked =
             iv_posting_is_blocked
           AND
           ls_before-purchasing_is_blocked =
             iv_purchasing_is_blocked.

          rs_result-ok =
            abap_true.

          rs_result-status =
            'NO_CHANGE'.

          rs_result-message =
            'El proveedor ya tiene el estado solicitado'.

          RETURN.

        ENDIF.


        "--------------------------------------------------------
        " 3. Crear proxy
        "--------------------------------------------------------
        DATA(lo_proxy) =
          get_proxy( ).


        "--------------------------------------------------------
        " 4. Navegar al Supplier por clave
        "--------------------------------------------------------
        DATA(ls_key) =
          VALUE ty_supplier_key(
            supplier = iv_supplier
          ).

        DATA(lo_entity_resource) =
          lo_proxy->create_resource_for_entity_set(
            'A_SUPPLIER'
          )->navigate_with_key(
            ls_key
          ).


        "--------------------------------------------------------
        " 5. Crear PATCH
        "--------------------------------------------------------
        DATA(lo_update_request) =
          lo_entity_resource->create_request_for_update(
            /iwbep/if_cp_request_update=>gcs_update_semantic-patch
          ).


        "--------------------------------------------------------
        " 6. Cargar estado solicitado
        "--------------------------------------------------------
        DATA(ls_patch_data) =
          VALUE zscm_api_business_partner=>tys_a_supplier_type(
            supplier              = iv_supplier
            posting_is_blocked    = iv_posting_is_blocked
            purchasing_is_blocked = iv_purchasing_is_blocked
          ).


        "--------------------------------------------------------
        " 7. Enviar solamente los dos campos de bloqueo
        "--------------------------------------------------------
        lo_update_request->set_business_data(
          is_business_data = ls_patch_data
          it_provided_property = VALUE #(
            ( |POSTING_IS_BLOCKED| )
            ( |PURCHASING_IS_BLOCKED| )
          )
        ).


        "--------------------------------------------------------
        " 8. Ejecutar PATCH real
        "--------------------------------------------------------
        lo_update_request->execute( ).


        "--------------------------------------------------------
        " 9. Leer nuevamente y verificar
        "--------------------------------------------------------
        DATA(ls_after) =
          read_supplier(
            iv_supplier = iv_supplier
          ).


        IF ls_after-found = abap_true
           AND
           ls_after-posting_is_blocked =
             iv_posting_is_blocked
           AND
           ls_after-purchasing_is_blocked =
             iv_purchasing_is_blocked.

          rs_result-ok =
            abap_true.

          rs_result-status =
            'UPDATED'.

          rs_result-message =
            'Estado de bloqueo actualizado y verificado'.

          rs_result-message_tech =
            |Posting=[{ ls_after-posting_is_blocked }] | &&
            |Purchasing=[{ ls_after-purchasing_is_blocked }]|.

        ELSE.

          rs_result-ok =
            abap_false.

          rs_result-status =
            'VERIFY_ERROR'.

          rs_result-message =
            'La API respondio pero el estado final no coincide'.

          rs_result-message_tech =
            |Esperado Posting=[{ iv_posting_is_blocked }] | &&
            |Purchasing=[{ iv_purchasing_is_blocked }] / | &&
            |Real Posting=[{ ls_after-posting_is_blocked }] | &&
            |Purchasing=[{ ls_after-purchasing_is_blocked }]|.

        ENDIF.


      CATCH cx_root INTO DATA(lx).

        rs_result-ok =
          abap_false.

        rs_result-status =
          'ERROR'.

        rs_result-message =
          'No se pudo actualizar el estado de bloqueo del proveedor'.

        rs_result-message_tech =
          lx->get_text( ).

    ENDTRY.

  ENDMETHOD.



  METHOD block_supplier.

    rs_result =
      set_block_status(
        iv_supplier              = iv_supplier
        iv_posting_is_blocked    = abap_true
        iv_purchasing_is_blocked = abap_true
      ).

    IF rs_result-ok = abap_true.

      IF rs_result-status = 'UPDATED'.

        rs_result-status =
          'BLOCKED'.

        rs_result-message =
          'Proveedor bloqueado correctamente para contabilizacion y compras'.

      ELSEIF rs_result-status = 'NO_CHANGE'.

        rs_result-status =
          'ALREADY_BLOCKED_API'.

        rs_result-message =
          'Proveedor ya tiene bloqueo global de contabilizacion y compras'.

      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
