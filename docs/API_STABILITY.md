# ETHOS 1.x API stability

ETHOS v1.0.0 established the first stable public API baseline. v1.1.0 preserves the exported 1.x entry points while strengthening incorrect or under-specified scientific behavior.

Within 1.x, compatible additions are preferred. A bug fix may reject an input that older versions accepted when that input produced scientifically undefined behavior, such as rank-deficient Procrustes alignment or unsupported cross-language comparison.

Internal helpers that are not exported by `ETHOS` are not part of the public compatibility promise.
