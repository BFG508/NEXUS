# Política de estabilidad de API — ETHOS.jl 1.x

## Alcance

A partir de v1.0.0, los símbolos exportados por `ETHOS` constituyen la API pública estable. Las funciones internas no exportadas pueden refactorizarse sin garantía de compatibilidad.

## Compatibilidad

Durante la serie 1.x se intentará preservar:

- nombres y significado de los tipos públicos;
- firmas existentes de funciones exportadas;
- semántica documentada de frecuencia, PPMI, embeddings, alineamiento, valencia y bootstrap;
- formatos principales de configuración y tablas de salida.

Se pueden añadir métodos, campos de salida opcionales y nuevas funcionalidades compatibles. Una corrección de seguridad, corrupción de datos o error científico grave puede justificar cambiar un comportamiento incorrecto; dicho cambio deberá documentarse en `CHANGELOG.md`.

## Fronteras documentales

La separación entre documentos forma parte de la semántica estable del framework. Ninguna operación basada en ventanas puede tratar el final de una obra y el inicio de otra como tokens adyacentes.

## Versionado

ETHOS sigue versionado semántico:

- `PATCH`: fixes compatibles;
- `MINOR`: nuevas capacidades compatibles;
- `MAJOR`: cambios incompatibles deliberados.
