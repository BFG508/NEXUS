# ETHOS methodology

ETHOS separates corpus provenance, lexical realization, distributional representation, alignment, descriptive controls, and uncertainty.

## Analysis units

Documents remain separate token sequences. Group-level frequencies aggregate numerators/denominators without creating cross-document contexts. Concept aliases are explicit configuration rather than inferred semantic equivalence.

## Embedding baseline

The default backend builds local co-occurrence, converts it to PPMI, and applies SVD with \(U_k\Sigma_k^{1/2}\) word vectors. The backend is intentionally transparent and deterministic.

## Alignment

Procrustes is fitted on shared non-target anchor terms. v1.1.0 applies frequency-stability filtering, row normalization, minimum-anchor constraints, and numerical-rank checks. The minimum number of anchors must be at least the actual embedding dimension, and substantially more anchors are recommended for real studies.

Anchor stability is a modelling assumption; passing a rank test does not prove that an anchor's meaning is historically fixed.

## Semantic shift

Shift is one minus cosine similarity after target-space alignment. Concepts with no shared representable alias return unavailable/NaN measurements rather than fabricated values.

## Bootstrap

Frequency and semantic uncertainty use circular moving blocks sampled within each document. Semantic bootstrap rebuilds embedding/alignment once per replicate and then evaluates all concepts. Invalid expected alignments are counted; unexpected errors stop the run. CIs require sufficient valid replicates.

## Contextual valence

Valence uses a configured lexicon around concept occurrences and local negation handling. It is a transparent descriptive metric rather than a universal sentiment model.
