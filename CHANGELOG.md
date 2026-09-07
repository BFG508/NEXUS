# Changelog

## v0.3.0 — NEXUS Integration & Inference Release

- Replaced insertion/FIFO-like bounded opponent memory with true least-recently-used behavior.
- Added Student-t and bootstrap confidence intervals for ensemble means.
- Added Wilson intervals for invasion frequency-growth probability.
- Added initial/final invader counts plus separate frequency and absolute growth metrics while retaining `grew` as the frequency-growth compatibility field.
- Strengthened empirical ESS diagnostics with complete resident×invader coverage checks and confidence-bound-aware classification.
- Added controlled ABM-to-replicator convergence studies over population size and selection intensity.
- Added a generic TOML-driven runner for reproducible externally configured scenarios.
- Added repository-level NEXUS contracts/adapters without placing integration code inside the standalone EDEN release.
- Updated model, validation, tests, and presentation for v0.3.0.

## v0.2.0 — Research Prototype

- Added a continuous ethical genome separated from the doctrine tag.
- Replaced O(N²) memory with configurable bounded per-agent memory.
- Added cultural, biological, and hybrid evolution modes.
- Added energy-dependent mortality and reproduction, inheritance, and mutation.
- Added synchronous and asynchronous evolutionary updates.
- Added controlled invasion experiments and an invasibility matrix.
- Added empirical ESS candidates without presenting them as formal ESS proof.
- Added ensembles with standard deviation and 95% confidence intervals.
- Added directional ABM validation against replicator dynamics in the pure binary case.
- Expanded population, birth, death, age, and genome-trait metrics.
- Added biological, spatial, uncertainty, invasion, validation, and benchmark scripts.
- Expanded the test suite and CI.
- Added LICENSE and technical documentation.

## v0.1.0 — Stable Prototype

First functional EDEN core with Prisoner's Dilemma, four doctrines, Fermi cultural evolution, per-opponent memory, energy as a metric, well-mixed mode, GridSpace, ensembles, replicator theory, and Makie visualization.
