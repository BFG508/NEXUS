# EDEN.jl

**Evolutionary Dynamics of Ethical Networks**

Agent-based simulator for studying the emergence and evolutionary stability of cooperative behaviors under game theory, selection, mutation, memory, and optional spatial structure.

## Scientific scope

EDEN does not assume that cooperation, ethics, and humanism are equivalent concepts. The simulator operationalizes observable behaviors and makes it possible to study under which conditions particular policies of cooperation, reciprocity, or welfare maximization are competitive or evolutionarily stable.

The project explicitly separates:

- **game**: determines payoffs;
- **strategy**: determines actions;
- **fitness**: summarizes relative success;
- **evolution**: determines imitation and mutation;
- **energy**: represents biological resources and is not automatically identified with utility;
- **space**: may be absent or locally constrain interactions.

## Stack

- Julia 1.10+;
- Agents.jl 7.x;
- DataFrames.jl;
- CSV.jl;
- GLMakie for the interactive interface;
- CairoMakie for static figures.

`InteractiveDynamics.jl` is not used: modern visualization and interactivity are provided through the Makie integration in Agents.jl.

## Installation

Installing Julia through `juliaup` is recommended.

```bash
julia --project=. scripts/bootstrap.jl
```

This command resolves dependencies, creates `Manifest.toml` locally, and precompiles the environment. The repository does not pin a `Manifest.toml` because it is organized as a reusable Julia package; `Project.toml` defines the main compatibility constraints.

To run the tests:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Structure

```text
EDEN/
├── Project.toml
├── README.md
├── CONTRIBUTING.md
├── notebooks/
│   └── 01_game_theory_math.jl
├── src/
│   ├── EDEN.jl
│   ├── agents.jl
│   ├── games.jl
│   ├── strategies.jl
│   ├── evolution.jl
│   ├── environment.jl
│   ├── metrics.jl
│   ├── theory.jl
│   └── simulation.jl
├── scripts/
│   ├── bootstrap.jl
│   ├── run_simulation.jl
│   ├── run_ensemble.jl
│   ├── run_parameter_sweep.jl
│   ├── run_interactive.jl
│   └── plot_results.jl
├── test/
│   ├── runtests.jl
│   ├── test_games.jl
│   ├── test_strategies.jl
│   ├── test_theory.jl
│   └── test_simulation.jl
└── results/
```

## Game model

The base game is a symmetric Prisoner's Dilemma with:

\[
T > R > P > S
\]

The default values are:

\[
(T,R,P,S)=(5,3,1,0).
\]

The row player's payoff matrix, ordered as Cooperate/Defect, is:

\[
A =
\begin{bmatrix}
R & S \\
T & P
\end{bmatrix}.
\]

## Implemented doctrines

### Egoist

Uses a low cooperation probability. The initial value is 0.02 and mutation remains within the interval [0, 0.25].

### Altruist

Uses a high cooperation probability. The initial value is 0.98 and mutation remains within [0.75, 1].

### Utilitarian

Compares the expected aggregate welfare of cooperating and defecting, conditioned on an estimate of the opponent's behavior. `cooperation_probability` represents the confidence with which the utilitarian recommendation is followed.

### StrictReciprocal

Cooperates on a first interaction and then attempts to repeat the last action observed for that opponent. The `doctrine_tag` field identifies the doctrine. Memory is specific to each agent identifier and is stored in a preallocated vector.

## Interaction and fitness

Each generation performs approximately:

\[
N_{int}=\left\lceil\frac{N\,k}{2}\right\rceil
\]

interactions, where `N` is the population and `k` is `interactions_per_agent`.

Individual fitness is calculated as the mean payoff for that generation:

\[
f_i = \frac{1}{n_i}\sum_j \pi_{ij}.
\]

## Evolution

A Fermi imitation rule is used:

\[
P(i\leftarrow j)=\frac{1}{1+\exp[-\beta(f_j-f_i)]}.
\]

`selection_intensity = β` controls selection pressure. After each comparison, mutation may occur with probability `mutation_rate`.

The population is fixed: agents are neither created nor destroyed during a simulation. Evolution occurs through strategy changes, not through changes in population size.

## Energy

Energy is separated from payoff. After an interaction:

\[
\Delta E_i = k_E\pi_i - C_m,
\]

with `payoff_to_energy = k_E` and `metabolic_cost = C_m`.

Energy is lower-bounded at zero. It currently does not control mortality or reproduction; it is recorded as an additional biological variable.

## Spatial modes

### Well-mixed

This is the default mode and the recommended mode for initial scientific validation. There is no explicit space and every agent may interact with any other agent.

### GridSpace

With `spatial=true`, agents live on a periodic two-dimensional grid. Interactions and model-agent selection for imitation are restricted to `neighborhood_radius`; if `move_agents=true`, agents perform a random walk before each generation. Evolutionary updating is asynchronous and uses a randomized activation order in each generation.

## Analytical baseline

The project includes replicator dynamics for arbitrary matrices:

\[
\dot{x}_i=x_i\left[(A\mathbf{x})_i-\mathbf{x}^{T}A\mathbf{x}\right].
\]

It is used as a mathematical reference, especially for the simplified Cooperate/Defect case. Doctrines with memory generally cannot be reduced to a static two-strategy matrix.

Example:

```bash
julia --project=. notebooks/01_game_theory_math.jl
```

## Run a simulation

```bash
julia --project=. scripts/run_simulation.jl
```

Optionally:

```bash
julia --project=. scripts/run_simulation.jl GENERATIONS POPULATION SEED
```

Example:

```bash
julia --project=. scripts/run_simulation.jl 2000 1000 42
```

The CSV is saved in `results/`.

## Seed ensemble

```bash
julia --project=. scripts/run_ensemble.jl
```

Runs multiple independent replicates to avoid drawing inferences from a single stochastic realization.

## Parameter sweep

```bash
julia --project=. scripts/run_parameter_sweep.jl
```

Explores combinations of selection intensity and mutation rate across multiple seeds.

## Static visualization

After generating a CSV:

```bash
julia --project=. scripts/plot_results.jl results/simulation_seed_42.csv
```

Generates a PNG figure with doctrine frequencies and realized cooperation.

## Interactive visualization

```bash
julia --project=. scripts/run_interactive.jl
```

Opens a spatial simulation with Agents.jl + GLMakie controls.

## Metrics

Each generation records:

- Egoist fraction;
- Altruist fraction;
- Utilitarian fraction;
- StrictReciprocal fraction;
- realized cooperation rate;
- mean fitness;
- mean energy;
- energy Gini coefficient;
- Shannon diversity of strategies;
- mean cooperation parameter;
- number of interactions performed.

## Reproducibility

The model RNG is created with `MersenneTwister(seed)`, and all internal random decisions use the RNG owned by `Agents.jl` through `abmrng(model)` or `Agents.jl` functions that consume that RNG.

CI runs the suite on Julia 1.10 and 1.12.

## Current limitations

- Reciprocity uses the last action observed per opponent, not a complete history of arbitrary length.
- Utilitarianism is local to a two-agent interaction; it does not have perfect global information about the entire population.
- Energy does not yet cause death or reproduction.
- Replicator dynamics are only a direct baseline for strategies representable by a fixed payoff matrix.
- A cooperative outcome is not, by itself, a normative demonstration of an ethical theory.

## Natural next extensions

- configurable memory depth;
- public and private reputation;
- explicit social graphs;
- birth-death and Moran selection;
- energy-linked reproduction;
- continuous coevolution of ethical parameters;
- controlled invasions to estimate evolutionary stability;
- sensitivity analysis and uncertainty quantification.
