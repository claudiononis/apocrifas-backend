# APOC backend demo v0.3 (abapGit)

Backend demo para Facturas Apócrifas, derivado del patrón técnico de ZPADRON_EMBARGO.

**Guardrail:** esta versión NO modifica Business Partner. El writer devuelve WRITE_DISABLED.

## Importación
1. Crear repo Git privado y subir este contenido (raíz con `.abapgit.xml` y `src/`).
2. En ADT > abapGit Repositories > +, vincular el repo al paquete `ZAPOCRIFAS`.
3. Pull/Import.
4. Activar primero tablas, luego CDS/BDEF/clases y por último Service Definition/Binding.
5. Si el Service Binding no queda publicado tras importar, abrir `ZUI_APOC_RUN_O4` y publicar manualmente.

## Alcance v0.3
CSV APOC -> RAP Run -> bgPF -> parser -> I_Supplier -> staging/log -> TERMINADO.
Sin PATCH a API_BUSINESS_PARTNER.

## Importante
Los archivos están serializados con el mismo formato abapGit observado en el paquete real `ZPADRON_EMBARGO`. No pueden ser validados contra el compilador de tu tenant desde fuera de S/4; cualquier incompatibilidad de release/released objects se corrige tras el primer Pull/activation.
