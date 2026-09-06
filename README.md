# ETHOS.jl

**Evolution of Textual Humanism, Ontology and Semantics**

**Análisis reproducible de evolución conceptual y semántica en corpus históricos, filosóficos, religiosos y literarios.**

`ETHOS.jl` (**Evolution of Textual Humanism, Ontology and Semantics**) es un proyecto de NLP y humanidades digitales escrito en Julia. Su objetivo es estudiar cómo cambia el uso contextual de conceptos abstractos —por ejemplo, compasión, deber, existencia o alma— entre corpus pertenecientes a distintos periodos, autores o paradigmas culturales.

El repositorio parte de la especificación original del proyecto y añade una metodología explícita para evitar varios errores habituales en estudios diacrónicos: normalización por tamaño de corpus, trazabilidad de edición y traducción, separación entre palabra y concepto, alineamiento de espacios vectoriales, bootstrap, controles de frecuencia y separación estricta entre visualización e inferencia.

> **Importante:** el corpus incluido es completamente sintético y sirve únicamente para probar el software. Sus resultados no deben interpretarse como evidencia histórica, filosófica o literaria.

## Estado

**v1.0.0 — Stable Research Framework.**

El pipeline principal está implementado de extremo a extremo y usa únicamente bibliotecas estándar de Julia. Esto reduce la fragilidad de dependencias y permite auditar todas las transformaciones matemáticas importantes.

## Estabilidad 1.0

La v1.0.0 congela la base corregida de v0.2.0 como primera API estable del framework. No introduce cambios numéricos ni metodológicos respecto a v0.2.0. Las funciones públicas exportadas se consideran compatibles dentro de la serie 1.x salvo correcciones de seguridad o errores que hagan imposible preservar un comportamiento incorrecto. Consulta [`docs/api_stability.md`](docs/api_stability.md).

## Requisitos

- Linux, macOS o Windows.
- Julia **1.10 LTS o superior**.
- Recomendado: `juliaup` para gestionar versiones de Julia.
- Git y Visual Studio Code son opcionales.

No hay dependencias Julia externas en la versión base.

## Instalación

```bash
# Desde el .zip de la release:
unzip ETHOS.jl-v1.0.0.zip
cd ETHOS.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Si publicas el repositorio en GitHub, también puedes clonarlo con la URL real que le asignes y ejecutar los mismos comandos desde la raíz del proyecto.

Para verificar el repositorio:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Ejecución rápida

```bash
julia --project=. scripts/run_pipeline.jl
```

También puedes validar primero los corpus y sus checksums:

```bash
julia --project=. scripts/validate_corpus.jl
```

Y revisar cuántas apariciones de cada concepto hay en cada documento:

```bash
julia --project=. scripts/inspect_concepts.jl
```

Al finalizar, el pipeline genera:

```text
results/
├── report.md
├── run_metadata.toml
├── tables/
│   ├── document_metadata.csv
│   ├── corpus_summary.csv
│   ├── concept_frequency.csv
│   ├── concept_ppmi_associations.csv
│   ├── contextual_valence.csv
│   ├── tfidf_top_terms.csv
│   └── semantic_shift.csv
├── embeddings/
│   └── *_embedding.csv
└── figures/
    ├── concept_frequency.svg
    └── semantic_map_*.svg
