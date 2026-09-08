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
├── tests/          Contract and end-to-end integration tests
└── nexus_contracts.py
```

## Validation

Run the dependency-free contract/integration tests from the repository root:

```bash
python -m pytest -q integration/tests
```

Individual project CI remains responsible for validating the scientific implementation of that project. The integration suite validates interface compatibility and cross-project data flow.
