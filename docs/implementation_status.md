# Estado de implementación — v1.0.0

`ETHOS.jl` v1.0.0 es la primera versión estable del **Research Framework**. El núcleo de `src/` y la suite de `test/` son idénticos a v0.2.0: esta release congela la base de corrección y reproducibilidad sin modificar sus resultados.

## Núcleo estable

- fronteras documentales preservadas en todas las operaciones con contexto local;
- frecuencia conceptual y bootstrap sensibles a fronteras;
- DTM/TF-IDF, coocurrencia, PPMI y embeddings PPMI-SVD;
- alineamiento ortogonal Procrustes y semantic shift;
- controles descriptivos emparejados por frecuencia;
- valencia contextual con negación local;
- metadatos de provenance y checksums SHA-256;
- `Pkg.test()` mediante `test/runtests.jl`;
- tests de regresión, invariantes, fronteras, casos límite e integración end-to-end;
- CI para Julia 1.10 y 1.12, validación del corpus y smoke test;
- documentación de arquitectura, metodología, limitaciones, reproducibilidad y estabilidad de API.

## Qué significa “estable”

La serie 1.x preservará la API pública documentada siempre que sea razonablemente posible. Nuevos backends o análisis podrán añadirse de forma compatible. Cambios incompatibles deliberados requerirán una nueva versión mayor.

## Qué no significa

La estabilidad del software no convierte el corpus sintético en un estudio histórico. Para producir resultados científicos siguen siendo necesarios corpus reales, control filológico, diseño experimental y validación externa.
