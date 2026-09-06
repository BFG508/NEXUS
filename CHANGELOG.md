# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-09-06

### Stable
- Promoted the v0.2.0 correctness and reproducibility baseline to the first stable ETHOS research-framework release.
- Declared the exported public API stable for the 1.x series.
- Added an explicit API-stability and compatibility policy.

### Compatibility
- No source-code, test, numerical or methodological behavior changes relative to v0.2.0.
- The synthetic corpus remains a software validation fixture and is not historical evidence.

## [0.2.0] - 2026-09-06

### Fixed
- Preserved document boundaries throughout concept matching, co-occurrence, contextual valence, PPMI-SVD embeddings and semantic-shift analysis.
- Reworked block bootstrap so sampled blocks remain independent sequences and cannot create artificial cross-block contexts.
- Moved the Julia test entry point from `tests/` to the standard `test/` directory so `Pkg.test()` and `julia-runtest` execute the suite correctly.
- Added group-level metadata validation for label, period and analysis language.

### Added
- Regression tests for document-boundary isolation, deterministic bootstrap, TF-IDF values, PPMI invariants and Procrustes orthogonality.
- Extended run provenance with ETHOS version, Git commit when available, OS, architecture, CPU/thread information and BLAS vendor.
- CI corpus validation and end-to-end pipeline smoke test.

### Changed
- Optimized TF-IDF by precomputing document row totals.
- Clamped cosine similarity to its mathematical range and added explicit rejection of degenerate embedding dimensions.
- Tightened required corpus-manifest fields and corpus validation.
- The pipeline now uses boundary-preserving token-sequence collections internally while retaining single-sequence public methods for compatibility.

## [0.1.1] - 2026-09-06

### Changed
- Rebranded the project from `SemanticLogos.jl` to `ETHOS.jl`.
- Renamed the Julia package and public module to `ETHOS`.
- Updated scripts, tests, reports, documentation, metadata, citation information, fixtures and repository paths to the new identity.
- Defined the canonical acronym as **Evolution of Textual Humanism, Ontology and Semantics**.
- Preserved the pre-rebrand project specification in `references/project_specification_pre_ethos.md` for provenance.

### Compatibility
- No methodological, numerical or scientific behavior changes relative to v0.1.0.
- The package import changes from `using SemanticLogos` to `using ETHOS`.

## [0.1.0] - 2026-09-06

### Added
- Reproducible corpus manifest and checksum validation.
- Configurable Unicode-aware tokenization and task-specific preprocessing.
- Word-level and concept-level analysis with multiword aliases.
- Frequency, document-term matrix, TF-IDF, co-occurrence and PPMI baselines.
- PPMI-SVD word embeddings implemented with Julia standard libraries.
- Orthogonal Procrustes alignment for cross-corpus semantic comparison.
- Concept semantic-shift metrics and block-bootstrap uncertainty estimates.
- Transparent contextual-valence analysis with local negation handling.
- PCA-based visualization exported as dependency-free SVG.
- End-to-end pipeline, tests, CI, documentation and synthetic example corpus.
