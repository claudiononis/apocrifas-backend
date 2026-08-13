# Orden sugerido de activación tras Pull

1. ZAPOC_RUN, ZAPOC_RUN_D, ZAPOC_STG, ZAPOC_LOG, ZAPOC_LOG_D
2. ZI_APOC_LOG, ZI_APOC_RUN
3. ZCL_APOC_PARSER, ZCL_APOC_MATCHER, ZCL_APOC_INGESTA, ZCL_APOC_PROCESSOR, ZCL_APOC_WRITER, ZCL_APOC_JOB
4. ZBP_I_APOC_RUN + BDEF ZI_APOC_RUN
5. ZC_APOC_LOG, ZC_APOC_RUN + projection BDEF
6. ZUI_APOC_RUN_O4 Service Definition
7. ZUI_APOC_RUN_O4 Service Binding: abrir y Publish manualmente.

Si abapGit informa dependencias durante Deserialize, importar todo y luego activar en este orden.
