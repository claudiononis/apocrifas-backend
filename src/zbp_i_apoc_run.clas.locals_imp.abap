CLASS lhc_Run DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Run RESULT result.
    METHODS setdefaults FOR DETERMINE ON MODIFY
      keys FOR run~setdefaults.

ENDCLASS.

CLASS lhc_Run IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

 METHOD setDefaults.

  MODIFY ENTITIES OF zi_apoc_run IN LOCAL MODE
    ENTITY Run
      UPDATE FIELDS ( ModoTest Estado )
      WITH VALUE #(
        FOR key IN keys
        (
          %tky     = key-%tky
          ModoTest = abap_true
          Estado   = 'PENDIENTE'
        )
      ).

ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_APOC_RUN DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_APOC_RUN IMPLEMENTATION.

METHOD save_modified.

  DATA(lo_bgpf) =
    cl_bgmc_process_factory=>get_default( )->create( ).

  lo_bgpf->set_operation_tx_uncontrolled(
    NEW zcl_apoc_job( )
  ).

  lo_bgpf->save_for_execution( ).

ENDMETHOD.
  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
