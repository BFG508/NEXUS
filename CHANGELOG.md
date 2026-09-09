# Changelog

All notable changes to HERMES are documented in this file.

## [0.1.0] - 2026-09-09

### Added

- Versioned HERMES Scenario v1 format with a deliberately small, documented YAML subset and JSON support.
- Scenario validation, dependency checking, deterministic topological planning, and cycle detection.
- Sequential dependency-aware execution of heterogeneous external processes.
- Per-step timeouts, explicit environment overrides, failure propagation, and blocked-step reporting.
- Runtime variable expansion for run, scenario, seed, and per-step artifact paths.
- Structured run directories with stdout/stderr logs, JSONL telemetry, declared artifacts, and SHA-256 checksums.
- Reproducibility metadata including scenario hash, effective seed, deterministic run fingerprint, HERMES version, Go runtime, host platform, and Git provenance when available.
- `validate`, `plan`, `run`, `inspect`, and `version` CLI commands.
- Standard-library-only Go implementation with unit and end-to-end tests.
- NEXUS-level smoke scenario orchestrating the SCALE → SPARTAN → BEAM → LEVI-request adapter chain without embedding NEXUS logic in HERMES itself.

### Boundaries

- HERMES v0.1.0 is a local-process orchestrator. Distributed execution, resumable runs, concurrent branch scheduling, sandboxing, network APIs, and live streaming are intentionally deferred.

### Fixed before release

- Preparation failures record complete attempt timing and step lifecycle telemetry without assigning a process exit code, so ATLAS can validate failed runs.
