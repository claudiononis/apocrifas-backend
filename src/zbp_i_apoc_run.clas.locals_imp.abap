CLASS lhc_run DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING REQUEST requested_authorizations FOR Run RESULT result.
    METHODS set_initial_status FOR DETERMINE ON SAVE IMPORTING keys FOR Run~setInitialStatus.
    METHODS refresh FOR MODIFY IMPORTING keys FOR ACTION Run~refresh.
ENDCLASS.
CLASS lhc_run IMPLEMENTATION.
  METHOD get_global_authorizations. ENDMETHOD.
  METHOD set_initial_status.
    MODIFY ENTITIES OF zi_apoc_run IN LOCAL MODE ENTITY Run UPDATE FIELDS ( Estado ModoTest )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky Estado = 'PENDIENTE' ModoTest = abap_true ) ).
  ENDMETHOD.
  METHOD refresh. ENDMETHOD.
ENDCLASS.
CLASS lsc_zi_apoc_run DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION. METHODS save_modified REDEFINITION.
ENDCLASS.
CLASS lsc_zi_apoc_run IMPLEMENTATION.
  METHOD save_modified.
    IF create-run IS NOT INITIAL.
      TRY.
          DATA(lo_bgpf) = cl_bgmc_process_factory=>get_default( )->create( ).
          lo_bgpf->set_operation_tx_uncontrolled( NEW zcl_apoc_job( ) ).
          lo_bgpf->save_for_execution( ).
        CATCH cx_bgmc.
      ENDTRY.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
