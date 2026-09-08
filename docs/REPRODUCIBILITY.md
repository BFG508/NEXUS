# ETHOS reproducibility

A reproducible ETHOS study should preserve the package tag, Julia version, complete configuration, corpus and concept manifests, source texts, source/edition/license metadata, translation provenance, checksums, stopword/valence lexicons, random seed, and bootstrap settings.

`run_metadata.toml` records resolved paths/hashes and runtime context. A dirty Git working tree is recorded when detectable so results generated from uncommitted source changes are distinguishable from tagged releases.

Historical or real-corpus studies should archive the exact legal source material or a stable retrieval record when redistribution is not permitted.
