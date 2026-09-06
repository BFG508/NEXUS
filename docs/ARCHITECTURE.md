# NEXUS architecture baseline

Each NEXUS project owns its domain logic and must remain executable without importing another project's source tree. Cross-project communication should converge on explicit, versioned interchange schemas rather than direct dependencies on sibling implementation details.

Current domain boundaries are:

- **ASTRA:** stellar systems, planets, geology proxies, and civilization initial conditions;
- **GAIA:** planetary environment, habitability, and astrobiology proxies;
- **EDEN:** social, ethical, and evolutionary dynamics;
- **SCALE:** stochastic events and probabilistic state transitions;
- **SPARTAN:** tactical assets and persistent operational state;
- **BEAM:** communications, antenna arrays, steering, and interference studies;
- **LEVI:** orbital mechanics, transfers, and trajectory analysis.

## Integration baseline

Existing `integrations/` scripts are compatibility adapters. They may currently:

- consume a producer-generated file directly;
- transform a producer artifact into a consumer-specific format;
- queue changes through SPARTAN's fixed-width import path; or
- reproduce a deliberately limited local proxy when the sibling runtime is not invoked.

The README of each project identifies which behavior applies. Compatibility adapters are not a stable public cross-project API.

## Future interchange schemas

When an integration becomes part of the intended stable NEXUS architecture, its producer/consumer payload should be defined by an explicit versioned schema. Schemas should be introduced only alongside implemented producer and consumer support rather than by reserving an otherwise empty repository directory.

A future schema change should version the data contract instead of requiring either project to import or understand the sibling project's internal code layout.
