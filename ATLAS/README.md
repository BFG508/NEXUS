# ATLAS

**Advanced Temporal & Layered Analysis Suite**

ATLAS is a Swift-based inspection and visualization client for reproducible simulation runs. Version 0.1.0 focuses on a stable offline workflow: load a HERMES run, validate its manifest, inspect project/step outcomes, reconstruct an execution timeline, inspect artifacts, verify hashes, and browse collections of runs.

ATLAS is intentionally a **consumer of results and provenance**. It does not implement scientific, tactical, orbital, social, semantic, communication, or reliability models.

## Core capabilities

ATLAS v0.1.0 provides:

- strict decoding of `hermes.run_manifest.v1`;
- portable manifest loading from either a run directory or `manifest.json`;
- structural and semantic validation of run metadata;
- dependency validation and cycle detection;
- deterministic step/run timeline reconstruction;
- JSONL telemetry loading and consistency checks;
- artifact inspection with relocation-aware path resolution;
- SHA-256 and file-size verification without external packages;
- run-directory discovery and summary ordering;
- a dependency-free Swift CLI;
- a macOS SwiftUI application shell using the same `ATLASCore` library;
- deterministic unit tests using temporary run directories.

No third-party Swift package is required.

## Operating modes

ATLAS is designed around two modes:

```text
Offline (implemented in v0.1.0)
--------------------------------
HERMES run directory
  ├── manifest.json
  ├── telemetry.jsonl
  ├── artifacts/
  └── logs/
          |
          v
        ATLAS

Live (future)
-------------
HERMES service / telemetry transport
          |
          v
        ATLAS
```

Offline operation is the canonical v0.1.0 path. A historical run remains inspectable even when no HERMES process is running.

## Supported contract

ATLAS v0.1.0 supports:

```text
hermes.run_manifest.v1
```

The schema carries:

- HERMES version;
- run ID and reproducibility fingerprint;
- run lifecycle status;
- scenario path/hash/seed;
- runtime provenance;
- run start/finish timestamps;
- telemetry path;
- step dependencies;
- process command/arguments;
- duration and exit status;
- stdout/stderr logs;
- declared artifacts with byte size and SHA-256.

ATLAS rejects an unsupported manifest schema rather than guessing how to interpret it.

## Repository structure

```text
ATLAS/
├── Sources/
│   ├── Core/
│   │   ├── Analysis/           Timeline and run summaries
│   │   ├── Contracts/          Manifest decoder and schema checks
│   │   ├── Crypto/             Dependency-free SHA-256
│   │   ├── Data/               File loading, discovery and telemetry
│   │   ├── Models/             Run/step/artifact/runtime types
│   │   ├── Validation/         Manifest and artifact validation
│   │   └── ATLASCore.swift
│   ├── ATLASCLI/               Command-line interface
│   └── ATLASApp/               macOS SwiftUI application target
├── Resources/
│   └── PreviewData/            HERMES-compatible preview fixtures
├── Tests/
│   └── CoreTests/              Portable deterministic tests
├── CHANGELOG.md
├── Package.swift
├── VERSION
└── README.md
```

## Build and test

Portable core and CLI:

```bash
swift test --package-path ATLAS
swift build --package-path ATLAS
```

From inside `ATLAS/`:

```bash
swift test
swift build
```

On macOS, `swift build` also builds the `ATLASApp` SwiftUI executable target.

Release checks run on Linux without SwiftUI or an Apple SDK. They compile and test the real core and CLI, and check SwiftUI source syntax with:

```bash
swiftc -frontend -parse ATLAS/Sources/ATLASApp/*.swift
go -C HERMES build -o /tmp/nexus-hermes ./cmd/hermes
python scripts/check_hermes_atlas.py --hermes /tmp/nexus-hermes --atlas ATLAS/.build/debug/atlas
```

The last two commands run from the NEXUS repository root. The compatibility check exercises successful runs, preparation failures and duplicate step names using real HERMES and ATLAS executables. Syntax parsing does not type-check SwiftUI APIs or test graphical rendering, file-picker permissions or application launch; those UI behaviors remain unverified by Linux CI.

## CLI

### Version

```bash
swift run --package-path ATLAS atlas version
```

### Validate a run

Pass either the run directory or its manifest:

