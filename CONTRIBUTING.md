# Contributing to EDEN.jl

## Development rules

- Write source code, identifiers, inline comments, docstrings, tests, and commit-facing technical text in English.
- Keep game rules, behavioral policy, evolutionary update, energy bookkeeping, and metrics separated by module responsibility.
- Add or update tests for every behavioral change.
- Preserve stochastic reproducibility by using `abmrng(model)` or an explicitly supplied RNG.
- Avoid avoidable allocations in hot simulation loops.
- Do not introduce narrative examples that depend on spoilers from books, films, series, or games.

## Local workflow

```bash
julia --project=. scripts/bootstrap.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Pull requests

A pull request should state the scientific hypothesis or software issue it addresses, the parameters used for validation, and whether the change modifies model semantics or only implementation details.
