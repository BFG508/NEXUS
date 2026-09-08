# NEXUS architecture

NEXUS is a monorepo of independently executable projects connected through a repository-level integration layer. Domain implementations do not import sibling source trees and project releases do not contain cross-project adapters.

## Domain ownership

- **ASTRA:** stellar systems, planets, geology proxies, and civilization initial conditions.
- **GAIA:** exoplanet data processing, habitability, and astrobiology proxies.
- **ETHOS:** corpus provenance, lexical/concept analysis, distributional semantics, and semantic-shift uncertainty.
- **EDEN:** agent-based ethical/social dynamics, evolutionary game experiments, and invasion diagnostics.
- **SCALE:** stochastic dice/state-transition behavior and entropy/controller experiments.
- **SPARTAN:** tactical asset persistence and fixed-width operational state.
- **BEAM:** ideal phased-array steering and array-factor calculations.
- **LEVI:** orbital mechanics, Lambert transfers, and trajectory studies.

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

For public GitHub releases, the replacement script creates isolated synthetic tag commits from the standalone trees so GitHub's automatic source archives are project-only as well.