```

## Qué analiza

El proyecto implementa varios niveles complementarios de análisis.

### 1. Frecuencia normalizada

Para un concepto `c` en un corpus con `N` tokens:

```math
f(c) = \frac{n_c}{N} \cdot S
```

con `S = 10^6` por defecto. De este modo no se comparan directamente recuentos brutos de corpus de tamaños distintos.

Los intervalos de confianza se estiman por **block bootstrap sensible a fronteras documentales**. Los bloques remuestreados permanecen como secuencias independientes: nunca se crean contextos artificiales entre documentos o bloques no contiguos.

### 2. Fronteras documentales

Cada obra se mantiene como una secuencia independiente durante coincidencia de aliases, coocurrencia, valencia, embeddings y bootstrap. El final de un documento **nunca** se considera adyacente al principio de otro. Las frecuencias de grupo agregan recuentos y denominadores, pero sin concatenar semánticamente las obras.

### 3. DTM y TF-IDF

Se genera una matriz documento-término y una representación TF-IDF como baseline descriptiva. La eliminación de stop-words se aplica únicamente a esta rama por defecto; no se destruyen automáticamente en los embeddings ni en el análisis contextual.

### 4. Coocurrencia y PPMI

Se construye una matriz de coocurrencia con ventana local y ponderación opcional por distancia. Después se calcula:

```math
PPMI(w,c) = \max\left(\log_2 \frac{P(w,c)}{P(w)P(c)}, 0\right)
```

El pipeline exporta las asociaciones PPMI principales de cada concepto como baseline interpretable.

### 5. Embeddings PPMI-SVD

La matriz PPMI se factoriza mediante SVD:

```math
M = U\Sigma V^T
```

con representación de palabra:

```math
E = U_k \Sigma_k^{1/2}
```

La elección PPMI-SVD busca una base determinista, transparente y auditable para la primera versión del proyecto. La arquitectura permite añadir posteriormente otros backends de embeddings sin cambiar la lógica de corpus, conceptos, alineamiento o estadística.

### 6. Alineamiento entre corpus

Dos embeddings entrenados por separado no comparten necesariamente el mismo sistema de coordenadas. Por ello `ETHOS.jl` **no compara directamente** sus vectores.

Para los términos ancla compartidos se resuelve el problema de Procrustes ortogonal:

```math
R^* = \arg\min_R \|X_BR - X_A\|_F,
\qquad R^TR = I
```

Los términos pertenecientes a los conceptos objetivo se excluyen de las anclas para reducir circularidad.

### 7. Desplazamiento semántico

Tras el alineamiento:

```math
D(c) = 1 - \cos(v_c^{A}, Rv_c^{B})
```

Un valor mayor significa mayor desplazamiento vectorial. **No significa automáticamente mayor diferencia filosófica, moral o histórica.**

### 8. Control por frecuencia

Los embeddings distribucionales pueden mostrar inestabilidad relacionada con frecuencia. Para cada concepto se seleccionan términos compartidos con frecuencia similar y se calcula una distribución de desplazamientos de control.

El resultado incluye:

- desplazamiento medio de los controles;
- desviación estándar;
- `z-score` descriptivo del concepto frente a esos controles;
- número de controles disponibles.

Este control ayuda a detectar resultados sospechosos, pero no elimina todos los confusores posibles.

### 9. Valencia contextual

En lugar de asignar un sentimiento global a una obra, se estudian ventanas alrededor de cada aparición del concepto. La versión base utiliza un lexicón explícito y tratamiento local de negación.

Esta métrica se denomina **valencia contextual estimada**. No debe interpretarse como una medición universal de moralidad o sentimiento filosófico.

### 10. PCA y figuras

Las representaciones 2D se generan mediante PCA y se exportan directamente a SVG.

Las distancias de las figuras **no se usan para calcular cambio semántico**. Toda inferencia cuantitativa se realiza en el espacio vectorial original.

## Palabra frente a concepto

Un concepto no se identifica necesariamente con una sola palabra. La configuración permite definir múltiples realizaciones léxicas e incluso expresiones de varias palabras:

```toml
[concepts.compassion]
label = "Compassion"
terms = ["compassion", "mercy", "kindness"]
```

El análisis distingue por tanto entre:

- **token:** forma textual observada;
- **alias:** forma léxica asociada a un concepto;
- **concepto:** conjunto explícito y versionado de aliases.

Esto reduce el riesgo de confundir cambio conceptual con simple sustitución de vocabulario.

## Estructura del repositorio

```text
ETHOS.jl/
├── Project.toml
├── README.md
├── LICENSE
├── CITATION.cff
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Makefile
├── .github/
│   └── workflows/
│       └── ci.yml
├── config/
│   ├── pipeline.toml
│   ├── pipeline_test.toml
│   ├── corpora.toml
│   ├── concepts.toml
│   ├── stopwords_en.txt
│   └── valence_en.toml
├── data/
│   ├── raw/
│   ├── metadata/
│   └── processed/
├── src/
│   ├── ETHOS.jl
│   ├── types.jl
│   ├── io.jl
│   ├── normalization.jl
│   ├── concepts.jl
│   ├── frequencies.jl
│   ├── matrices.jl
│   ├── embeddings.jl
│   ├── alignment.jl
│   ├── sentiment.jl
│   ├── statistics.jl
│   ├── visualization.jl
│   ├── reporting.jl
│   └── pipeline.jl
├── scripts/
├── notebooks/
├── test/
├── docs/
├── references/
└── results/
```

## Incorporar un corpus real

1. Obtén legalmente el texto y guárdalo en `data/raw/...`.
2. Calcula su SHA-256.
3. Añade una entrada a `config/corpora.toml`.
4. Registra como mínimo obra, autor, año, idioma, idioma original, edición, fuente y licencia.
5. Si analizas una traducción, identifica el traductor.
6. Añade o revisa los conceptos en `config/concepts.toml`.
7. Adapta stop-words y lexicón contextual al idioma y dominio.
8. Ejecuta `scripts/validate_corpus.jl` antes del pipeline.

Consulta [`docs/adding_a_real_corpus.md`](docs/adding_a_real_corpus.md) antes de introducir datos de investigación.

## Traducciones y comparabilidad

La traducción es un confusor de primer orden: una diferencia entre corpus puede proceder del autor, del periodo, del género, de la edición o del traductor.

`ETHOS.jl` obliga a conservar metadatos explícitos y puede exigir que toda traducción identifique su traductor. El pipeline base **no implementa alineamiento semántico cross-lingual**; las comparaciones vectoriales directas deben hacerse dentro de un mismo idioma de análisis salvo que se añada explícitamente un modelo cross-lingual validado.

## Reproducibilidad

Cada ejecución registra:

- versión de Julia;
- fecha y hora;
- checksums SHA-256 reales de los documentos;
- configuración versionada;
- seeds del bootstrap.

Los resultados generados se ignoran en Git por defecto para evitar mezclar código y artefactos derivados. Para una publicación o release científica se recomienda archivar juntos:

- commit/tag del código;
- `Manifest.toml` generado en la máquina de análisis;
- configuración;
- metadatos del corpus;
- checksums;
- resultados finales.

## Tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

La suite cubre:

- normalización y tokenización;
- aliases multiword y solapamientos;
- DTM, TF-IDF, coocurrencia y PPMI;
- recuperación de una rotación mediante Procrustes;
- bootstrap de frecuencia;
- ejecución end-to-end sobre el corpus sintético.

GitHub Actions ejecuta los tests en Julia 1.10 y 1.12.

## Rendimiento

El backend PPMI-SVD de esta versión utiliza matrices densas para mantener el código pequeño, transparente y sin dependencias externas. El parámetro `maximum_vocabulary` limita el coste de memoria y SVD.

Para corpus grandes:

- incrementa `minimum_count`;
- reduce `maximum_vocabulary` durante exploración;
- usa menos réplicas de bootstrap al depurar;
- aumenta las réplicas únicamente para el análisis final;
- considera un backend sparse/randomized-SVD como evolución futura.

## Límites metodológicos

El software no resuelve automáticamente:

- sesgo de selección del corpus;
- diferencias de género literario;
- dependencia entre autor y época;
- polisemia difícil de separar con embeddings estáticos;
- cambios introducidos por traducción o edición;
- OCR defectuoso;
- causalidad histórica;
- equivalencia entre proximidad distribucional y significado filosófico.

Estos límites están desarrollados en [`docs/methodology.md`](docs/methodology.md) y [`docs/limitations.md`](docs/limitations.md). Las decisiones sobre dependencias y backend se documentan en [`docs/design_decisions.md`](docs/design_decisions.md). El alcance exacto de esta release se resume en [`docs/implementation_status.md`](docs/implementation_status.md).

## Política de código e idioma

Siguiendo la especificación original:

- código, identificadores, comentarios y docstrings: **inglés**;
- documentación y comunicación con el usuario: **español**;
- al discutir obras narrativas: **cero spoilers salvo petición explícita**.

La visión/especificación de partida, actualizada únicamente al branding ETHOS, se encuentra en `references/project_specification.md`; la versión previa al cambio de nombre se conserva únicamente por trazabilidad en `references/project_specification_pre_ethos.md`. La documentación técnica vigente está en `docs/` y en este README.

## Licencia

El código se distribuye bajo licencia MIT. **La licencia del repositorio no se extiende a corpus externos añadidos por el usuario.** Cada documento debe respetar su propia licencia y condiciones de uso.

## Referencias metodológicas

La selección inicial de referencias se encuentra en [`references/bibliography.md`](references/bibliography.md), incluyendo trabajos sobre embeddings diacrónicos, PPMI/SVD y sesgos de frecuencia.
