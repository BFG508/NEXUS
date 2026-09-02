# Main API

- `SimulationParameters`: complete ABM configuration.
- `EthicalGenome`: continuous traits of a strategy.
- `build_model`: builds a well-mixed or spatial model.
- `run_simulation`: runs one replicate.
- `run_ensemble`: runs multiple seeds.
- `summarize_ensemble`: computes means, deviations, and 95% CIs by generation.
- `run_invasion_experiment`: runs resident–invader experiments.
- `summarize_invasions`: aggregates invasion results.
- `invasibility_matrix`: generates the invader-growth probability matrix.
- `empirical_ess_candidates`: identifies resistant residents under a configurable threshold.
- `replicator_rhs`, `replicator_step`, `simulate_replicator`: analytical baseline.
- `validate_binary_abm_against_replicator`: directional validation of the pure binary case.
