# Contributing

SemanticLogos.jl follows the language policy established by the project specification:
all source code, identifiers, comments and docstrings are written in English.

## Workflow

1. Create a branch from `main`.
2. Add or update tests for every behavioral change.
3. Run `julia --project=. -e 'using Pkg; Pkg.test()'`.
4. Run the example pipeline and inspect the generated report and SVG figures.
5. Keep corpus licensing and provenance metadata complete.

## Research integrity

Do not add a corpus without recording its edition, language, translator when relevant,
source, license and checksum. Do not interpret 2D projections as quantitative evidence.
Cross-corpus embedding comparisons must use an explicit alignment step.
