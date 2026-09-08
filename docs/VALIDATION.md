# ETHOS validation

ETHOS validation covers software invariants and methodological failure guards rather than claiming historical truth from the synthetic fixture.

## Software invariants

Tests verify token normalization, alias spans, document-boundary isolation, DTM/TF-IDF values, PPMI properties, embedding dimensions, Procrustes recovery, rank/anchor failure handling, deterministic bootstrap behavior, manifest validation, language consistency, portable configuration, and end-to-end output generation.

## Alignment acceptance

A comparison must have:

- identical analysis language in the baseline backend;
- enough selected anchors for the embedding dimension;
- full numerical rank in reference and target anchor matrices; and
- concept-target terms excluded from the alignment set.

For real studies, inspect anchor counts, rank, frequency balance, and sensitivity to the anchor policy rather than treating a successful rotation as proof of semantic comparability.

## Bootstrap acceptance

A semantic CI is available only if the number of finite replicate estimates meets the configured absolute and fractional thresholds. Report `valid_bootstraps`, `requested_bootstraps`, and `bootstrap_sufficient` with every semantic-shift result.

## Interpretation

Software validation does not validate corpus selection, translation quality, edition choice, OCR, philosophical interpretation, or causal historical claims. Those remain study-design responsibilities.
