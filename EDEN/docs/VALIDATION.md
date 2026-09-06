# Validation protocol

Before tagging a release:

1. `julia --project=. scripts/bootstrap.jl`
2. `julia --project=. -e 'using Pkg; Pkg.test()'`
3. Run a well-mixed, spatial, and biological smoke test.
4. Generate a figure with `plot_results.jl`.
5. Run `run_theory_validation.jl`.
6. Run at least one multiseed ensemble and review the confidence intervals.
7. For stability studies, run `run_invasion_analysis.jl` with mutation disabled.
8. Record the Julia version, Project.toml, Manifest.toml, seed, parameters, and commit/tag used.

Directional agreement with replicator dynamics is required only in the simplified binary case for which the assumptions are comparable.
