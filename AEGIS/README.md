# AEGIS

**Autonomous Engine for Graded Integrity & Survivability**

AEGIS is a dependency-free Rust engine for reliability, availability and mission-survivability studies. The v0.1.0 release provides deterministic analytical models, continuous-time Markov analysis, independent-event fault trees, reproducible Monte Carlo simulation, and portable TOML/JSON configuration without embedding any NEXUS-specific assumptions.

AEGIS is an engineering analysis tool, not a certification authority. Its numerical outputs require independent verification and validation before they can support qualification, mission assurance, or safety decisions.

## Core capabilities

AEGIS v0.1.0 implements:

- exponential lifetime models;
- Weibull lifetime models;
- component MTTF;
- repairable steady-state availability for exponential components;
- series, parallel, and k-out-of-n architectures;
- heterogeneous k-out-of-n reliability through Poisson-binomial dynamic programming;
- independent-event AND/OR fault trees;
- finite-state continuous-time Markov chains (CTMCs);
- transient CTMC probabilities by uniformization;
- CTMC steady-state iteration;
- reproducible Monte Carlo mission survival;
- Wilson 95% confidence intervals for Monte Carlo survival probability;
- TOML and JSON configuration inputs;
- machine-readable JSON analysis outputs;
- a dependency-free CLI;
- unit, integration, edge-case, and numerical regression tests;
- a standard-library Monte Carlo benchmark.

## Scope and boundaries

The standalone project is domain-agnostic. It understands components, lifetime distributions, repair rates, system architectures, state-transition generators, and probabilities. It does **not** know what a spacecraft, tactical asset, antenna, trajectory, or NEXUS project is.

Cross-project mappings must therefore remain outside AEGIS:

```text
NEXUS project output
        |
        v
explicit integration policy + adapter
        |
        v
AEGIS configuration
        |
        v
AEGIS analysis
```

This prevents domain-specific assumptions from being hidden inside the reliability engine.

## Mathematical model

### Exponential lifetime

For constant failure rate \(\lambda\),

\[
R(t)=e^{-\lambda t},
\qquad
\mathrm{MTTF}=\frac{1}{\lambda}.
\]

For a two-state repairable component with repair rate \(\mu\),

\[
A_\infty=\frac{\mu}{\lambda+\mu}.
\]

### Weibull lifetime

For shape \(k>0\) and scale \(\eta>0\),

\[
R(t)=\exp\left[-\left(\frac{t}{\eta}\right)^k\right],
\]

and

\[
\mathrm{MTTF}=\eta\,\Gamma\left(1+\frac{1}{k}\right).
\]

### System architectures

For independent series components,

\[
R_\mathrm{series}=\prod_i R_i.
\]

For independent parallel components,

\[
R_\mathrm{parallel}=1-\prod_i(1-R_i).
\]

For a heterogeneous k-out-of-n architecture, AEGIS evaluates the probability of at least \(k\) surviving components with dynamic programming rather than assuming identical component reliabilities.

### Continuous-time Markov chains

A CTMC is represented by generator matrix \(Q\), with non-negative off-diagonal transition rates and rows summing to zero. Transient probabilities are computed by uniformization using

\[
P=I+\frac{Q}{q},
\]

where \(q\) is chosen above the maximum exit rate. This yields a numerically stable Poisson-weighted series for finite state spaces.

### Monte Carlo

Each component lifetime is sampled directly from its configured distribution. System survival is evaluated with the same architecture semantics used by the analytical model. AEGIS uses a local SplitMix64 generator so identical seeds produce identical simulations across runs without global RNG state.

## Repository structure

