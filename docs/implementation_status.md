# Estado de implementación — v0.1.1

Esta versión mantiene el prototipo ejecutable y reproducible bajo la identidad canónica `ETHOS.jl` en un prototipo de investigación ejecutable y reproducible.

## Implementado

- estructura estándar de paquete Julia y entry points en `scripts/`;
- configuración TOML versionable para corpus, conceptos y pipeline;
- validación de provenance y checksums SHA-256;
- normalización Unicode y tokenización conservadora;
- distinción explícita entre token, alias y concepto;
- aliases de una o varias palabras con resolución de solapamientos;
- frecuencias normalizadas y block bootstrap;
- DTM y TF-IDF como baselines descriptivas;
- matrices de coocurrencia y PPMI;
- embeddings deterministas PPMI-SVD;
- alineamiento ortogonal Procrustes entre espacios independientes;
- desplazamiento semántico mediante distancia coseno en el espacio original;
- controles descriptivos emparejados por frecuencia;
- intervalos bootstrap para desplazamiento semántico;
- valencia contextual basada en lexicón y negación local;
- PCA exclusivamente para visualización;
- exportación de tablas CSV, embeddings, SVG, informe Markdown y metadatos de ejecución;
- corpus sintético redistribuible para demo y tests;
- tests unitarios e integración end-to-end;
- CI para Julia 1.10 y 1.12;
- documentación de arquitectura, metodología, limitaciones, reproducibilidad y alta de corpus reales;
- licencia, contributing, security, changelog y Citation File Format.

## Decisiones deliberadas

La versión base no depende de paquetes externos de NLP ni plotting. Se utiliza PPMI-SVD en lugar de Word2Vec como backend inicial porque permite una implementación determinista, auditable y autocontenida. La API mantiene separadas las etapas de corpus, representación, alineamiento y evaluación para poder incorporar backends adicionales más adelante.

`Manifest.toml` no se versiona en el repositorio. Para una release científica congelada debe generarse con Julia en el entorno de análisis y archivarse junto con el tag, la configuración, los checksums y los resultados.

## Fuera de alcance de v0.1.1

No se presentan como resueltos los problemas de polisemia contextual fina, alineamiento cross-lingual, OCR, inferencia causal histórica, equivalencia entre traducciones o escalado sparse a corpus de millones de tokens. Son extensiones que requieren validación específica y no simples cambios de software.
