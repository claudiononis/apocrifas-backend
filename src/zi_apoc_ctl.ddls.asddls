@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'APOC - proveedores bloqueados'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_APOC_CTL
  as select from zapoc_ctl
{
  key supplier           as Supplier,

      cuit               as Cuit,

      condition_date     as ConditionDate,

      block_date         as BlockDate,

      run_id             as RunId,

      source_line        as SourceLine,

      posting_blocked    as PostingBlocked,

      purchasing_blocked as PurchasingBlocked,

      created_by         as CreatedBy,

      created_at         as CreatedAt,

      last_changed_at    as LastChangedAt
}