```text
AEGIS/
├── src/
│   ├── error.rs                Public error type
│   ├── models/                 Components, systems, architectures
│   ├── reliability/            Exponential/Weibull/system models
│   ├── fault_tree/             Independent-event AND/OR trees
│   ├── markov/                 CTMC validation and solvers
│   ├── monte_carlo/            Reproducible mission simulation
│   ├── metrics/                MTTF/availability helpers
│   ├── io/                     TOML/JSON configuration and JSON reports
│   ├── lib.rs                  Public API
│   └── main.rs                 CLI
├── config/                     Example configurations
├── examples/                   Example fault-tree and Markov studies
├── tests/                      Black-box and numerical tests
├── benches/                    Dependency-free performance benchmark
├── Cargo.toml
├── Cargo.lock
├── VERSION
└── README.md
```

## Build and test

AEGIS requires stable Rust with the 2021 edition.

```bash
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo test
```

Run the benchmark:

```bash
cargo bench --bench monte_carlo
```

## CLI

Show the version:

```bash
cargo run -- version
```

Validate a configuration:

```bash
cargo run -- validate config/example.toml
cargo run -- validate config/example.json
```

Run an analytical study:

```bash
cargo run -- analyze config/example.toml
cargo run -- analyze config/example.toml --output results.json
```

Run Monte Carlo using configuration defaults:

```bash
cargo run -- monte-carlo config/example.toml
```

Override the number of runs and seed:

```bash
cargo run -- monte-carlo config/example.toml --runs 100000 --seed 1234 --output mc.json
```

The CLI writes JSON to stdout unless `--output` is provided.

## Configuration

A minimal TOML configuration is:

```toml
name = "redundant_computer"
mission_hours = 1000.0
architecture = "parallel"
monte_carlo_runs = 50000
seed = 42

[[components]]
id = "computer_a"
distribution = "exponential"
failure_rate_per_hour = 1.0e-5
repair_rate_per_hour = 1.0e-2

[[components]]
id = "computer_b"
distribution = "weibull"
shape = 1.5
scale_hours = 80000.0
```

Supported architecture values are:

- `series`;
- `parallel`;
- `k_out_of_n`, which additionally requires `minimum_operational`.

JSON accepts the same field names.

## Output contract

Analytical output uses schema identifier:

```text
aegis.analysis.v1
```

Monte Carlo output uses:

```text
aegis.monte_carlo.v1
```

These are standalone AEGIS schemas. A NEXUS adapter may wrap them in a NEXUS contract when a cross-project interface is needed.

## Reproducibility

AEGIS v0.1.0 keeps simulation randomness local to each invocation. The report records the seed, requested run count, mission duration, and analytical baseline. Re-running the same configuration with the same seed produces the same Monte Carlo survival count.

## Numerical assumptions

- Component failures are statistically independent in the v0.1.0 system-reliability and Monte Carlo models.
- Steady-state repairable availability is implemented only for exponential lifetime models.
- Weibull repair/rejuvenation processes are not inferred from an MTTF.
- Fault-tree basic events are treated as independent. Repeated event IDs, including across nested gates, are rejected because they require a dependent-event model.
- CTMC state spaces are finite and explicitly supplied by the caller.
- The uniformization solver is intended for moderate state spaces and engineering studies, not very large sparse generators.

## Roadmap

### v0.2.x

- explicit common-cause failure models;
- richer repair and maintenance policies;
- FMECA workflow;
- FDIR detection/isolation/recovery coverage;
- degradation-state models;
- parallel Monte Carlo;
- convergence diagnostics and additional confidence methods.

### v0.3.x

- uncertainty propagation;
- global sensitivity analysis;
- correlated failures;
- importance sampling for rare events;
- richer survivability and mission-phase models.

### v1.0.0

- stable public input/output schemas;
- expanded numerical validation suite;
- documented compatibility policy;
- performance baselines for supported analysis sizes.

## Limitations

AEGIS v0.1.0 is not a certified RAMS, FDIR, safety, or mission-assurance tool. It does not model every dependency between real failure modes, does not infer failure rates from operational telemetry, and does not replace domain-specific reliability data or independent engineering review.
