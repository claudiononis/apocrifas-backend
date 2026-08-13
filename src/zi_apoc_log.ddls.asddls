@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'APOC - log por registro'
define view entity ZI_APOC_LOG
  as select from zapoc_log
  association to parent ZI_APOC_RUN as _Run on $projection.RunId = _Run.RunId
{
  key run_id as RunId,
  key line_number as LineNumber,
      cuit as Cuit,
      supplier as Supplier,
      resultado as Resultado,
      mensaje as Mensaje,
      created_at as CreatedAt,
      _Run
}
