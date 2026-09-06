# Decisiones de diseño

## Por qué v1.0.0 no depende de TextAnalysis.jl o Word2Vec.jl

La especificación original proponía `TextAnalysis.jl`, `Word2Vec.jl`/`Embeddings.jl`, `Languages.jl`, `DataFrames.jl` y `Plots.jl`/`Makie.jl` como stack inicial. En esta primera implementación se ha priorizado una base reproducible y auditable con únicamente bibliotecas estándar de Julia.

La decisión tiene cuatro objetivos:

1. reducir incompatibilidades de versiones y tiempos de instalación;
2. mantener visibles las transformaciones matemáticas centrales;
3. hacer que CI pueda verificar el núcleo sin descargar un ecosistema amplio;
4. establecer baselines sólidos antes de introducir modelos más complejos.

## Embedding base

PPMI-SVD no pretende sustituir para siempre a Word2Vec. Se utiliza como backend inicial porque permite relacionar directamente:

```text
coocurrencia -> PPMI -> factorización -> embedding
```

Esto hace sencillo inspeccionar dónde aparece una asociación y comparar el embedding con su baseline de coocurrencia.

## Extensiones futuras compatibles

La arquitectura separa corpus, conceptos, estadística y alineamiento del constructor de embeddings. Por ello pueden añadirse posteriormente backends como:

- SGNS/Word2Vec;
- FastText;
- embeddings contextuales por ocurrencia;
- modelos cross-lingual;
- randomized/truncated SVD sparse para corpus grandes.

Una extensión debería implementar la misma semántica básica de `EmbeddingSpace` y conservar las pruebas de alineamiento y trazabilidad.

## Visualización sin dependencia

Los gráficos se exportan directamente como SVG. Se evita convertir una biblioteca gráfica en dependencia del núcleo y se mantiene la posibilidad de regenerar figuras con Makie u otra herramienta desde los CSV exportados.

## DTM sin DataFrames

Las tablas se representan internamente con matrices y estructuras Julia simples y se exportan a CSV. `DataFrames.jl` puede ser útil en notebooks exploratorios, pero no es necesario para ejecutar el pipeline reproducible.


## Document boundaries are first-class

Documents are never concatenated for window-based semantics. Group aggregation is implemented over independent token sequences so aliases, co-occurrence and contextual metrics cannot cross source boundaries.
