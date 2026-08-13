@EndUserText.label: 'APOC - corridas'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: { typeName: 'Corrida APOC', typeNamePlural: 'Corridas APOC', title: { value: 'FileName' }, description: { value: 'Estado' } }
define root view entity ZC_APOC_RUN provider contract transactional_query as projection on ZI_APOC_RUN
{
  @UI.hidden: true key RunId,
  @EndUserText.label: 'Modo test' @UI: { lineItem: [{ position: 20 }], fieldGroup: [{ position: 10, qualifier: 'Carga' }] } ModoTest,
  @EndUserText.label: 'Archivo APOC' @UI: { lineItem: [{ position: 10 }], fieldGroup: [{ position: 20, qualifier: 'Carga' }] } FileContent,
  @UI.hidden: true MimeType,
  @UI.hidden: true FileName,
  @UI.hidden: true Contenido,
  @EndUserText.label: 'Estado' @UI: { lineItem: [{ position: 30 }], identification: [{ type: #FOR_ACTION, dataAction: 'refresh', label: 'Refrescar', position: 10 }] } Estado,
  @EndUserText.label: 'Total' @UI.lineItem: [{ position: 40 }] TotalRegistros,
  @EndUserText.label: 'Validos' @UI.lineItem: [{ position: 50 }] TotalValidos,
  @EndUserText.label: 'Encontrados' @UI.lineItem: [{ position: 60 }] TotalMatch,
  @EndUserText.label: 'Candidatos' @UI.lineItem: [{ position: 70 }] TotalBloqueables,
  @EndUserText.label: 'No encontrados' @UI.lineItem: [{ position: 80 }] TotalNoEncontrados,
  @EndUserText.label: 'Errores' @UI.lineItem: [{ position: 90 }] TotalErrores,
  MensajeError, CreatedBy, CreatedAt, LastChangedAt,
  _Log : redirected to composition child ZC_APOC_LOG
}
