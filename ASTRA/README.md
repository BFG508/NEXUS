# ASTRA 🌌

**A**strophysical **S**tochastic **T**errain **R**endering **A**rchitect

ASTRA is a Julia procedural-generation framework for building synthetic stellar systems, planetary environments, geology proxies, and speculative civilization initial conditions. It combines unit-aware physical calculations with stochastic generation and a set of NEXUS export adapters.

The project is intended for exploratory simulation and hard-science-fiction worldbuilding. Its stellar, planetary, geological, and sociological models use simplified relations and heuristics where identified; ASTRA is not a stellar-population synthesis code, a climate model, or a validated astrobiology model.

## Core capabilities

### Stellar generation

ASTRA generates main-sequence stars with linked mass, luminosity, radius, and effective temperature. The current implementation uses piecewise mass-luminosity scaling relations and the Stefan-Boltzmann relation to keep generated properties internally connected.

The generated temperature is mapped to the Morgan-Keenan O/B/A/F/G/K/M sequence. Stellar masses are drawn from a truncated log-normal procedural distribution concentrated toward lower masses. That distribution is deliberately a generation proxy and is not presented as a Salpeter, Kroupa, or Chabrier initial mass function.

Physical quantities use `Unitful.jl` so dimensional information is carried through the core calculations.

### Planetary systems and thermodynamics

`src/planets.jl` provides synthetic rocky-planet generation with:

- mass-radius scaling;
- semi-major axis and eccentricity generation;
- simple habitable-zone boundaries based on stellar luminosity;
- equilibrium-temperature estimation;
- stochastic greenhouse-heating increments;
- a simplified tidal-locking heuristic;
- sorted multi-planet system construction.

The habitable-zone and surface-temperature calculations are intentionally compact exploratory approximations rather than a coupled radiative-convective climate solution.

### Geology and atmosphere proxies

`src/geology.jl` derives surface gravity from generated mass/radius and assigns heuristic geological/atmospheric states. Current outputs include tectonic activity, atmospheric category, and resource-richness labels.

These classifications are procedural inference rules. They should not be interpreted as geophysical or atmospheric retrievals.

### Civilization inference

`src/culture_generator.jl` maps generated planetary boundary conditions into speculative civilization attributes used by ASTRA's narrative/system-generation layer and selected NEXUS adapters.

The cultural layer is a synthetic inference engine, not an empirical sociology model.

### Sector generation and visualization

`scripts/generate_sector.jl` is the command-line entry point for deterministic seeded sector generation. `notebooks/01_orbital_mechanics.jl` provides an interactive visualization/demo path, while `src/ui_render.jl` contains text rendering helpers.

## NEXUS integration

ASTRA currently acts as a producer for several compatibility adapters:

- **GAIA:** exports generated planets to `GAIA/data/raw/astra_payload.csv` for GAIA's ETL pipeline. Missing observational fields, such as catalog distance, are left unavailable rather than synthesized.
- **SCALE:** exports civilization-derived numeric attributes to `SCALE/data/astra_entities.json`; only values that SCALE v0.1.0 can interpret as rollable numeric attributes are emitted.
- **SPARTAN:** queues advanced generated civilizations as fixed-width aerospace asset records in `SPARTAN/spartan_import.txt` for explicit import into the SPARTAN indexed database.
- **LEVI:** exports planetary orbital elements to `LEVI/integrations/astra_orbits.csv` for MATLAB transfer studies.

Run the export path with:

```bash
julia --project=. scripts/generate_sector.jl 10 --seed 42 --export
```

These adapters are compatibility interfaces, not a stable NEXUS cross-project API.

## Reproducibility

Sector generation accepts an explicit seed. For a fixed code/environment state and seed, the command-line generator is intended to produce deterministic stochastic choices.

Example:

```bash
julia --project=. scripts/generate_sector.jl 10 --seed 42
```

Dependency versions are managed through Julia's project environment. For release or campaign reproducibility, record the Julia version, project state, seed, and Git commit/tag used.

## Julia requirements

ASTRA targets Julia 1.10+ and uses the project environment declared by `Project.toml`.

Restore dependencies with:

```bash
cd ASTRA
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Core dependencies include `Unitful.jl`, `Distributions.jl`, `DataFrames.jl`, and `Plots.jl`.

## Repository structure

```text
ASTRA/
├── notebooks/
│   └── 01_orbital_mechanics.jl   Interactive exploration/demo
├── scripts/
│   └── generate_sector.jl        Seeded sector-generation entry point
├── src/
│   ├── integrations/             NEXUS compatibility exporters
│   ├── astra.jl                  Main module/public surface
│   ├── stars.jl                  Stellar generation/classification
│   ├── planets.jl                Planetary generation/thermodynamics
│   ├── geology.jl                Geology/atmosphere proxies
│   ├── culture_generator.jl      Civilization inference
│   └── ui_render.jl              Text presentation helpers
├── test/
│   └── runtests.jl               Julia smoke/regression tests
├── Project.toml
├── VERSION
└── README.md
```

## Usage

Generate ten systems:

```bash
cd ASTRA
julia --project=. scripts/generate_sector.jl 10 --seed 42
```

Generate and export NEXUS compatibility payloads:

```bash
julia --project=. scripts/generate_sector.jl 10 --seed 42 --export
```

Explore the visualization/demo script with:

```bash
julia --project=. notebooks/01_orbital_mechanics.jl
```

## Tests and CI

Run the Julia test suite with:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

`.github/workflows/astra.yml` restores the Julia environment and runs the package tests on a clean Ubuntu runner.

## Important modeling assumptions

- The stellar-mass generator is a truncated log-normal procedural proxy, not a measured Galactic IMF model.
- Habitable-zone boundaries use a simple luminosity square-root scaling.
- Planetary greenhouse heating, tidal locking, geology, atmosphere, and resource states use simplified heuristic models.
- Civilization attributes are speculative generated state, not empirical sociological predictions.
- Cross-project exporters map ASTRA state into the current consumer format and are not yet stable versioned interfaces.
- ASTRA is an exploratory simulation/worldbuilding framework, not an astrophysical or astrobiological qualification tool.
