CLASS zcl_apoc_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single_tx_uncontr.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_job IMPLEMENTATION.

  METHOD if_bgmc_op_single_tx_uncontr~execute.
    " Skeleton: no business processing yet.
  ENDMETHOD.

ENDCLASS.
