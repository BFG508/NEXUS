# EDEN 🌱

**E**volutionary **D**ynamics of **E**thical **N**etworks

EDEN is a Julia research simulator for agent-based evolutionary-game experiments involving cooperation, reciprocity, bounded opponent memory, cultural imitation, biological turnover, continuous ethical-genome traits, and controlled invasion studies. It combines an explicit Prisoner's Dilemma interaction model with well-mixed or spatial populations and a reduced replicator-dynamics reference model.

The project is intended for computational experiments and methodological validation. Doctrine families and genome traits are model constructs; EDEN is not a validated psychological or moral model of human populations.

## Core capabilities

### Agent strategies and continuous traits

Agents carry a doctrine tag — `Egoist`, `Altruist`, `Utilitarian`, or `StrictReciprocal` — together with a continuous `EthicalGenome` containing base cooperation, reciprocity, other-regard, and forgiveness parameters. Doctrine-specific projection keeps genomes inside the intended experimental regions.

### True bounded LRU opponent memory

EDEN v0.3.0 uses bounded least-recently-used memory. Updating an already-known opponent moves that opponent to the most-recent position; once capacity is full, the least recently used opponent is evicted. A memory capacity of zero removes opponent-history information entirely.

### Cultural, biological, and hybrid evolution

The model supports:

- asynchronous or synchronous cultural imitation using a configurable Fermi selection rule;
- biological mortality/reproduction driven by energy thresholds and carrying capacity;
- inheritance plus continuous-trait and doctrine mutation; and
- hybrid runs combining cultural and biological mechanisms.

### Well-mixed and spatial populations

The default model is well mixed. A periodic 2-D `GridSpace` mode provides local interaction neighborhoods and optional agent motion.

### Ensemble uncertainty

`run_ensemble` executes independent seeded realizations. `summarize_ensemble` supports Student-t mean intervals and bootstrap mean intervals rather than assuming a fixed normal approximation for every sample size.

For a sample mean \(\bar{x}\), Student-t uncertainty uses

\[
\bar{x} \pm t_{1-\alpha/2,n-1}\frac{s}{\sqrt{n}}.
\]

The bootstrap option resamples replica values directly with an explicit seed.

### Controlled invasion experiments

Invasion runs now report both frequency and absolute growth:

```text
initial_fraction / final_fraction
initial_count    / final_count
frequency_growth
absolute_growth
```

The historical `grew` field is retained for compatibility and means **frequency growth**. `grew_absolute` records absolute population-count growth.

Invasion summaries use Wilson intervals for the probability of frequency growth. This avoids treating a small-binomial proportion as if it automatically had Gaussian uncertainty.

### Empirical ESS diagnostics

`empirical_ess_candidates` remains an empirical simulation diagnostic, not a mathematical ESS proof. v0.3.0 strengthens it by requiring complete resident-versus-invader coverage by default and by using the upper bound of the Wilson interval when checking whether invasion success is below the configured threshold.

`empirical_ess_diagnostics` exposes the evidence behind each classification so an incomplete invasion matrix cannot silently appear to support an ESS candidate.

### ABM-to-replicator validation

EDEN includes a reduced replicator model and two comparison levels:

- `validate_binary_abm_against_replicator` for a controlled two-doctrine directional comparison; and
- `validate_abm_replicator_convergence` for a grid over population size and selection intensity.

The convergence study is designed to test whether ABM trends approach the reduced mean-field reference in regimes where the assumptions become more comparable. It does not assert exact equivalence between the full ABM and replicator dynamics.

## NEXUS integration

The standalone EDEN release contains no NEXUS integration code. NEXUS keeps the cross-domain bridge under the repository-level `integration/` directory.

A semantic profile produced by ETHOS can be transformed into `nexus.eden_initialization.v1` only through an explicit mapping policy. The policy is recorded with the output because textual semantic measurements are not intrinsically EDEN moral parameters.

The repository-level adapter can translate that contract into a generic EDEN TOML configuration consumed by:

