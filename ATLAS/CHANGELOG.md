# Changelog

All notable changes to ATLAS are documented here.

## [0.1.0] - 2026-09-11

### Added
- Portable `ATLASCore` package for offline inspection of HERMES run manifests.
- Strict support for the `hermes.run_manifest.v1` schema.
- Run and step validation, including dependency and lifecycle consistency checks.
- Deterministic timeline construction from run and step timestamps.
- JSONL telemetry loading with run-ID consistency validation.
- Artifact discovery, relocation-aware path resolution, size checks and SHA-256 verification.
- Run discovery for directories containing multiple HERMES executions.
- Command-line interface with `version`, `validate`, `inspect`, `timeline`, `artifacts` and `discover` commands.
- macOS SwiftUI application target with run loading, overview, timeline and artifact views.
- Unit tests for contracts, validation, timeline ordering, discovery, telemetry and artifact verification.
- Preview HERMES v0.1.0 manifest and telemetry fixtures.

### Boundaries
- ATLAS consumes result/provenance contracts and does not implement scientific models.
- NEXUS-specific scientific adapters remain outside ATLAS under the repository-level `integration/` tree.

### Fixed before release

- Duplicate step names produce validation errors without crashing cycle detection; duplicate dependency edges remain checked for cycles.
- Linux CI builds and tests the portable core/CLI, checks SwiftUI source syntax, and exercises real successful and failed HERMES runs without requiring macOS.
