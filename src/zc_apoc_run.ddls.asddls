@EndUserText.label: 'APOC - corridas'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: {
  typeName: 'Corrida APOC',
  typeNamePlural: 'Corridas APOC',
  title: { value: 'FileName' },
  description: { value: 'Estado' }
}

define root view entity ZC_APOC_RUN
  provider contract transactional_query
  as projection on ZI_APOC_RUN
{
  @UI.hidden: true

  @UI.facet: [
    {
      id: 'Carga',
      purpose: #STANDARD,
      type: #FIELDGROUP_REFERENCE,
      label: 'Parámetros de la corrida',
      targetQualifier: 'Carga',
      position: 10
    },
    {
      id: 'Resultado',
      purpose: #STANDARD,
      type: #FIELDGROUP_REFERENCE,
      label: 'Resultados',
      targetQualifier: 'Resultado',
      position: 20
    },
    {
      id: 'Detalle',
      purpose: #STANDARD,
      type: #LINEITEM_REFERENCE,
      label: 'Detalle por registro',
      targetElement: '_Log',
      position: 30
    }
  ]
  key RunId,

  @EndUserText.label: 'Modo test (no impacta S/4)'
  @UI.fieldGroup: [
    {
      position: 10,
      qualifier: 'Carga'
    }
  ]
  @UI.lineItem: [
    {
      position: 20
    }
  ]
  ModoTest,

  @EndUserText.label: 'Nombre del archivo'
  @UI.fieldGroup: [
    {
      position: 20,
      qualifier: 'Carga'
    }
  ]
  FileName,

  @UI.hidden: true
  MimeType,

  @UI.hidden: true
  Contenido,

  @EndUserText.label: 'Estado'
  @UI.fieldGroup: [
    {
      position: 10,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 30
    }
  ]
  Estado,

  @EndUserText.label: 'Total registros'
  @UI.fieldGroup: [
    {
      position: 20,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 40
    }
  ]
  TotalRegistros,

  @EndUserText.label: 'Válidos'
  @UI.fieldGroup: [
    {
      position: 30,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 50
    }
  ]
  TotalValidos,

  @EndUserText.label: 'Encontrados'
  @UI.fieldGroup: [
    {
      position: 40,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 60
    }
  ]
  TotalMatch,

  @EndUserText.label: 'Candidatos'
  @UI.fieldGroup: [
    {
      position: 50,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 70
    }
  ]
  TotalBloqueables,

  @EndUserText.label: 'No encontrados'
  @UI.fieldGroup: [
    {
      position: 60,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 80
    }
  ]
  TotalNoEncontrados,

  @EndUserText.label: 'Errores'
  @UI.fieldGroup: [
    {
      position: 70,
      qualifier: 'Resultado'
    }
  ]
  @UI.lineItem: [
    {
      position: 90
    }
  ]
  TotalErrores,

  @EndUserText.label: 'Mensaje'
  @UI.fieldGroup: [
    {
      position: 80,
      qualifier: 'Resultado'
    }
  ]
  MensajeError,

  @UI.hidden: true
  CreatedBy,

  @UI.hidden: true
  CreatedAt,

  @UI.hidden: true
  LastChangedAt,

  _Log : redirected to composition child ZC_APOC_LOG
}
