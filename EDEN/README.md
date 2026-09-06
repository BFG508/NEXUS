# EDEN.jl ⚖️

**E**volutionary **D**ynamics of **E**thical **N**etworks

EDEN is a Julia agent-based simulation framework for studying the conditions under which cooperation, reciprocity, and consideration for collective welfare emerge, persist, or are invaded. It separates game utility, decision policy, continuous strategy traits, doctrine families, evolutionary mechanisms, and environmental structure so each layer can be varied explicitly.

The active development tree is **v0.2.0 — Research Prototype**. EDEN is intended for computational experiments in evolutionary/game-theoretic dynamics; it does not identify cooperation with ethics, does not treat empirical invasion resistance as a formal ESS proof, and is not presented as a scientifically closed v1.0 model.

## Core capabilities

### Ethical genome and doctrine families

Each agent carries an `EthicalGenome` with four normalized continuous traits:

```text
base_cooperation
reciprocity
other_regard
forgiveness
```

A doctrine tag selects one of four policy families:

```text
Egoist
Altruist
Utilitarian
StrictReciprocal
```

The doctrine selects the policy family while the genome parameterizes behavior inside that family.

### Cultural evolution

Cultural imitation uses the Fermi rule:

\[
P(i \leftarrow j) = \frac{1}{1 + \exp[-\beta(f_j-f_i)]}.
\]

The simulation supports `AsynchronousUpdate` and `SynchronousUpdate` modes so update ordering can be treated as an explicit modelling choice.

### Biological evolution

`BiologicalEvolution` represents selection through resource-dependent death and reproduction. Agents at or below `death_energy` are removed; agents at or above `reproduction_energy` may reproduce subject to `carrying_capacity`. Offspring inherit doctrine/genome state with mutation according to the configured model parameters.

`HybridEvolution` applies cultural evolution and biological turnover in the same generation.

### Energy and game utility

Prisoner's Dilemma payoff is model utility rather than energy itself. Per-interaction energy change is defined by the configured payoff conversion and metabolic cost:

```text
ΔE = payoff_to_energy * payoff - metabolic_cost
```

The biological/hybrid modes use that resource state for population turnover.

### Bounded opponent memory

`memory_capacity` bounds the number of opponent histories retained by each agent. This avoids the unbounded all-pairs memory scaling of the v0.1 prototype and keeps memory usage approximately proportional to `N * memory_capacity`.

### Spatial and well-mixed environments

`build_model` can construct well-mixed or spatial experiments. Environment structure is kept separate from game/policy/evolution logic so comparative experiments can vary interaction topology independently.

### Invasion analysis and empirical ESS screening

Resident-invader experiments measure whether an initially rare doctrine increases under the configured simulation assumptions. The experiment layer can aggregate invasion outcomes, build an invasibility matrix, and identify empirical resistance candidates under a configurable threshold.

These procedures are screening tools. They do not constitute a mathematical proof of evolutionary stability.

### Ensemble uncertainty and analytical baseline

The experiment layer supports multiple seeds, ensemble summaries, dispersion estimates, and 95% confidence intervals. A simplified replicator-dynamics implementation provides an analytical baseline for the pure binary case where ABM and replicator assumptions are sufficiently comparable.

Directional agreement in that reduced case is a validation aid, not a claim that the full ABM is equivalent to replicator dynamics.

## Core API

The principal public modelling/experiment surface includes:

- `SimulationParameters` — complete ABM configuration;
- `EthicalGenome` — continuous strategy traits;
- `build_model` — constructs a well-mixed or spatial model;
- `run_simulation` — executes one replicate;
- `run_ensemble` — executes multiple seeds;
- `summarize_ensemble` — aggregates means, deviations, and 95% confidence intervals by generation;
- `run_invasion_experiment` — executes a resident-invader experiment;
- `summarize_invasions` — aggregates invasion results;
- `invasibility_matrix` — builds the invader-growth probability matrix;
- `empirical_ess_candidates` — screens resistant residents under a configurable threshold;
- `replicator_rhs`, `replicator_step`, `simulate_replicator` — analytical baseline;
- `validate_binary_abm_against_replicator` — directional validation of the pure binary case.

## NEXUS integration

EDEN v0.2.0 currently remains independently executable and does not yet consume or produce a stable NEXUS interchange schema. The repository architecture reserves future EDEN integration for a later development release rather than presenting incomplete adapters as current capability.

