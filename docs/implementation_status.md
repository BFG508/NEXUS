# Estado de implementación — v0.2.0

`ETHOS.jl` v0.2.0 es la release de **corrección metodológica, QA y reproducibilidad** previa a estabilizar la API 1.0.

## Implementado y corregido

- pipeline reproducible de extremo a extremo;
- fronteras documentales preservadas en coincidencia conceptual, coocurrencia, valencia, embeddings y bootstrap;
- `test/runtests.jl` conectado al flujo estándar `Pkg.test()`;
- validación de coherencia de `label`, `period` e idioma dentro de cada grupo;
- tests de regresión numérica e invariantes matemáticos;
- DTM/TF-IDF, PPMI, PPMI-SVD, Procrustes, semantic shift, controles por frecuencia y bootstrap;
- provenance con hashes, versión de ETHOS/Julia, commit Git cuando existe, plataforma, arquitectura, threads y BLAS;
- CI en Julia 1.10 y 1.12 con tests, validación de corpus y smoke test end-to-end;
- documentación de metodología, limitaciones y reproducibilidad.

## Alcance

El corpus incluido sigue siendo sintético y solo valida el framework. Una investigación histórica real exige corpus reales, control filológico y validación externa. OCR, inferencia causal, embeddings contextuales y alineamiento cross-lingual permanecen fuera del núcleo 1.0.
