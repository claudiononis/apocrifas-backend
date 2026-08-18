CLASS zcl_apoc_processor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_result,
        run_id              TYPE sysuuid_x16,
        status              TYPE string,
        total_registros     TYPE i,
        total_validos       TYPE i,
        total_match         TYPE i,
        total_bloqueables   TYPE i,
        total_no_encontrados TYPE i,
        total_errores       TYPE i,
        message             TYPE string,
      END OF ty_result.

    METHODS process
      IMPORTING
        iv_run_id         TYPE sysuuid_x16
        iv_content        TYPE string
      RETURNING
        VALUE(rs_result)  TYPE ty_result.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_apoc_processor IMPLEMENTATION.

  METHOD process.

    DATA(lo_ingesta) = NEW zcl_apoc_ingesta( ).

    DATA lv_timestamp TYPE timestampl.

    GET TIME STAMP FIELD lv_timestamp.


    "------------------------------------------------------------
    " Inicializar resultado
    "------------------------------------------------------------
    rs_result-run_id = iv_run_id.
    rs_result-status = 'PROCESANDO'.


    "------------------------------------------------------------
    " Marcar corrida como PROCESANDO
    "------------------------------------------------------------
    UPDATE zapoc_run
      SET estado          = 'PROCESANDO',
          mensaje_error   = '',
          last_changed_at = @lv_timestamp
      WHERE run_id        = @iv_run_id.


    TRY.

        "--------------------------------------------------------
        " Ejecutar ingesta
        "
        " Internamente:
        "   Parser
        "     ->
        "   Matcher
        "     ->
        "   ZAPOC_STG
        "--------------------------------------------------------
        DATA(ls_ingesta) = lo_ingesta->execute(
          iv_run_id  = iv_run_id
          iv_content = iv_content
        ).


        "--------------------------------------------------------
        " Completar contadores de la corrida
        "--------------------------------------------------------
        rs_result-total_registros =
          ls_ingesta-total_registros.

        rs_result-total_validos =
          ls_ingesta-total_validos.

        rs_result-total_match =
          ls_ingesta-total_match.

        rs_result-total_no_encontrados =
          ls_ingesta-total_no_match.


        "--------------------------------------------------------
        " DEMO:
        "
        " Todo proveedor encontrado se considera potencialmente
        " bloqueable.
        "
        " Más adelante ZCL_APOC_WRITER hará las validaciones
        " funcionales definitivas antes de modificar BP.
        "--------------------------------------------------------
        rs_result-total_bloqueables =
          ls_ingesta-total_match.


        "--------------------------------------------------------
        " Registros inválidos detectados por Parser
        "--------------------------------------------------------
        rs_result-total_errores =
          ls_ingesta-total_registros -
          ls_ingesta-total_validos.


        rs_result-status = 'TERMINADO'.
        rs_result-message = 'Procesamiento finalizado correctamente'.


        GET TIME STAMP FIELD lv_timestamp.


        "--------------------------------------------------------
        " Actualizar cabecera de corrida
        "--------------------------------------------------------
        UPDATE zapoc_run
          SET estado              = 'TERMINADO',
              total_registros     = @rs_result-total_registros,
              total_validos       = @rs_result-total_validos,
              total_match         = @rs_result-total_match,
              total_bloqueables   = @rs_result-total_bloqueables,
              total_no_encontr    = @rs_result-total_no_encontrados,
              total_errores       = @rs_result-total_errores,
              mensaje_error       = '',
              last_changed_at     = @lv_timestamp
          WHERE run_id            = @iv_run_id.


      CATCH cx_root INTO DATA(lx_error).

        "--------------------------------------------------------
        " Error controlado
        "--------------------------------------------------------
        rs_result-status = 'ERROR'.
        rs_result-message = lx_error->get_text( ).


        GET TIME STAMP FIELD lv_timestamp.


        UPDATE zapoc_run
          SET estado          = 'ERROR',
              mensaje_error   = @rs_result-message,
              last_changed_at = @lv_timestamp
          WHERE run_id        = @iv_run_id.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
