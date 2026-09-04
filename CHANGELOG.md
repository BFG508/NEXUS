# Changelog

All notable changes to this project will be documented in this file.

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
