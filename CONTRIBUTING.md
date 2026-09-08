# Contributing to NEXUS

NEXUS is intentionally multi-language. Changes should stay inside the owning project unless they modify a documented cross-project interface or repository-wide policy.

Before proposing a change, run the project's local tests where the runtime is available. GitHub Actions provides the authoritative clean-environment check for Julia, Python, R, MATLAB, Scala, and GnuCOBOL.

Do not commit local environments, generated simulation outputs, downloaded large datasets, compiled binaries, or `_release_assets/` / `_local_assets/`.

Project versions follow Semantic Versioning independently. Cross-project compatibility changes should document both producer and consumer expectations. When a stable interchange schema is introduced, version the data contract instead of depending on sibling implementation details.

## General development rules

- Keep source code, public identifiers, inline comments, and docstrings in English.
- Add or update tests for semantic behavior changes.
- Keep project READMEs aligned with implemented behavior and explicit modelling limitations.
- Preserve reproducibility controls such as seeds, fixtures, environment locks, and release metadata where the project exposes stochastic or data-dependent behavior.
- Avoid adding generated outputs or downloaded source datasets when a deterministic generation/download path is available.
- Do not introduce direct source-code imports between sibling NEXUS projects as a substitute for an interchange interface.

## EDEN development

EDEN has additional scientific/software constraints:

- keep game, policy, genome, evolution, biology, environment, and metrics as separate responsibilities;
- use `abmrng(model)` or an explicitly supplied RNG for stochastic operations;
- preserve deterministic reproducibility for fixed seeds;
- avoid unbounded per-agent data structures in hot paths unless scientifically required;
- distinguish empirical invasion resistance from a formal ESS proof;

Recommended EDEN local workflow:

```bash
cd EDEN
julia --project=. scripts/bootstrap.jl
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. scripts/run_theory_validation.jl
```

For EDEN pull requests, state the scientific hypothesis or software issue, parameters and seeds used for validation, and whether the change modifies model semantics or only implementation details.

## ETHOS development

ETHOS changes must preserve corpus/document boundaries, explicit provenance, deterministic seeds, and the distinction between descriptive semantic measurements and historical/causal interpretation. Alignment changes require tests for rank/anchor behavior; bootstrap changes must report valid replicate support and must not suppress unexpected errors. Cross-language semantic comparison requires an explicitly cross-lingual backend rather than bypassing the monolingual guard.

Repository-level NEXUS adapters belong under `integration/`; do not add NEXUS-specific adapter code inside `ETHOS/` or any other standalone project directory.
