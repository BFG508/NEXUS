# NEXUS 🧩

**N**etwork of **E**xperimental e**X**plorations, **U**tilities & **S**ystems

NEXUS is a multi-language scientific and engineering monorepo built from independent projects that can also participate in explicit cross-domain experiments. The suite spans stellar-system generation, astrobiology, semantic change, evolutionary social dynamics, stochastic systems, tactical state, phased-array communications, orbital mechanics, reliability engineering, heterogeneous orchestration, and scientific-result visualization.

Each project owns its model, runtime, tests, version, and standalone release. Cross-project behavior is kept outside the project directories under `integration/`, where versioned contracts and adapters exchange data without copying sibling-project logic into release artifacts.

The repository is intended for model development, reproducible experimentation, numerical study, and integration research. It is not flight software, operational tactical software, historical evidence, or scientific qualification merely because a pipeline executes successfully.

## Project suite

| Project | Domain | Primary language | Current version |
|---|---|---|---:|
| **AEGIS** | Reliability, availability, fault trees, Markov analysis, and survivability | Rust | 0.1.0 |
| **ASTRA** | Procedural stellar systems, planets, geology proxies, and civilization initial conditions | Julia | 0.1.0 |
| **ATLAS** | Layered visualization and exploration of NEXUS run artifacts and telemetry | Swift | 0.1.0 |
| **BEAM** | Idealized phased-array steering and array-factor analysis | Python | 0.1.0 |
| **EDEN** | Ethical/cultural/biological agent dynamics and evolutionary-game experiments | Julia | 0.3.0 |
| **ETHOS** | Reproducible diachronic semantic and conceptual analysis of text corpora | Julia | 1.1.0 |
| **GAIA** | Exoplanet habitability and astrobiology exploration | R / Shiny | 0.1.0 |
| **HERMES** | Heterogeneous DAG orchestration, process execution, provenance, and artifacts | Go | 0.1.0 |
| **LEVI** | Lambert transfers, propagation, and orbital-mechanics studies | MATLAB | 0.1.0 |
| **SCALE** | Dice parsing, stochastic state transitions, entropy fusion, and PI compensation | Scala | 0.1.0 |
| **SPARTAN** | Tactical aerospace asset state and indexed persistence | COBOL / Python | 0.1.0 |

Each project has its own `README.md` describing implemented capabilities, native requirements, usage, tests, reproducibility, and modelling limitations.

HERMES, AEGIS, and ATLAS are now implemented at **v0.1.0**. HERMES provides reproducible heterogeneous orchestration, AEGIS provides reliability, availability, fault-tree, Markov, and Monte Carlo survivability analysis, and ATLAS provides offline validation, inspection, timeline reconstruction, artifact verification, run discovery, and a macOS SwiftUI client for HERMES run records.

## Integration architecture

NEXUS uses versioned JSON contracts at domain boundaries:

```text
                 ┌───────────────────────────────┐
                 │             ASTRA             │
                 └──────────┬───────────────┬────┘
                            │               │
                 stellar_system.v1          │
                            │               │
                            ▼               │
                          GAIA              │
                            │               │
                    habitability.v1         │
                            │               │
                            └──────┐        │
                                   ▼        │
ETHOS ── semantic_culture_profile.v1 ── policy ──► EDEN
                                                     │
                                              society_state.v1
                                                     │
                                                     ▼
                                                   SCALE
                                                     │
                                             stochastic_event.v1
                                                     │
                                                     ▼
                                                  SPARTAN
                                                     │
                                              tactical_state.v1
                                                     │
                                                     ▼
                                                   BEAM
                                                     │
                                           communication_state.v1
                                                     │
                                                     ▼
                                                    LEVI ◄──── ASTRA
```

The diagram describes interfaces, not automatic scientific equivalence. In particular, ETHOS measurements are textual/semantic observations. The ETHOS-to-EDEN bridge requires an explicit policy artifact and does **not** identify semantic shift with moral traits or causal social parameters.

The central integration layer contains:

```text
integration/
├── adapters/       Cross-runtime producers, consumers, and format translators
├── contracts/      Versioned JSON Schema interfaces
├── fixtures/       Deterministic integration fixtures
├── policies/       Explicit cross-domain scenario mappings
├── tests/          End-to-end contract tests
└── nexus_contracts.py
```

