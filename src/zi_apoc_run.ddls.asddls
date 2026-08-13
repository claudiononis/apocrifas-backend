@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'APOC - cabecera de corrida'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_APOC_RUN
  as select from zapoc_run
  composition [0..*] of ZI_APOC_LOG as _Log
{
  key run_id as RunId,
      modo_test as ModoTest,
      estado as Estado,
      contenido as Contenido,
      @Semantics.largeObject: { mimeType: 'MimeType', fileName: 'FileName', contentDispositionPreference: #ATTACHMENT }
      file_content as FileContent,
      mime_type as MimeType,
      file_name as FileName,
      total_registros as TotalRegistros,
      total_validos as TotalValidos,
      total_match as TotalMatch,
      total_bloqueables as TotalBloqueables,
      total_no_encontr as TotalNoEncontrados,
      total_errores as TotalErrores,
      mensaje_error as MensajeError,
      @Semantics.user.createdBy: true created_by as CreatedBy,
      @Semantics.systemDateTime.createdAt: true created_at as CreatedAt,
      @Semantics.systemDateTime.lastChangedAt: true last_changed_at as LastChangedAt,
      _Log
}