The intended domain boundary is social, ethical, and evolutionary dynamics. Any future NEXUS connection should exchange explicit data artifacts without importing sibling implementation internals.

## Reproducibility

Use explicit seeds for stochastic experiments and preserve the environment used for a reported campaign.

Bootstrap the project and run tests with:

```bash
julia --project=. scripts/bootstrap.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

To freeze the exact package environment for a campaign:

```bash
julia --project=. scripts/freeze_environment.jl
```

This produces `Manifest.toml`. For reproducible results, retain the Julia version, `Project.toml`, generated `Manifest.toml`, seeds, simulation parameters, and Git commit/tag used.

Stochastic source changes should use `abmrng(model)` or an explicitly supplied RNG rather than an uncontrolled global random stream.

## Julia requirements

Julia 1.10 LTS or stable Julia 1.12 is recommended for the current project line.

Restore the environment with:

```bash
julia --project=. scripts/bootstrap.jl
```

## Repository structure

```text
EDEN/
├── docs/
│   ├── MODEL.md                   Scientific model definition
│   └── VALIDATION.md              Release/validation protocol
├── notebooks/
│   └── 01_game_theory_math.jl     Analytical exploration
├── results/                       Generated results placeholder
├── scripts/
│   ├── benchmark_core.jl
│   ├── bootstrap.jl
│   ├── freeze_environment.jl
│   ├── plot_results.jl
│   ├── run_biological_simulation.jl
│   ├── run_ensemble.jl
│   ├── run_interactive.jl
│   ├── run_invasion_analysis.jl
│   ├── run_parameter_sweep.jl
│   ├── run_simulation.jl
│   ├── run_spatial.jl
│   ├── run_theory_validation.jl
│   └── run_uncertainty_analysis.jl
├── src/
│   ├── EDEN.jl
│   ├── agents.jl
│   ├── biology.jl
│   ├── environment.jl
│   ├── evolution.jl
│   ├── experiments.jl
│   ├── games.jl
│   ├── metrics.jl
│   ├── simulation.jl
│   ├── strategies.jl
│   ├── theory.jl
│   └── validation.jl
├── test/                          Julia unit/model regression tests
├── CHANGELOG.md
├── Project.toml
├── VERSION
└── README.md
```

## Usage

Cultural simulation:

```bash
julia --project=. scripts/run_simulation.jl
```

Biological simulation:

```bash
julia --project=. scripts/run_biological_simulation.jl
```

Spatial simulation:

```bash
julia --project=. scripts/run_spatial.jl
```

Ensemble and uncertainty analysis:

```bash
julia --project=. scripts/run_ensemble.jl
julia --project=. scripts/run_uncertainty_analysis.jl
```

Resident-invader analysis:

```bash
julia --project=. scripts/run_invasion_analysis.jl
```

Replicator/binary validation:

```bash
julia --project=. scripts/run_theory_validation.jl
```

Core benchmark:

```bash
julia --project=. scripts/benchmark_core.jl
```

## Tests and CI

Run the complete Julia test suite with:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

The suite covers game logic, strategies, agents, cultural/biological evolution, experiments, simulation behavior, theory utilities, and validation paths.

`.github/workflows/eden.yml` restores Julia and runs the package tests in a clean environment.

See `docs/VALIDATION.md` for the additional checks expected before tagging a scientific/research release.

## Important modeling assumptions

- Prisoner's Dilemma payoff is game utility and is not inherently a moral score or physical resource.
- Cooperation is an action/policy outcome and is not identified with ethics.
- Genome traits and doctrine families are model constructs chosen for experimentation rather than empirically established psychological dimensions.
- Cultural imitation follows the configured Fermi rule; biological turnover follows explicit energy thresholds and carrying capacity.
- Bounded memory limits stored opponent histories and therefore changes the information available to agents relative to unbounded-memory models.
- Empirical invasion resistance and `empirical_ess_candidates` are simulation diagnostics, not formal ESS proofs.
- Replicator comparison is meaningful only in the reduced cases where its assumptions are comparable with the ABM.
- Single-seed trajectories should not be used as population-level statistical evidence; use multiseed ensembles for uncertainty claims.
- EDEN is a research prototype for computational experiments, not a validated model of human moral behavior.

See `docs/MODEL.md` and `docs/VALIDATION.md` for the scientific model and release validation protocol.
