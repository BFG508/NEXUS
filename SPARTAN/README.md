# SPARTAN 🛰️

**S**ystem for **P**arsing, **A**nalysis, and **R**outing of **T**actical **A**erospace **N**odes

SPARTAN is a COBOL/Python prototype that emulates a legacy aerospace tactical command terminal. It combines fixed-width telemetry generation, an indexed operational database, an interactive COBOL text interface, explicit import/snapshot tooling, and a small internal physics routine.

The project is intended to demonstrate legacy-style persistence, fixed-format interoperability, COBOL/Python integration, and NEXUS tactical-state experiments. Its tactical and physics behavior is deliberately simplified and must not be interpreted as operational mission software or validated aerospace performance analysis.

## Core capabilities

### Indexed operational database

`spartan_core.cbl` converts bootstrap fixed-width records into a COBOL indexed file (`ORGANIZATION IS INDEXED`) keyed by asset identifier. Once initialized, that indexed database is the authoritative operational state.

The indexed-file implementation enables direct keyed record access rather than requiring a full sequential scan for every asset lookup.

### Interactive tactical terminal

The core program uses COBOL `SCREEN SECTION` constructs to render an interactive terminal, display asset state, collect action codes, and update operational records.

### Internal physics subprogram

The core demonstrates COBOL subprogram/data-passing patterns using `CALL`, `LINKAGE SECTION`, by-reference state updates, and by-content inputs for simplified tactical recalculation.

The calculation is a project demonstration, not a high-fidelity spacecraft dynamics model.

### Fixed-width import and snapshot tools

SPARTAN separates bootstrap, live state, integration queue, and read-only interchange:

```text
spartan_init.txt       bootstrap input only
spartan_tactical.dat   authoritative indexed operational database
spartan_import.txt     queued fixed-width updates from integrations
spartan_snapshot.txt   refreshed read-only interchange snapshot
```

`spartan_import_tool.cbl` applies queued updates to the live indexed database. `spartan_snapshot_tool.cbl` exports the current authoritative state for sibling read-only analyses.

### Audit reporting

`spartan_audit_tool.cbl` reads the indexed state sequentially and produces a human-readable audit representation.

### Python bootstrap generation

`spartanGen.py` creates deterministic-format mock tactical telemetry records for initial database population/testing.

## Persistent-state contract

Once `spartan_tactical.dat` exists, it is the authoritative state. `spartan_init.txt` must not be treated as a continuously synchronized copy.

Sibling projects must not rewrite the live database or bootstrap file directly. They queue fixed-width changes in:

```text
spartan_import.txt
```

Apply queued changes explicitly:

```bash
./spartan_import_tool
```

Before a read-only sibling analysis, refresh:

```bash
./spartan_snapshot_tool
```

This makes the state transition explicit and avoids ambiguity between bootstrap data and live indexed state.

## NEXUS integration

### GAIA probe deployment

```bash
python integrations/gaiaProbeDeployer.py
```

The adapter reads processed GAIA exoplanet state, selects candidate targets under its exploratory habitability logic, and queues PROBE/RELAY assets for SPARTAN import.

### SCALE combat events

SCALE's `spartanCombatSim.py` consumes a SPARTAN snapshot/bootstrap and queues fixed-width state updates rather than mutating the indexed database directly.

### ASTRA asset generation

ASTRA can queue advanced generated civilizations/assets into `spartan_import.txt` using the fixed-width interoperability format.

### BEAM and LEVI consumers

BEAM and LEVI can read refreshed SPARTAN state for steering/trajectory analyses. Generate `spartan_snapshot.txt` before those read-only studies when the live database has changed.

These integrations are compatibility adapters, not a stable cross-project protocol.

## Reproducibility

Keep bootstrap inputs, queued import records, and snapshots associated with the scenario under test. The binary indexed database is runtime state and is not intended as the only reproducibility artifact.

For a reproducible study, record:

- source/bootstrap payload;
- ordered import queue applied;
- resulting snapshot;
- compiler/runtime version;
- Python version for generators/adapters;
- Git commit/tag.

## GnuCOBOL and Python requirements

SPARTAN uses:

- GnuCOBOL for the core/indexed database/tools;
- Python 3 for bootstrap generation and NEXUS adapters;
- `pytest` for Python regression tests.

Compile the COBOL programs with:

```bash
cd SPARTAN
cobc -x -free -o spartan_core spartan_core.cbl
cobc -x -free -o spartan_import_tool spartan_import_tool.cbl
cobc -x -free -o spartan_snapshot_tool spartan_snapshot_tool.cbl
cobc -x -free -o spartan_audit_tool spartan_audit_tool.cbl
```

## Repository structure

```text
SPARTAN/
├── integrations/
│   └── gaiaProbeDeployer.py       GAIA -> SPARTAN adapter
├── tests/
│   └── test_spartan.py            Python format/integration tests
├── spartanGen.py                  Bootstrap telemetry generator
├── spartan_core.cbl               Indexed DB + interactive terminal + physics demo
├── spartan_import_tool.cbl        Apply queued fixed-width updates
├── spartan_snapshot_tool.cbl      Export authoritative state snapshot
├── spartan_audit_tool.cbl         Human-readable indexed-state audit
├── VERSION
└── README.md
```

Runtime files such as `spartan_init.txt`, `spartan_import.txt`, `spartan_snapshot.txt`, and `spartan_tactical.dat` are generated/local state and are ignored by Git.

## Usage

Generate bootstrap telemetry:

```bash
python spartanGen.py
```

Compile the COBOL tools as shown above, then launch the core:

```bash
./spartan_core
```

Apply queued NEXUS records and refresh a consumer snapshot:

```bash
./spartan_import_tool
./spartan_snapshot_tool
```

Run a human-readable audit:

```bash
./spartan_audit_tool
```

## Tests and CI

Run Python tests with:

```bash
cd SPARTAN
python -m pytest -q
```

`.github/workflows/spartan.yml` runs the Python tests and installs GnuCOBOL on Ubuntu to compile all four COBOL programs.

A successful compile/test validates the checked software paths; it does not establish operational correctness of the tactical/physics model.

## Important modeling assumptions

- The fixed-width record format is a project interoperability convention, not an external aerospace standard.
- The indexed database is authoritative after initialization; bootstrap text is not automatically synchronized with later live-state changes.
- Tactical actions and internal physics calculations are simplified demonstration logic.
- Sibling projects must communicate through the explicit import/snapshot workflow rather than mutating internal state files.
- Generated tactical assets and combat outcomes are synthetic scenario data.
- SPARTAN is a legacy-systems/aerospace prototype, not operational command-and-control or flight software.