```bash
swift run --package-path ATLAS atlas validate /path/to/run
swift run --package-path ATLAS atlas validate /path/to/run/manifest.json
```

Successful validation prints the run ID, schema and number of steps.

### Inspect a run

```bash
swift run --package-path ATLAS atlas inspect /path/to/run
```

Example output:

```text
ATLAS 0.1.0
run: integration-ci
schema: hermes.run_manifest.v1
scenario: nexus-hermes-v0.1-smoke
seed: 42
status: succeeded
steps: 8
artifacts: 7
started: 2026-09-09T12:00:00Z
finished: 2026-09-09T12:00:03Z

✓ apply-scale              succeeded     143 ms
✓ spartan-snapshot         succeeded      77 ms
✓ beam-state               succeeded     106 ms
...
```

### Timeline

```bash
swift run --package-path ATLAS atlas timeline /path/to/run
```

The timeline is sorted by timestamp and a deterministic tie-breaker. It combines run start/end with step start/end events.

### Artifacts

List declared artifacts:

```bash
swift run --package-path ATLAS atlas artifacts /path/to/run
```

Verify every declared artifact against its recorded byte count and SHA-256:

```bash
swift run --package-path ATLAS atlas artifacts --verify /path/to/run
```

HERMES currently records absolute artifact paths. To keep archived/moved run directories usable, ATLAS first checks the recorded path and then attempts a safe relocation under the loaded run's local `artifacts/` tree.

### Discover runs

```bash
swift run --package-path ATLAS atlas discover /path/to/hermes-runs
```

ATLAS scans direct child run directories containing `manifest.json`, loads valid manifests, and prints them newest-first.

## macOS application

On macOS the package exposes an `ATLASApp` executable target built with SwiftUI. The v0.1.0 application provides:

- file-based manifest/run loading;
- run overview;
- step list and status summary;
- execution timeline;
- artifact list and verification status;
- manifest provenance details.

It intentionally uses the same `ATLASCore` APIs as the CLI so validation and interpretation are not duplicated in the UI layer.

Run it on macOS with:

```bash
swift run --package-path ATLAS ATLASApp
```

## HERMES compatibility

ATLAS v0.1.0 is tested against the HERMES v0.1.0 manifest structure. HERMES remains responsible for executing processes and writing provenance. ATLAS remains responsible for reading and presenting that result.

```text
HERMES v0.1.0
      |
      | hermes.run_manifest.v1
      | telemetry.jsonl
      | artifacts
      v
ATLAS v0.1.0
```

This is a platform/provenance boundary, not a scientific mapping. Scientific adapters between NEXUS projects continue to live at repository level under `integration/`.

## Validation rules

ATLAS checks, among other invariants:

- supported schema;
- non-empty run ID, fingerprint and scenario name;
- valid SHA-256 text fields;
- unique step names;
- dependencies reference known steps;
- no self-dependencies or dependency cycles;
- finished runs have `finished_at`;
- step finish is not before step start;
- successful/failed executed steps have sensible lifecycle metadata;
- artifact sizes are non-negative;
- artifact hashes are valid hexadecimal SHA-256 values.

Artifact verification additionally checks the actual file and digest when requested.

## Reproducibility

ATLAS does not modify the loaded run. Inspection is read-only. Deterministic output is obtained by:

- stable sorting of runs, steps, events and artifacts;
- explicit schema handling;
- deterministic SHA-256 verification;
- no implicit network access;
- no hidden project-specific interpretation.

## Roadmap

### v0.2.x

- live HERMES HTTP/WebSocket client;
- continuously updating telemetry timeline;
- dependency-graph visualization;
- richer run comparison;
- filter/search across large run collections.

### v0.3.x

- reusable scientific visualization panels;
- 3D scene support for compatible geometric/orbital outputs;
- richer artifact previews;
- performance work for large telemetry streams.

### v1.0.0

- stable visualization/run-consumption contract;
- backwards-compatible manifest migration policy;
- polished macOS application architecture.

## Limitations

ATLAS v0.1.0 is not a scientific validation tool. A green manifest or matching artifact hash proves structural integrity and provenance consistency, not physical, social, statistical, tactical, or engineering correctness of the upstream model.

Live networking is not part of v0.1.0. The macOS application is intentionally focused on offline inspection; iPadOS and other Apple-platform targets are future work.
