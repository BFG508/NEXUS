# NEXUS 🧩

**N**etwork of **E**xperimental e**X**plorations, **U**tilities & **S**ystems

NEXUS is a multi-language engineering and scientific sandbox composed of independently executable projects that explore astrophysics, astrobiology, evolutionary dynamics, stochastic systems, tactical state management, electromagnetic arrays, and orbital mechanics. Each project owns its domain logic, version, tests, and release line while remaining able to exchange data through explicit compatibility adapters.

The repository is intended for experimental modelling, algorithm development, reproducible demonstrations, and cross-domain integration studies. The individual models are prototypes with different fidelity levels; NEXUS does not treat a successful run or a visually plausible result as scientific validation, operational qualification, or production readiness.

## Project suite

| Project | Domain | Primary language | Current version |
|---|---|---|---:|
| **ASTRA** | Procedural stellar systems, planets, geology, and civilization initial conditions | Julia | 0.1.0 |
| **BEAM** | Idealized dipole/phased-array modelling and electronic steering | Python | 0.1.0 |
| **EDEN** | Ethical, cultural, biological, and evolutionary agent dynamics | Julia | 0.2.0 |
| **GAIA** | Exoplanet habitability and astrobiology exploration | R / Shiny | 0.1.0 |
| **LEVI** | Lambert transfers, propagation, and orbital-mechanics studies | MATLAB | 0.1.0 |
| **SCALE** | Dice parsing, stochastic state transitions, entropy fusion, and PI compensation | Scala | 0.1.0 |
| **SPARTAN** | Tactical aerospace asset state, fixed-width interchange, and indexed persistence | COBOL / Python | 0.1.0 |

Each project has its own `README.md` with model scope, local requirements, usage, tests, integration behavior, and limitations.

## NEXUS architecture

NEXUS keeps domain ownership explicit:

```text
ASTRA    stellar systems, planets and civilization initial conditions
GAIA     planetary environment, habitability and astrobiology proxies
EDEN     social, ethical and evolutionary dynamics
SCALE    stochastic events and probabilistic state transitions
SPARTAN  tactical assets and persistent operational state
BEAM     antenna arrays, steering and interference studies
LEVI     orbital mechanics, transfers and trajectory analysis
```

A project must remain executable without importing another project's source tree. Cross-project scripts under `integrations/` are compatibility adapters: they exchange files or reproduce a deliberately limited local proxy where a common interface does not yet exist. Shared versioned schemas will be introduced only when the corresponding integrations are formally defined; the repository does not currently claim a stable cross-project API.

See `docs/ARCHITECTURE.md` for the architecture baseline.

## Cross-project integration

Current integration paths include:

```text
ASTRA -> GAIA
ASTRA -> SCALE
ASTRA -> SPARTAN
ASTRA -> LEVI

GAIA  -> SPARTAN
GAIA  -> SCALE-like compatibility proxy

SCALE -> SPARTAN
SCALE -> BEAM

SPARTAN -> BEAM
SPARTAN -> LEVI

BEAM -> LEVI
GAIA -> LEVI
ASTRA -> LEVI
```

These paths do not all have the same maturity. Some consume another project's exported artifact directly, while others remain compatibility proxies. Individual project READMEs identify those distinctions explicitly.

EDEN v0.2.0 remains independently executable and is not yet wired into the full NEXUS data flow. Its future integration work belongs to a later EDEN release rather than being implied by the current repository structure.

## Reproducibility and data policy

NEXUS keeps source and reproducible fixtures in Git while excluding generated or machine-local artifacts. The repository-level `.gitignore` covers language environments, build products, generated results, large downloaded datasets, local release assets, and runtime state.

Important repository rules:

- one root `.gitignore` is authoritative for the monorepo;
- one root MIT `LICENSE` covers the repository projects;
- each project keeps its own `VERSION` and `README.md`;
- large source datasets are downloaded locally when required instead of committed by default;
- release ZIPs are generated under `_release_assets/` and are not committed to normal repository history;
- `_local_assets/` is reserved for local source material that must remain available without being tracked;
- deterministic seeds are used where the underlying project exposes stochastic generation or Monte Carlo execution.

