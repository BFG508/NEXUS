# ETHOS.jl 🧭

**E**volution of **T**extual **H**umanism, **O**ntology and **S**emantics

ETHOS.jl is a Julia research framework for reproducible lexical, conceptual, contextual, and diachronic semantic analysis of text corpora. It measures normalized concept frequency, PPMI associations, contextual valence, distributional embeddings, aligned semantic displacement, frequency-matched controls, and bootstrap uncertainty while preserving document and provenance boundaries.

The bundled corpus is synthetic and exists only to validate software behavior. ETHOS output is not historical, philosophical, moral, or causal evidence merely because a numerical semantic displacement is observed.

## Core capabilities

### Corpus provenance and document boundaries

Every source document is represented explicitly in a TOML corpus manifest with work, author, year, original year, analysis/original language, edition, source, license, path, and optional translation provenance. SHA-256 checks can be required before analysis.

Document token sequences remain separate during alias matching, co-occurrence, contextual valence, embeddings, and bootstrap. ETHOS never creates a false context between the end of one work and the beginning of another.

### Concept definitions

A concept is an explicit versioned set of lexical aliases rather than a single assumed word. Single tokens and multi-token spans can be used for frequency/context analysis. Multiword embedding representation remains an approximation based on constituent vectors and is documented as a limitation.

### Frequency, TF-IDF and PPMI

Normalized concept frequency is computed as

\[
f(c)=\frac{n_c}{N}S,
\]

with configurable scale \(S\). ETHOS also exports a document-term TF-IDF baseline and local co-occurrence PPMI associations:

\[
PPMI(w,c)=\max\left(\log_2\frac{P(w,c)}{P(w)P(c)},0\right).
\]

### Auditable PPMI-SVD embeddings

The baseline embedding backend is deterministic PPMI-SVD:

\[
M=U\Sigma V^T, \qquad E=U_k\Sigma_k^{1/2}.
\]

This keeps the first stable backend dependency-light and mathematically inspectable. Large-corpus sparse/truncated backends remain future extensions rather than being implied by the current implementation.

### Rank-safe semantic alignment

Separately trained distributional spaces are aligned before semantic comparison. ETHOS v1.1.0 strengthens orthogonal Procrustes alignment by:

- excluding target-concept terms from anchors;
- requiring at least as many usable anchors as embedding dimensions;
- checking numerical anchor rank;
- row-normalizing anchors before fitting the rotation;
- filtering anchors by minimum frequency and cross-corpus frequency balance; and
- making anchor selection deterministic.

The fitted transform solves

\[
R^*=\arg\min_R\lVert X_BR-X_A\rVert_F, \qquad R^TR=I.
\]

A rank-deficient or under-anchored comparison fails explicitly instead of silently returning an arbitrary rotation.

### Explicit comparison plan and language guard

Comparisons are configured explicitly:

```toml
[[comparisons]]
reference = "ancient"
target = "enlightenment"
```

When no list is supplied, the pipeline can derive adjacent chronological comparisons. ETHOS v1.1.0 rejects comparisons whose analysis languages differ because the baseline has no cross-lingual embedding backend.

### Semantic displacement and frequency controls

After alignment, conceptual displacement is

\[
D(c)=1-\cos(v_c^A,Rv_c^B).
\]

Frequency-matched shared non-concept terms provide a descriptive control distribution and a control `z_score`. This is a diagnostic for frequency-related embedding instability, not a universal deconfounding correction.

### Contextual valence

Valence is measured locally around concept occurrences using a transparent lexicon and configurable negation handling. The output is labelled contextual valence; ETHOS does not interpret it as universal sentiment, morality, or philosophical value.

### Bootstrap uncertainty

v1.1.0 uses circular moving-block resampling independently within each document, preserving document lengths and boundaries. Semantic bootstrap builds each reference/target embedding pair once per replicate and evaluates all concepts from that pair, avoiding repeated SVD work for every concept.

Expected insufficient/rank-deficient alignment failures are counted as invalid replicates. Unexpected exceptions are rethrown. A semantic CI is reported only when both the configured minimum count and minimum fraction of valid replicates are satisfied; otherwise the interval is marked unavailable rather than presenting a poorly supported percentile interval.

## NEXUS integration