```bash
julia --project=EDEN EDEN/scripts/run_configured.jl eden_config.toml eden_metrics.csv
```

EDEN metrics can then be normalized by the integration layer as `nexus.society_state.v1`.

## Reproducibility

Stochastic entry points expose explicit seeds. Ensemble runs record a seed column, while bootstrap confidence intervals use a separate deterministic seed argument. Reproducible studies should preserve:

- EDEN version/tag;
- complete `SimulationParameters`;
- generation count;
- all ensemble/bootstrap seeds;
- Julia/Agents/DataFrames versions; and
- any external scenario-mapping policy used before EDEN execution.

A `Manifest.toml` may be frozen for a specific campaign with `scripts/freeze_environment.jl` when bit-for-bit environment reconstruction is required.

## Julia requirements

- Julia **1.10 or newer**.
- Agents.jl 7.x.
- DataFrames, CSV, CairoMakie, and GLMakie according to `Project.toml` compatibility bounds.

Instantiate the project with:

```bash
julia --project=EDEN -e 'using Pkg; Pkg.instantiate()'
```

## Repository structure

```text
EDEN/
├── src/                         Model, evolution, UQ, experiments and validation
├── test/                        Julia package tests
├── scripts/                     Simulation, ensemble, invasion and validation entry points
├── notebooks/                   Mathematical exploration
├── docs/
│   ├── MODEL.md                 Formal model description
│   └── VALIDATION.md            Validation and inference protocol
├── results/                     Generated results; ignored except placeholder
├── Project.toml
├── VERSION
├── CHANGELOG.md
└── README.md
```

The MIT license is provided at the NEXUS repository root and is copied into standalone release archives.

## Usage

Run the default simulation:

```bash
julia --project=EDEN EDEN/scripts/run_simulation.jl
```

Other entry points include:

```bash
julia --project=EDEN EDEN/scripts/run_ensemble.jl
julia --project=EDEN EDEN/scripts/run_invasion_analysis.jl
julia --project=EDEN EDEN/scripts/run_uncertainty_analysis.jl
julia --project=EDEN EDEN/scripts/run_theory_validation.jl
julia --project=EDEN EDEN/scripts/run_biological_simulation.jl
julia --project=EDEN EDEN/scripts/run_spatial.jl
```

A programmatic example:

```julia
using EDEN

params = SimulationParameters(
    population_size = 500,
    initial_doctrine_fractions = (0.25, 0.25, 0.25, 0.25),
    memory_capacity = 32,
    selection_intensity = 0.5,
    mutation_rate = 0.002,
    seed = 42,
)

metrics, model = run_simulation(params; generations = 500)
```

## Tests and CI

Run the Julia suite with:

```bash
julia --project=EDEN -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The suite covers strategy behavior, bounded LRU memory, cultural/biological evolution, simulation metrics, ensemble UQ, invasion summaries, matrix-completeness ESS logic, and theory-validation helpers. The NEXUS `eden.yml` workflow executes this suite on GitHub Actions.

## Important modelling assumptions

- Prisoner's Dilemma payoff is game utility, not a moral score or physical resource.
- Cooperation is an action/policy outcome and is not identified with ethics.
- Doctrine labels and genome coordinates are experimental abstractions rather than measured psychological dimensions.
- Cultural imitation and biological reproduction encode different mechanisms and should not be conflated.
- Bounded memory changes the information structure of the game and can materially affect reciprocal strategies.
- `empirical_ess_candidates` is a finite-simulation diagnostic; complete coverage and Wilson uncertainty reduce false confidence but do not constitute a formal ESS proof.
- Frequency growth can occur while absolute invader count falls, which is why v0.3.0 reports both quantities.
- Replicator comparisons are meaningful only under controlled simplifications where mean-field assumptions are approximately relevant.
- Single-seed trajectories are demonstrations, not population-level statistical evidence.
- ETHOS-derived NEXUS initialization requires an explicit scenario policy and is not empirical identification of ethical traits from language.

See `docs/MODEL.md` and `docs/VALIDATION.md` for additional detail.
