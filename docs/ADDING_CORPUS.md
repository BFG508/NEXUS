# Adding a corpus

1. Obtain the text legally and record its source/license.
2. Store it under `data/raw/` or another configured project root.
3. Calculate SHA-256 when checksum enforcement is enabled.
4. Add a `[[documents]]` entry to the corpus manifest with ID, group, label, period, work, author, year, original year, analysis/original language, edition, source, license, path, and checksum.
5. Identify the translator whenever analysis language differs from original language and translation provenance is required.
6. Review concept aliases and lexicons for the analysis language.
7. Validate the corpus before running the full pipeline.
8. Define comparison pairs explicitly when the intended contrasts are not merely adjacent chronological groups.

The baseline backend only supports same-analysis-language semantic alignment.
