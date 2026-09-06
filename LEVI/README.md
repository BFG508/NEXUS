# LEVI 🛰️

**L**ambert & **E**phemeris-based **V**elocity **I**ntegrator

LEVI is a MATLAB orbital-mechanics suite for exploring Lambert boundary-value solutions, transfer timing, two-body propagation, and selected zonal-perturbation studies. Multiple solver implementations are kept together so transfer solutions can be compared within one engineering sandbox.

The project is intended for algorithm study, numerical comparison, and NEXUS trajectory experiments. It is not a mission-design/flight-dynamics qualification library, and current cross-project scripts use simplified assumptions where a full mission or navigation model would require additional geometry, uncertainty, ephemerides, and operational constraints.

## Core capabilities

### Lambert solver suite

`func/` contains multiple Lambert solution paths:

- `lambertUniVar.m` — universal-variable formulation;
- `lambertGauss.m` — Gauss formulation;
- `lambertb.m` with `kbatt.m` / `seebatt.m` — Battin implementation and helpers;
- `lambhodograph.m` — hodograph-based solution;
- `lambertmin.m` — minimum-energy transfer reference.

The suite is designed for comparative study; agreement between algorithms should be checked for the specific geometry/time-of-flight regime being analyzed.

### Transfer timing and ΔV optimization

`optimizationSimplex.m` and `costDeltaV.m` provide a custom simplex-based search over transfer timing/cost. `computeTBI.m` supports time-bound calculations used in multi-revolution studies.

### Two-body propagation

`kepler.m` provides scriptable two-body propagation. `run_demo.m` supplies a minimal command-line-compatible demonstration independent of the Live Script.

### Zonal perturbation exploration

`zonalEquationMotion.m` supports numerical propagation with Earth zonal-harmonic terms used by the project to explore J2/J3 effects against a two-body reference.

### Live engineering demonstration

`LEVI.mlx` is the richer interactive demonstration containing multi-solver comparisons, optimization cases, and plotting. It is retained as a presentation/analysis layer rather than the only executable entry point.

## NEXUS integration

LEVI contains compatibility adapters under `integrations/`:

### ASTRA transfer analysis

```matlab
run('integrations/astra_transfer.m')
```

Consumes ASTRA-generated planetary orbital elements and constructs approximate transfer geometry for Lambert studies.

### SPARTAN ΔV screening

```matlab
run('integrations/spartan_dv_check.m')
```

Reads a SPARTAN fleet snapshot and compares asset budgets with simplified transfer requirements.

### BEAM communication window

```matlab
run('integrations/beam_comm_window.m')
```

Combines propagated geometry with an idealized BEAM beamwidth assumption to identify candidate communication windows.

### GAIA mission-planning proxy

```matlab
run('integrations/gaia_mission_planner.m')
```

Uses GAIA exoplanet data to construct simplified interstellar mission metrics. This is an exploratory proxy rather than a physically complete interstellar mission design.

### SCALE-style trajectory-risk proxy

```matlab
run('integrations/scale_trajectory_risk.m')
```

Runs a local stochastic trajectory-risk calculation inspired by SCALE-style events. It does **not** execute the Scala SCALE engine.

Integration scripts resolve paths from their own location so execution does not depend on the caller's current working directory.

## Reproducibility

Use the scriptable `run_demo.m` and MATLAB tests for clean-start regression rather than relying only on the execution state embedded in `LEVI.mlx`.

Cross-project analyses should preserve the producer input file, MATLAB release, numerical parameters, and Git commit/tag used. Stochastic compatibility scripts should record their configured seed when applicable.

## MATLAB requirements

The core project is MATLAB code and uses standard numerical functions including ODE integration. No external toolbox is intentionally required for the basic two-body/Lambert core documented here.

A reasonably recent MATLAB release is recommended. GitHub Actions provides the clean-environment MATLAB check for the repository project line.

## Repository structure

```text
LEVI/
├── func/
│   ├── computeTBI.m               Multi-revolution timing helper
│   ├── costDeltaV.m               Optimization cost
│   ├── findc2c3.m                 Stumpff functions
│   ├── kepler.m                   Two-body propagation
│   ├── lambertGauss.m             Gauss Lambert solver
│   ├── lambertUniVar.m            Universal-variable Lambert solver
│   ├── lambertb.m                 Battin Lambert solver
│   ├── lambertmin.m               Minimum-energy transfer
│   ├── lambhodograph.m            Hodograph solver
│   ├── optimizationSimplex.m      Timing/ΔV optimization
│   └── zonalEquationMotion.m      Zonal-perturbation ODE
├── integrations/                  NEXUS compatibility scripts
├── tests/
│   └── test_smoke.m               MATLAB smoke tests
├── LEVI.mlx                       Interactive Live Script
├── run_demo.m                     Scriptable demonstration
├── VERSION
└── README.md
```

## Usage

From MATLAB, execute the reproducible demonstration:

```matlab
run('LEVI/run_demo.m')
```

For interactive analysis, open:

```text
LEVI.mlx
```

Individual integration adapters may be run after their producer project has generated the required input artifact.

## Tests and CI

Run the MATLAB tests from the repository root with:

```matlab
addpath('LEVI/func');
results = runtests('LEVI/tests');
assertSuccess(results);
```

`.github/workflows/levi.yml` uses MATLAB Actions to execute the test suite on a clean runner.

## Important modeling assumptions

- The Lambert implementations solve idealized boundary-value problems and must be checked for the intended geometry/time-of-flight branch.
- `run_demo.m` uses a two-body Earth reference and is a smoke demonstration, not an orbit-determination scenario.
- J2/J3 studies are limited to the force model implemented in `zonalEquationMotion.m`.
- NEXUS adapters use simplified mission, communication, or risk assumptions and are not replacements for high-fidelity ephemeris/mission analysis.
- The SCALE-style integration is a local proxy and does not invoke SCALE itself.
- LEVI is an engineering study suite, not flight-certified GNC/FDS software.
