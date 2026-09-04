# Arquitectura

## Flujo principal

```text
config/corpora.toml
        │
        ▼
  ingestion + SHA-256
        │
        ▼
 normalization/tokenization
        │
        ├────────► DTM ─► TF-IDF
        │
        ├────────► concept spans ─► normalized frequency ─► block bootstrap
        │
        ├────────► context windows ─► contextual valence
        │
        └────────► co-occurrence ─► PPMI ─► SVD embeddings
                                      │
                                      ├──► PPMI associations
                                      ├──► PCA ─► SVG only
                                      └──► Procrustes alignment
                                                │
                                                ├──► semantic shift
                                                ├──► frequency controls
                                                └──► semantic bootstrap
```

## Módulos

- `types.jl`: tipos de datos estables.
- `io.jl`: configuración, corpus, checksums y CSV.
- `normalization.jl`: preprocesamiento no destructivo.
- `concepts.jl`: aliases y detección de spans.
- `frequencies.jl`: vocabularios y frecuencias.
- `matrices.jl`: DTM, TF-IDF, coocurrencia y PPMI.
- `embeddings.jl`: PPMI-SVD y operaciones vectoriales.
- `alignment.jl`: Procrustes, cambio semántico y controles.
- `sentiment.jl`: valencia contextual explícita.
- `statistics.jl`: bootstrap por bloques.
- `visualization.jl`: PCA y SVG sin dependencias.
- `reporting.jl`: informe reproducible.
- `pipeline.jl`: orquestación end-to-end.

## Principios

1. Ninguna figura 2D se usa como evidencia cuantitativa de distancia.
2. Los espacios independientes se alinean antes de compararse.
3. Los corpus se identifican por metadatos y checksum.
4. El concepto es una configuración versionada, no una suposición implícita.
5. El pipeline base es dependency-light y auditable.
6. Las funciones matemáticas centrales se mantienen separadas de I/O.
