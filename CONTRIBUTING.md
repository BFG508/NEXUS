# Contributing to EDEN.jl

## Development rules

- Write source code, identifiers, inline comments and docstrings exclusively in English.
- Keep game, policy, genome, evolution, biology, environment and metrics as separate responsibilities.
- Add or update tests for every semantic change.
- Use `abmrng(model)` or an explicitly supplied RNG for stochastic operations.
- Preserve deterministic reproducibility for fixed seeds.
- Avoid unbounded per-agent data structures in hot paths unless scientifically required.
- Distinguish empirical invasion resistance from a formal ESS proof.
- Do not introduce narrative examples that depend on spoilers from books, films, series or games.

## Local workflow

```bash
julia --project=. scripts/bootstrap.jl
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. scripts/run_theory_validation.jl
```

## Pull requests

State the scientific hypothesis or software issue, parameters and seeds used for validation, and whether the change modifies model semantics or only implementation details.
