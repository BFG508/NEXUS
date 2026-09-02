# EDEN.jl

**Evolutionary Dynamics of Ethical Networks**

EDEN is a Julia agent-based simulator for studying the conditions under which policies of cooperation, reciprocity, and consideration for collective welfare emerge, persist, or are invaded.

## Version

**v0.2.0 — Research Prototype**

v0.2 extends the v0.1 Stable Prototype without yet presenting the project as a scientifically closed v1.0.

## Main additions since v0.1

- `EthicalGenome`: separates continuous traits, policy, and doctrine tag.
- bounded per-agent memory, instead of O(N²) memory;
- `CulturalEvolution`, `BiologicalEvolution`, and `HybridEvolution` modes;
- energy-dependent death and reproduction;
- offspring inheritance and mutation;
- synchronous or asynchronous cultural updating;
- resident–invader experiments and invasibility matrix;
- empirical ESS screening;
- multiseed UQ with 95% CIs;
- directional ABM validation against replicator dynamics in the pure binary case;
- expanded tests, benchmarks, documentation, and licensing.

## Installation

Recommended: Julia 1.10 LTS or stable Julia 1.12.

```bash
julia --project=. scripts/bootstrap.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

To freeze the exact environment of an experimental campaign:

```bash
julia --project=. scripts/freeze_environment.jl
```

This generates `Manifest.toml`; for reproducibility of a specific campaign, it should be retained alongside the results or the release tag.

## Architecture

```text
src/
├── EDEN.jl
├── games.jl
├── agents.jl
├── strategies.jl
├── environment.jl
├── evolution.jl
├── biology.jl
├── metrics.jl
├── theory.jl
├── simulation.jl
├── experiments.jl
└── validation.jl
```

## Doctrines and genome

The four families are `Egoist`, `Altruist`, `Utilitarian`, and `StrictReciprocal`. Each agent contains an `EthicalGenome` with `base_cooperation`, `reciprocity`, `other_regard`, and `forgiveness`, all in [0,1]. The doctrine selects the policy family and the genome parameterizes its behavior.

## Cultural evolution

Imitation uses:

```text
P(i <- j) = 1 / (1 + exp[-beta * (fitness_j - fitness_i)])
```

Either `AsynchronousUpdate` or `SynchronousUpdate` can be used.

## Biological evolution

In `BiologicalEvolution`, selection occurs through resources: agents with energy <= `death_energy` die, and agents with energy >= `reproduction_energy` may reproduce up to `carrying_capacity`. Offspring inherit the strategy subject to mutation.

`HybridEvolution` combines cultural imitation and biological turnover.

## Memory

`memory_capacity` controls the maximum number of opponents remembered by each agent. Memory cost changes approximately from O(N²) in v0.1 to O(N * memory_capacity).

## Experiments

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

Ensemble and UQ:

```bash
julia --project=. scripts/run_ensemble.jl
julia --project=. scripts/run_uncertainty_analysis.jl
```

Invasions and ESS screening:

```bash
julia --project=. scripts/run_invasion_analysis.jl
```

Analytical validation:

```bash
julia --project=. scripts/run_theory_validation.jl
```

Benchmark:

```bash
julia --project=. scripts/benchmark_core.jl
```

## Scientific interpretation

EDEN does not identify cooperation with ethics and does not use invasion experiments as formal proof of an ESS. Results are properties of the model and its assumptions. Replicator dynamics serve as a baseline only when their assumptions are comparable with the ABM experiment.

See `docs/MODEL.md`, `docs/API.md`, and `docs/VALIDATION.md` for more detail.
