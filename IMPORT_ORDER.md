# Orden de estabilización v0.4

1. Tablas / draft tables.
2. CDS interface/projection.
3. BDEF interface/projection.
4. Behavior pool `ZBP_I_APOC_RUN`.
5. Clases skeleton `ZCL_APOC_*`.
6. Completar manualmente en ADT, en este orden:
   - ZCL_APOC_PARSER
   - ZCL_APOC_MATCHER
   - ZCL_APOC_INGESTA
   - ZCL_APOC_PROCESSOR
   - ZCL_APOC_WRITER
   - ZCL_APOC_JOB
7. Crear Service Definition/Binding desde ADT una vez estable el backend.
