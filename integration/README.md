# NEXUS integration

This directory contains the versioned contracts and adapters that connect the independent NEXUS projects. Integration code deliberately lives outside the project directories so standalone releases contain only the project being released.

## Contract architecture

```text
ASTRA -> stellar_system.v1 -> GAIA
ETHOS -> semantic_culture_profile.v1 -> explicit policy -> EDEN
EDEN -> society_state.v1 -> downstream scenario/event layer
SCALE -> stochastic_event.v1 -> SPARTAN
SPARTAN -> tactical_state.v1 -> BEAM
BEAM -> communication_state.v1 -> LEVI
SPARTAN + BEAM -> explicit reliability policy -> AEGIS
ASTRA -------------------------------------------> LEVI
```

The contracts are intentionally small JSON interfaces. Adapters may translate formats, but they must not silently reimplement another project's scientific model. The ETHOS-to-EDEN adapter is especially explicit: semantic measurements are not interpreted as moral traits unless a separate, inspectable scenario policy performs that mapping.

## Layout

```text
integration/
├── adapters/       Runtime bridges and format translators
├── contracts/      Versioned JSON Schema documents
├── fixtures/       Small deterministic CI fixtures
├── policies/       Explicit cross-domain scenario mappings
├── scenarios/      Repository-level orchestration scenarios (HERMES)
├── tests/          Contract and end-to-end integration tests
└── nexus_contracts.py
```

## Validation

Run the dependency-free contract/integration tests from the repository root:

```bash
python -m pytest -q integration/tests
```

Individual project CI remains responsible for validating the scientific implementation of that project. The integration suite validates interface compatibility and cross-project data flow.

## HERMES v0.1.0 smoke scenario

`scenarios/hermes_v0.1_smoke.yaml` validates the orchestration boundary without moving NEXUS-specific logic into HERMES. From the repository root:

```bash
(cd HERMES && go run ./cmd/hermes validate ../integration/scenarios/hermes_v0.1_smoke.yaml)
(cd HERMES && go run ./cmd/hermes run --runs-dir /tmp/nexus-hermes --run-id smoke ../integration/scenarios/hermes_v0.1_smoke.yaml)
```

The scenario applies a SCALE event to SPARTAN state, evaluates BEAM communication state, builds an AEGIS reliability case through an explicit policy, runs AEGIS v0.1.0, and builds a LEVI trajectory request. The outputs are recorded as HERMES-declared artifacts with hashes and run provenance.


## AEGIS v0.1.0 integration boundary

`adapters/build_aegis_case.py` translates NEXUS tactical and communication state into a standalone AEGIS configuration only when an explicit policy is supplied. The example policy is `policies/aegis_from_nexus.example.json`.

This boundary is intentionally explicit: tactical integrity and communication state are not physically identical to reliability parameters. The adapter applies scenario assumptions from the policy; AEGIS itself remains domain-agnostic.

## ATLAS v0.1.0 compatibility boundary

ATLAS consumes the HERMES `hermes.run_manifest.v1` execution/provenance record directly. This is not a scientific cross-domain mapping: ATLAS reads lifecycle metadata, timestamps, dependencies, logs, and declared artifacts. The native ATLAS CI validates a deterministic HERMES-format fixture, and the repository integration workflow includes a macOS HERMES-to-ATLAS smoke run.

NEXUS-specific interpretation of scientific artifact payloads remains outside the standalone ATLAS project.