See `docs/ARCHITECTURE.md` and `integration/README.md` for the interface rules.

## ETHOS and EDEN development line

ETHOS history is preserved as:

```text
ETHOS v0.1.0  historical baseline
ETHOS v0.1.1  metadata/identity consolidation
ETHOS v0.2.0  correctness/reproducibility baseline
ETHOS v1.0.0  first stable API baseline
ETHOS v1.1.0  current NEXUS development release
```

ETHOS v1.1.0 strengthens the stable baseline with rank-safe and frequency-stable Procrustes anchors, explicit comparison pairs, cross-language guards, portable configuration roots, moving-block bootstrap, minimum valid-bootstrap thresholds, shared bootstrap embeddings across concepts, stricter metadata validation, and higher-precision/provenance exports.

EDEN history remains available as v0.1.0 and v0.2.0. The active v0.3.0 line adds true LRU opponent memory, Student-t/bootstrap ensemble uncertainty, Wilson intervals for invasion success, separate frequency and absolute invasion growth, complete-matrix ESS diagnostics, and controlled ABM-to-replicator convergence studies.

## Release isolation

NEXUS deliberately separates **project releases** from **NEXUS integration code**.

A standalone release ZIP contains only:

```text
<PROJECT>/
├── project source
├── project documentation/tests/configuration
└── LICENSE              copied from the repository-level MIT license
```

It does not contain:

```text
integration/
sibling projects
repository workflows
NEXUS-only adapters
```

`scripts/build_release_assets.py` builds the current isolated archive for each project under `_release_assets/built/PROJECT/`; only that project's current version is retained. `scripts/check_release_isolation.py` verifies that integration code has not leaked into them. Preserved historical archives live separately under `_release_assets/historical/PROJECT/`.

The canonical public history is now immutable. New GitHub releases are published append-only with `scripts/publish_github_releases.sh`, which creates an isolated synthetic tag commit containing only the selected standalone project. This keeps both the attached ZIP and GitHub's automatic **Source code (zip/tar.gz)** archives project-only.

`scripts/replace_github_releases.sh` is retained only as a safety guard and no longer deletes or recreates releases.

## Reproducibility and data policy

The repository maintains one root `.gitignore` and one root MIT `LICENSE`. Individual projects keep their own `VERSION` and `README.md`, while generated environments, results, large local datasets, release assets, and runtime state remain outside normal Git history.

Key rules:

- project releases advance independently using Semantic Versioning;
- deterministic seeds are exposed where a model is stochastic;
- large external datasets are fetched or kept under ignored local assets rather than duplicated in Git;
- historical release ZIPs are preserved as immutable local release inputs;
- integration mappings that cross scientific domains are explicit artifacts rather than hidden code assumptions;
- result provenance belongs with the model that generated the result.

## Repository structure

```text
NEXUS/
├── .github/
│   └── workflows/              Project, integration, and repository CI
├── AEGIS/
├── ASTRA/
├── ATLAS/
├── BEAM/
├── EDEN/
├── ETHOS/
├── GAIA/
├── HERMES/
├── LEVI/
├── SCALE/
├── SPARTAN/
├── integration/
│   ├── adapters/
│   ├── contracts/
│   ├── fixtures/
│   ├── policies/
│   └── tests/
├── docs/
│   ├── ARCHITECTURE.md
│   └── RELEASES.md
├── scripts/
│   ├── build_release_assets.py
│   ├── check_release_isolation.py
│   ├── publish_github_releases.sh
│   ├── replace_github_releases.sh
│   └── repo_preflight.py
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
└── README.md
```

`_release_assets/` and `_local_assets/` may exist locally but are intentionally ignored by Git.

## Usage

There is no single runtime for all NEXUS projects. Run each project with its native toolchain.

