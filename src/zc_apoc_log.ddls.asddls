@EndUserText.label: 'APOC - detalle'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZC_APOC_LOG as projection on ZI_APOC_LOG
{
  key RunId, key LineNumber,
  @UI.lineItem: [{ position: 10 }] Cuit,
  @UI.lineItem: [{ position: 20 }] Supplier,
  @UI.lineItem: [{ position: 30 }] Resultado,
  @UI.lineItem: [{ position: 40 }] Mensaje,
  CreatedAt,
  _Run : redirected to parent ZC_APOC_RUN
}
