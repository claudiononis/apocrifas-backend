# APOC backend demo v0.4 — estructura RAP + clases skeleton

Objetivo de esta versión: importar por abapGit la estructura declarativa del backend y crear las clases con esqueletos mínimos válidos. La lógica ABAP se completa después, clase por clase, directamente en ADT y se activa antes de consolidarla nuevamente en Git.

## Incluido

- Tablas y draft tables APOC.
- CDS interface/projection.
- Behavior Definitions RAP.
- Behavior pool `ZBP_I_APOC_RUN`.
- Clases `ZCL_APOC_*` como esqueletos mínimos.
- `ZCL_APOC_JOB` conserva únicamente las interfaces bgPF necesarias para que el behavior saver pueda referenciarla.

## Diferido intencionalmente

- Service Definition `ZUI_APOC_RUN_O4`.
- Service Binding `ZUI_APOC_RUN_O4`.
- Lógica funcional de Parser/Matcher/Ingesta/Processor/Writer/Job.
- PATCH real a Business Partner.

## Metodología

1. Pull abapGit para crear estructura y clases skeleton.
2. Verificar que los objetos existan/activen.
3. Completar una clase por vez en ADT.
4. Activar y probar cada clase.
5. Al cierre, Stage/Commit/Push desde abapGit para que Git quede con la serialización generada por S/4.