The standalone ETHOS release contains no NEXUS integration code. Repository-level adapters under `../integration/` package ETHOS result tables as `nexus.semantic_culture_profile.v1`.

A downstream ETHOS-to-EDEN transform is deliberately separated into an explicit policy artifact:

```text
ETHOS results
    ↓
semantic_culture_profile.v1
    ↓
scenario mapping policy
    ↓
eden_initialization.v1
```

The mapping policy is a modelling choice, not an estimator that infers human ethical traits from language.

## Reproducibility

`run_metadata.toml` records the ETHOS version, Git commit when available, dirty-tree state, Julia/OS/architecture information, thread/BLAS context, configuration hash, input hashes, document hashes, random seed, and the resolved analysis root. Numeric CSV output uses sufficient precision for stable `Float64` round-tripping.

For a publishable corpus study, preserve the exact corpus manifest, concept definitions, preprocessing configuration, source/edition/translation provenance, checksums, ETHOS tag, Julia version, and bootstrap settings.

## Julia requirements

- Julia **1.10 or newer**.
- No external Julia package dependencies in the baseline implementation.

Instantiate and test with:

```bash
julia --project=ETHOS -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

## Repository structure

```text
ETHOS/
├── config/                       Pipeline, corpus, concept and lexicon configuration
├── data/                         Synthetic fixture plus corpus metadata layout
├── docs/
│   ├── METHODOLOGY.md
│   ├── VALIDATION.md
│   ├── REPRODUCIBILITY.md
│   ├── ADDING_CORPUS.md
│   └── API_STABILITY.md
├── notebooks/                    Exploratory analysis
├── references/                   Bibliography
├── results/                      Generated outputs; ignored except placeholders/README
├── scripts/                      Pipeline/validation/inspection entry points
├── src/                          Package implementation
├── test/                         Julia package tests
├── Project.toml
├── VERSION
├── CITATION.cff
├── CHANGELOG.md
└── README.md
```

The NEXUS repository-level MIT license is copied into the standalone ETHOS release archive.

## Usage

Run the software-validation pipeline:

```bash
julia --project=ETHOS ETHOS/scripts/run_pipeline.jl
```

Validate corpus metadata/checksums first with:

```bash
julia --project=ETHOS ETHOS/scripts/validate_corpus.jl
```

Inspect concept counts with:

```bash
julia --project=ETHOS ETHOS/scripts/inspect_concepts.jl
```

The pipeline produces a Markdown report, run metadata, tabular frequency/PPMI/valence/semantic-shift outputs, embedding CSVs, and SVG figures under `results/`.

## Tests and CI

Run:

```bash
julia --project=ETHOS -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The suite covers normalization, concept spans, document-boundary isolation, DTM/TF-IDF/PPMI invariants, embedding/alignment behavior, rank safeguards, frequency controls, deterministic bootstrap behavior, bootstrap-support thresholds, contextual valence, metadata validation, cross-language rejection, portable configuration roots, regression cases, and an end-to-end synthetic-corpus pipeline.

The NEXUS `ethos.yml` workflow runs the package tests and a pipeline smoke test on Julia 1.10.

## Important methodological assumptions

- Semantic displacement is a distributional-text measurement, not direct conceptual, moral, or causal evidence.
- Alignment quality depends on adequate stable shared vocabulary; rank checks prevent one failure mode but do not prove anchors are historically invariant.
- The baseline is monolingual. Cross-language comparisons are rejected unless a future explicitly cross-lingual backend is introduced.
- Frequency-matched controls expose one source of instability but do not remove author, genre, edition, OCR, translation, corpus-selection, or polysemy confounding.
- Circular moving-block bootstrap represents local token dependence within documents; alternative hierarchical/document-level uncertainty models may be preferable for some corpora.
- Alias vectors are uniformly averaged in the baseline; rare and common aliases can therefore contribute equally to a concept vector.
- Multiword semantic representation is approximate in the PPMI-SVD backend.
- Per-group PCA figures are descriptive views and are not used to calculate semantic shift.
- The bundled synthetic corpus validates software mechanics only.

See `docs/METHODOLOGY.md`, `docs/VALIDATION.md`, and `docs/REPRODUCIBILITY.md` before interpreting results from a real corpus.