Historical EDEN v0.1.0 and v0.2.0 release trees are preserved locally as English language-only editions. Their code, versions, parameters, APIs, and behavior remain unchanged relative to those historical snapshots.

## Repository structure

```text
NEXUS/
├── .github/
│   └── workflows/              Project-specific and repository CI
├── ASTRA/                      Julia stellar/system generator
├── BEAM/                       Python phased-array model
├── EDEN/                       Julia evolutionary-dynamics simulator
├── GAIA/                       R/Shiny astrobiology explorer
├── LEVI/                       MATLAB orbital-mechanics suite
├── SCALE/                      Scala stochastic/dice engine
├── SPARTAN/                    COBOL/Python tactical database prototype
├── docs/
│   ├── ARCHITECTURE.md         Architecture baseline
│   └── RELEASES.md             Versioning and release procedure
├── scripts/
│   ├── build_release_assets.py Standalone release packaging
│   └── repo_preflight.py       Dependency-free repository checks
├── CONTRIBUTING.md
├── LICENSE                     MIT License
├── .gitignore                  Monorepo ignore policy
└── README.md
```

`_release_assets/` and `_local_assets/` may exist in a local working copy but are intentionally ignored by Git.

## Usage

There is no single runtime that executes all NEXUS projects. Run each project from its own directory with its native toolchain.

Examples:

```bash
# ASTRA
julia --project=ASTRA ASTRA/scripts/generate_sector.jl 10 --seed 42

# BEAM
python -m pytest -q BEAM/tests

# EDEN
julia --project=EDEN EDEN/scripts/run_simulation.jl

# GAIA
Rscript -e 'setwd("GAIA"); source("scripts/process_data.R")'

# SCALE
cd SCALE && sbt run

# SPARTAN bootstrap
python SPARTAN/spartanGen.py
```

From MATLAB, LEVI can be exercised with:

```matlab
run('LEVI/run_demo.m')
```

Refer to the individual project README before running an integration adapter because some adapters require a producer-generated input file or an explicitly refreshed SPARTAN snapshot.

## Tests and CI

The repository contains independent GitHub Actions workflows for the seven projects plus a repository structural preflight:

```text
.github/workflows/
├── repository.yml
├── astra.yml
├── beam.yml
├── eden.yml
├── gaia.yml
├── levi.yml
├── scale.yml
└── spartan.yml
```

The workflows exercise the native runtime where practical:

- ASTRA and EDEN: Julia package tests;
- BEAM: `pytest`;
- GAIA: `renv` restore, ETL fixture processing, and `testthat`;
- LEVI: MATLAB smoke/unit tests;
- SCALE: ScalaTest plus the Python BEAM-jamming adapter test;
- SPARTAN: Python tests plus GnuCOBOL compilation;
- repository: version, Markdown, JSON, license, ignore-policy, and nested-repository checks.

Run the repository preflight locally with:

```bash
python scripts/repo_preflight.py
```

A green repository preflight does not replace the native project workflow.

## Release model

Projects use Semantic Versioning independently. Git tags are prefixed with the project name, for example:

```text
astra-v0.1.0
beam-v0.1.0
eden-v0.1.0
eden-v0.2.0
gaia-v0.1.0
levi-v0.1.0
scale-v0.1.0
spartan-v0.1.0
```

A `v1.0.0` project release is reserved for a public behavior/interface intentionally considered stable. Standalone ZIPs are built with `scripts/build_release_assets.py`; the global MIT license is copied into each generated project archive.

See `docs/RELEASES.md` for the complete release procedure.

## Important integration assumptions

- NEXUS is a monorepo, not a single executable application.
- Project versions advance independently; a release in one project does not imply a repository-wide version change.
- Current `integrations/` scripts are not a stable public protocol and may change when versioned interchange schemas are introduced.
- Compatibility proxies that reproduce sibling-like behavior are identified as such and should not be interpreted as execution of the sibling project itself.
- Scientific and engineering fidelity is project-specific. Read each project's modelling assumptions before using outputs for analysis.
- The repository is an experimental/prototyping environment, not flight software, operational tactical software, or scientific qualification evidence.