```bash
# AEGIS
(cd AEGIS && cargo test)

# ASTRA
julia --project=ASTRA ASTRA/scripts/generate_sector.jl 10 --seed 42

# ATLAS
swift test --package-path ATLAS
swift run --package-path ATLAS atlas validate ATLAS/Resources/PreviewData/run_manifest.json
swift run --package-path ATLAS atlas inspect ATLAS/Resources/PreviewData/run_manifest.json

# BEAM
python -m pytest -q BEAM/tests

# EDEN
julia --project=EDEN EDEN/scripts/run_simulation.jl

# ETHOS
julia --project=ETHOS ETHOS/scripts/run_pipeline.jl

# GAIA
Rscript -e 'setwd("GAIA"); source("scripts/process_data.R")'

# HERMES
(cd HERMES && go test ./...)
(cd HERMES && go run ./cmd/hermes validate ../integration/scenarios/hermes_v0.1_smoke.yaml)
(cd HERMES && go run ./cmd/hermes plan ../integration/scenarios/hermes_v0.1_smoke.yaml)

# SCALE
(cd SCALE && sbt test)

# SPARTAN
python SPARTAN/spartanGen.py
```

From MATLAB:

```matlab
run('LEVI/run_demo.m')
```

Run the central Python integration tests with:

```bash
python -m pytest -q integration/tests
```

HERMES v0.1.0 also has a repository-level orchestration smoke scenario that exercises SCALE → SPARTAN → BEAM, an explicit-policy AEGIS v0.1.0 reliability analysis, and LEVI-request generation:

```bash
(cd HERMES && go run ./cmd/hermes run --runs-dir /tmp/nexus-hermes --run-id smoke ../integration/scenarios/hermes_v0.1_smoke.yaml)
```

The scenario lives under `integration/`; no NEXUS-specific adapter is packaged inside the standalone HERMES release.

ATLAS v0.1.0 consumes the HERMES v0.1.0 `hermes.run_manifest.v1` record directly as a provenance/platform contract. It can validate and inspect any compatible run directory without importing NEXUS project logic:

```bash
swift run --package-path ATLAS atlas validate /path/to/hermes-run
swift run --package-path ATLAS atlas timeline /path/to/hermes-run
swift run --package-path ATLAS atlas artifacts --verify /path/to/hermes-run
```

Scientific adapters remain under `integration/`; ATLAS only interprets execution/provenance metadata and declared artifacts.

## Tests and CI

Project-specific workflows exercise the native runtime, while integration and repository workflows validate the shared boundaries:

```text
.github/workflows/
├── aegis.yml
├── astra.yml
├── atlas.yml
├── beam.yml
├── eden.yml
├── ethos.yml
├── gaia.yml
├── hermes.yml
├── levi.yml
├── scale.yml
├── spartan.yml
├── integration.yml
└── repository.yml
```

The repository preflight checks project versions, documentation structure, JSON syntax, global license/ignore policy, nested Git metadata, and release-boundary rules:

```bash
python scripts/repo_preflight.py
```

A green repository/integration workflow does not replace each project's scientific or numerical validation suite.

## Release model

The canonical release chronology, from oldest to newest, is:

```text
beam-v0.1.0
levi-v0.1.0
spartan-v0.1.0
gaia-v0.1.0
scale-v0.1.0
astra-v0.1.0
eden-v0.1.0
eden-v0.2.0
ethos-v0.1.0
ethos-v0.1.1
ethos-v0.2.0
ethos-v1.0.0
eden-v0.3.0
ethos-v1.1.0
```

Build and validate all standalone release assets with:

```bash
python scripts/build_release_assets.py all
python scripts/check_release_isolation.py
```

The 14 releases listed above are protected historical/public records and are no longer replaced. See `docs/RELEASES.md` before publishing any new release.

## Important modelling assumptions

- NEXUS is a federation of models, not one unified physical or social theory.
- A versioned contract guarantees structural compatibility, not scientific equivalence between domains.
- ETHOS semantic displacement is a distributional-text measure and is not evidence of philosophical, moral, or causal change by itself.
- EDEN doctrine/genome parameters are experimental constructs and are not empirical measurements of human ethical psychology.
- GAIA habitability metrics remain proxies whose interpretation depends on the source variables and assumptions documented by GAIA.
- BEAM currently models idealized array-factor behavior rather than a complete RF link budget or calibrated antenna system.
- SCALE stochastic outputs require an explicit downstream interpretation before they represent a domain event.
- SPARTAN is a tactical state/persistence prototype, not operational command software.
- LEVI and ASTRA model fidelity is defined by their individual assumptions and validation tests.
- ATLAS validates execution/provenance structure and artifact integrity; it does not certify the scientific correctness of upstream results.
- End-to-end compatibility tests demonstrate data-flow integrity; they do not validate all scientific assumptions simultaneously.
