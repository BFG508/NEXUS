# NEXUS architecture

NEXUS is a monorepo of independently executable projects connected through a repository-level integration layer. Domain implementations do not import sibling source trees and project releases do not contain cross-project adapters.

## Domain ownership

- **AEGIS:** reliability, availability, fault/degradation models, FDIR coverage, and survivability analysis.

- **ASTRA:** stellar systems, planets, geology proxies, and civilization initial conditions.
- **GAIA:** exoplanet data processing, habitability, and astrobiology proxies.
- **ETHOS:** corpus provenance, lexical/concept analysis, distributional semantics, and semantic-shift uncertainty.
- **EDEN:** agent-based ethical/social dynamics, evolutionary game experiments, and invasion diagnostics.
- **SCALE:** stochastic dice/state-transition behavior and entropy/controller experiments.
- **SPARTAN:** tactical asset persistence and fixed-width operational state.
- **BEAM:** ideal phased-array steering and array-factor calculations.
- **LEVI:** orbital mechanics, Lambert transfers, and trajectory studies.

## Platform ownership

- **HERMES:** generic heterogeneous workflow orchestration, dependency scheduling, subprocess execution, provenance, and artifacts. It contains no scientific model.
- **ATLAS:** Swift-based offline/live visualization of run manifests, artifacts, timelines, and future telemetry. It consumes results rather than implementing scientific models.

HERMES v0.1.0, AEGIS v0.1.0, and ATLAS v0.1.0 are implemented. HERMES participates only at the orchestration layer. AEGIS remains a domain-agnostic reliability engine, while NEXUS-specific reliability mappings live under `integration/` and require explicit policies. ATLAS consumes HERMES execution/provenance records and declared artifacts without embedding sibling scientific models. All standalone releases remain isolated from repository-level adapters and contracts.

## HERMES orchestration boundary

HERMES consumes executable scenario definitions rather than scientific contracts. The canonical v0.1.0 smoke path is:

```text
SCALE stochastic_event.v1 fixture
        |
        v
NEXUS adapter -> SPARTAN tactical_state.v1
        |
        v
NEXUS adapter -> BEAM communication_state.v1
        |\
        | \-> explicit reliability policy -> AEGIS v0.1.0 analysis
        |
        \----> NEXUS adapter -> LEVI trajectory_request.v1
```

The scenario definition is stored in `integration/scenarios/hermes_v0.1_smoke.yaml`. This placement is intentional: the commands know about NEXUS, while the HERMES engine only knows about steps, dependencies, processes, artifacts, logs, and provenance.

## ATLAS visualization boundary

ATLAS v0.1.0 consumes the generic HERMES v0.1.0 run record rather than importing HERMES implementation code. Its offline input boundary is:

```text
HERMES execution
   |
   +-- manifest.json      hermes.run_manifest.v1
   +-- telemetry.jsonl
   +-- artifacts/
   +-- logs/
   |
   v
ATLAS v0.1.0
   +-- structural validation
   +-- timeline reconstruction
   +-- artifact/hash inspection
   +-- provenance presentation
```

ATLAS does not infer scientific meaning from an artifact merely because HERMES recorded it. Project-specific scientific visualization adapters, when required, remain a separate NEXUS integration concern.

## Interface rule

Cross-project behavior lives under `integration/` and communicates using versioned contracts. An adapter may:

1. invoke a producer's documented public/core interface;
2. translate a producer artifact into a versioned NEXUS contract;
3. translate a contract into a consumer's documented input format; or
4. apply an explicit scenario policy whose assumptions are stored with the output.

An adapter must **not** reimplement a sibling model and present the result as if the sibling had executed.

## Versioned contracts

Current v1 contracts cover stellar systems, habitability, semantic culture profiles, EDEN initialization, society state, stochastic events, tactical state, communication state, and trajectory requests. Schemas are stored in `integration/contracts/`.

Schema versioning is independent from project versioning. A project can advance without changing a contract when its emitted/consumed interface remains compatible.

## ETHOS-to-EDEN boundary

ETHOS produces descriptive textual measurements. EDEN consumes simulation parameters. There is no scientifically privileged direct mapping between those domains, so NEXUS requires a separate mapping-policy file. The example policy is deliberately labelled a scenario transform rather than an estimator.

The chain is therefore:

```text
ETHOS results
   ↓
semantic_culture_profile.v1
   ↓
explicit mapping policy
   ↓
eden_initialization.v1
   ↓
generic EDEN TOML runner configuration
```

This keeps the assumption visible and reproducible.

## Release boundary

`integration/` belongs to NEXUS, not to any standalone project release. Release tooling validates that neither `integration/` nor historical project-local `integrations/` directories appear inside generated project ZIPs.

For public GitHub releases, the append-only publisher creates isolated synthetic tag commits from standalone trees so GitHub's automatic source archives are project-only as well. Established release tags are never deleted or retargeted by current tooling.
