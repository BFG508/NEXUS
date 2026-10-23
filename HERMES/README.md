# HERMES

**Heterogeneous Execution & Runtime Manager for Ecosystem Simulations**

HERMES is the generic orchestration layer used by NEXUS to execute heterogeneous simulation workflows as explicit dependency graphs. It coordinates external programs while preserving execution order, seeds, provenance, logs, declared artifacts, checksums, and failure state.

HERMES contains **no scientific model of its own**. It does not know how ASTRA generates a stellar system, how EDEN evolves agents, or how LEVI propagates an orbit. Those concerns remain inside their respective projects. NEXUS-specific commands and adapters live at repository level under `integration/` and are supplied to HERMES through scenario files.

## Core capabilities

HERMES v0.1.0 implements:

- Scenario v1 loading from JSON or a constrained YAML subset.
- Structural and semantic scenario validation.
- Directed acyclic graph construction and deterministic topological planning.
- Sequential dependency-aware execution of arbitrary local processes.
- Per-step timeouts and process exit-code capture.
- Explicit environment overrides without serializing the caller's full environment.
- Failure propagation: a failed step blocks all remaining unexecuted work in v0.1.0.
- Runtime variable expansion for portable scenarios.
- Structured stdout/stderr logs for every step.
- JSONL telemetry for run and step lifecycle events.
- Declared artifact verification, size recording, and SHA-256 hashing.
- Run manifests with scenario provenance, effective seed, platform information, Git provenance when available, and individual step results.
- A deterministic run fingerprint distinct from the unique run identifier.
- CLI commands for validation, planning, execution, and inspection.

Step timing begins when HERMES attempts a step, before variable expansion and log/artifact-directory preparation. If preparation fails before launching a process, the step records `failed`, start/finish timestamps and an error, with no process exit code. Its telemetry still records `running` followed by `failed`.

## Architecture

```text
Scenario file
     |
     v
 Parser + validation
     |
     v
 Dependency graph
     |
     v
 Deterministic plan
     |
     v
 Local process runner
     |
     +----> stdout/stderr logs
     +----> telemetry.jsonl
     +----> declared artifacts + SHA-256
     |
     v
 manifest.json
```

The implementation deliberately keeps the orchestration engine independent from project adapters:

```text
HERMES standalone project
    generic scenario + process runtime
              |
              v
NEXUS/integration/
    project-specific commands/contracts
              |
              v
ASTRA / GAIA / ETHOS / EDEN / SCALE / SPARTAN / BEAM / LEVI / ...
```

## Repository structure

```text
HERMES/
├── cmd/hermes/                 CLI entry point
├── internal/
│   ├── artifact/               Artifact checksums and metadata
│   ├── executor/               Context-aware process execution
│   ├── graph/                  DAG validation and planning
│   ├── manifest/               Run-manifest model and persistence
│   ├── reproducibility/        Scenario hashes, fingerprints, provenance
│   ├── runner/                 End-to-end execution engine
│   ├── scenario/               Scenario v1 parser and validation
│   ├── telemetry/              JSONL lifecycle events
│   └── workspace/              Run-directory construction
├── pkg/protocol/               Public status constants
├── scenarios/                  Standalone examples
├── tests/                      Black-box execution tests
├── CHANGELOG.md
├── go.mod
├── VERSION
└── README.md
```

## Scenario v1

HERMES accepts JSON and a deliberately constrained YAML subset. The YAML reader supports the structures needed by Scenario v1 rather than attempting to be a general YAML implementation. Unsupported YAML syntax is rejected with a line-numbered error instead of being guessed.

A scenario contains a version, name, seed, optional working directory, and named steps:

```yaml
version: 1
name: minimal-demo
seed: 42
working_directory: .

steps:
  prepare:
    command: sh
    args:
      - -c
      - printf 'hello\\n' > "${STEP_ARTIFACT_DIR}/message.txt"
    timeout_seconds: 10
    artifacts:
      - ${STEP_ARTIFACT_DIR}/message.txt

  consume:
    command: sh
    depends_on:
      - prepare
    args:
      - -c
      - cat "${RUN_DIR}/artifacts/prepare/message.txt"
    timeout_seconds: 10
```

Step names must contain only letters, numbers, `.`, `_`, or `-`.

### Supported runtime variables

HERMES expands only explicit `${NAME}` placeholders. Available built-ins are:

| Variable | Meaning |
|---|---|
| `${SCENARIO_DIR}` | Directory containing the scenario file |
| `${WORKING_DIR}` | Resolved scenario working directory |
| `${RUN_DIR}` | Current run directory |
| `${RUN_ID}` | Unique current run identifier |
| `${SEED}` | Effective run seed |
| `${STEP}` | Current step name |
| `${STEP_ARTIFACT_DIR}` | `RUN_DIR/artifacts/<step>` |

Other `${NAME}` values are resolved from the process environment. Unknown variables are errors.

## Run directory

A successful or failed run is preserved as:

```text
<runs-dir>/
└── <run-id>/
    ├── manifest.json
    ├── telemetry.jsonl
    ├── logs/
    │   ├── prepare.stdout.log
    │   ├── prepare.stderr.log
    │   └── ...
    └── artifacts/
        ├── prepare/
        ├── consume/
        └── ...
```

Declared artifacts are not silently invented or copied from arbitrary locations. HERMES verifies that each declared path exists after the step, records its absolute path, size, and SHA-256 digest, and fails the step if a required declared artifact is missing.

## Reproducibility model

HERMES distinguishes between:

- **run ID** — unique identifier for one concrete execution;
- **run fingerprint** — deterministic SHA-256-derived identifier based on the scenario content hash and effective seed.

Repeated runs of the same scenario and seed therefore receive different run IDs but the same fingerprint. The manifest also records:

- scenario SHA-256;
- effective seed;
- HERMES version;
- Go version and operating platform;
- working directory;
- Git commit and dirty state when the working directory belongs to a Git checkout;
- expanded command and arguments for each step;
- timestamps, duration, exit code, logs, artifacts, and errors.

This metadata supports reproduction; it does not guarantee bit-for-bit determinism in the external programs being executed.

## CLI

Build and test:

```bash
go test ./...
go build ./cmd/hermes
```

Show the version:

```bash
go run ./cmd/hermes version
```

Validate a scenario:

```bash
go run ./cmd/hermes validate scenarios/minimal.yaml
```

Show the execution plan without running anything:

```bash
go run ./cmd/hermes plan scenarios/minimal.yaml
```

Execute a scenario:

```bash
go run ./cmd/hermes run --runs-dir .hermes/runs scenarios/minimal.yaml
```

Override the scenario seed:

```bash
go run ./cmd/hermes run --seed 1234 scenarios/minimal.yaml
```

Use a deterministic test/run name when needed:

```bash
go run ./cmd/hermes run --run-id engineering-case-001 scenarios/minimal.yaml
```

Inspect either a run directory or its manifest directly:

```bash
go run ./cmd/hermes inspect .hermes/runs/<run-id>
go run ./cmd/hermes inspect .hermes/runs/<run-id>/manifest.json
```

## NEXUS integration

The NEXUS repository contains a repository-level smoke scenario at:

```text
integration/scenarios/hermes_v0.1_smoke.yaml
```

It exercises a real adapter chain:

```text
SCALE stochastic event
        |
        v
SPARTAN tactical-state update
        |
        v
BEAM communication-state evaluation
        |
        v
LEVI trajectory-request construction
```

HERMES itself contains none of those adapters. This preserves standalone release isolation.

## Failure semantics

v0.1.0 uses deterministic sequential execution. When a step fails because of a non-zero exit code, timeout, variable error, or missing declared artifact:

1. the failing step is recorded as `failed`;
2. the run is recorded as `failed`;
3. all steps that have not yet run are recorded as `blocked`;
4. logs, telemetry, and the manifest are still finalized;
5. the CLI exits non-zero.

This intentionally conservative behavior makes partial execution explicit. Concurrent branch scheduling and more granular keep-going policies are deferred.

## Security boundary

A HERMES scenario is executable configuration. `command` and `args` launch local processes with the current user's permissions. HERMES v0.1.0 does **not** sandbox processes, enforce resource quotas, isolate containers, or authenticate scenario authors. Only run trusted scenarios.

## Roadmap

### v0.2.x

- concurrent execution of independent DAG branches;
- resumable runs;
- richer retry policies;
- optional artifact-copy/store policies;
- HTTP status API and live telemetry transport.

### v0.3.x

- remote/distributed executors;
- explicit resource requirements and scheduling;
- pluggable execution backends.

### v1.0.0

- stable Scenario and Run Manifest contracts;
- compatibility guarantees;
- validated executor semantics across supported platforms.

## Limitations

HERMES v0.1.0 is a local engineering orchestrator, not a workflow-security boundary or distributed scheduler. It does not validate the scientific meaning of project outputs. NEXUS JSON contracts and cross-domain policies remain the responsibility of the repository-level integration layer.
