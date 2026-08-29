# G.A.I.A. 🌌

**G**alactic **A**strobiology & **I**nteractive **A**nalysis

GAIA is an exploratory R/Shiny framework for processing exoplanet catalog data, computing habitability/biology/chemistry proxies, and presenting the resulting state through an interactive dashboard. Scientific calculations are separated into modular R files while the Shiny application provides the visualization and interaction layer.

The project is intended for astrobiology exploration and software experimentation. Several outputs are deliberately simplified proxies: GAIA does not claim that its ESI-inspired metric, extremophile classes, simulated atmospheres, biosignature flags, or Drake-equation scenarios are observational detections or validated predictions of life.

## Core capabilities

### Exoplanet ETL pipeline

`scripts/process_data.R` normalizes the repository sample or a downloaded NASA Exoplanet Archive payload into the fields required by the model layer. Missing observational fields remain `NA` rather than being silently synthesized.

`scripts/fetch_data.R` can download the current compact source-column subset used by the project. The large local source CSV is intentionally excluded from Git.

### Earth-similarity proxy

`R/astrobiology_models.R` computes an ESI-inspired score from radius, inferred density, escape velocity, and equilibrium temperature. Because the input field is equilibrium temperature, the Earth reference used by the current implementation is 255 K rather than a 288 K surface-temperature reference.

The returned `esi_global` is a modelling proxy for comparative exploration, not an observational habitability probability.

### Extremophile viability classification

`R/biology_models.R` compares equilibrium temperature against the project's extremophile-limit table and assigns a thermal biosphere class such as psychrophile, mesophile, thermophile, or hyperthermophile.

The classification uses temperature bounds and does not model pressure, solvent chemistry, radiation, geochemical energy sources, atmospheric retention, or evolutionary accessibility.

### Atmospheric and biosignature proxies

`R/chemistry_models.R` generates a hypothetical atmospheric gas set from the current biosphere class/ESI state and checks selected gas pairs against a small biosignature dictionary.

These atmospheres are simulated scenario state. A positive flag is not an observed atmosphere or confirmed biosignature.

### Drake-equation exploration

`R/drake_equation.R` provides an interactive multiplicative Drake-equation estimate for the dashboard. User-adjustable fractions are scenario inputs rather than measured certainty.

### Interactive Shiny dashboard

`app/` exposes the processed catalog and model outputs through Shiny, Plotly, and DT. The UI is the exploration layer; scientific functions remain callable independently from the application.

## NEXUS integration

GAIA remains a standalone R/Shiny analysis project. Repository-level adapters under `../integration/` translate `nexus.stellar_system.v1` into the documented GAIA ETL columns and export GAIA habitability calculations as `nexus.habitability.v1`.

No integration code is shipped in the GAIA release. Cross-project transformations live at the monorepo boundary and must not silently change GAIA's scientific definitions.

## Reproducibility and data policy

The repository tracks:

- a small NASA-derived raw sample;
- biological/biosignature lookup tables;
- a processed fixture suitable for tests and dashboard startup;
- `renv.lock` for package restoration.

The full downloaded NASA source file is a local asset and is ignored by Git.

Restore the package environment with:

```r
renv::restore()
```

Then process either the repository sample or a newly downloaded payload. Record the source dataset/query date, `renv.lock`, and Git commit/tag for a reproducible analysis campaign.

## R requirements

GAIA CI uses R 4.3.3. A compatible R 4.3.x environment is the current target.

The environment is managed with `renv`; principal application/data packages include Shiny, dplyr/readr/tidyr, Plotly, DT, and testthat.

## Repository structure

```text
GAIA/
├── app/
│   ├── global.R                   Shared application state/models
│   ├── server.R                   Shiny server logic
│   └── ui.R                       Shiny UI
├── R/
│   ├── astrobiology_models.R      ESI-inspired calculations
│   ├── biology_models.R           Thermal viability classes
│   ├── chemistry_models.R         Atmosphere/biosignature proxies
│   └── drake_equation.R           Drake-equation model
├── data/
│   ├── raw/                       Small source fixtures/lookups
│   └── processed/                 Processed test/dashboard fixture
├── scripts/
│   ├── fetch_data.R               NASA source downloader
│   └── process_data.R             ETL pipeline
├── tests/
│   ├── testthat.R
│   └── testthat/test-models.R
├── renv.lock
├── VERSION
└── README.md
```

## Usage

From the GAIA directory:

```r
renv::restore()
```

Optionally download the current compact NASA payload:

```r
source("scripts/fetch_data.R")
```

Process data:

```r
source("scripts/process_data.R")
```

Without the download step, the repository sample is used.

Run tests:

```r
source("tests/testthat.R")
```

Launch the application:

```r
shiny::runApp("app")
```

## Tests and CI

The `testthat` suite exercises the model functions and representative edge behavior. `.github/workflows/gaia.yml`:

- sets up R 4.3.3;
- restores the `renv` environment;
- runs the ETL pipeline on the repository fixture;
- executes `tests/testthat.R`.

A successful fixture/CI run verifies software behavior for the tested cases; it does not validate the underlying astrobiological hypotheses.

## Important modeling assumptions

- The ESI-inspired calculation uses equilibrium temperature consistently with an Earth equilibrium-temperature reference of 255 K.
- Thermal viability is based on a compact extremophile-temperature table and does not represent a full biological survivability model.
- Simulated atmospheres are heuristic scenario outputs, not spectroscopic retrievals.
- Biosignature detection operates on simulated gas co-occurrence and therefore is not evidence of biological activity.
- Drake-equation parameters are user/scenario assumptions with large epistemic uncertainty.
- Missing catalog values remain missing; downstream consumers should not silently synthesize observational quantities.
- GAIA is an exploratory astrobiology/data-visualization prototype, not an observational pipeline or life-detection instrument model.
