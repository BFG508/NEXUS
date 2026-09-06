# SCALE 🎲

**S**cala **C**alculator **A**nd **L**uck **E**ngine

SCALE is an experimental Scala framework for parsing/evaluating dice notation while exploring stochastic state transitions, contextual entities, scalar Kalman fusion, and PI-based variance compensation. The project combines a command-line engine with JSON-driven state and small Python NEXUS adapters.

The control-inspired randomness mechanisms are research/prototyping experiments. SCALE does not claim that Kalman-fused output is cryptographically uniform, that PI compensation improves statistical fairness in a formal sense, or that its stochastic game mechanisms are substitutes for a validated probabilistic model.

## Core capabilities

### Dice grammar and AST evaluation

`DiceParser.scala` and `DiceEngine.scala` parse structured dice expressions into an abstract syntax representation rather than relying on a single regular expression. The current syntax includes combinations such as:

```text
4d6!kh3+2
2d20kh1+5
```

The engine includes exploding-dice and keep-high/keep-low behavior as implemented by the parser/evaluator.

### Experimental scalar Kalman entropy fusion

`EntropyFusionFilter.scala` combines normalized measurements from `scala.util.Random` and `java.security.SecureRandom` through an implemented scalar Kalman estimator before mapping the fused state back into a roll range.

This intentionally changes the statistical distribution relative to direct uniform `SecureRandom` sampling. Use `SecureRandom` directly when uniform cryptographic randomness is the requirement.

### PI karma controller

`KarmaController.scala` uses proportional/integral feedback around a configured statistical target and accumulates an error state to generate a compensation signal.

The implementation is PI, not PID: there is no derivative term in the current controller.

### Markov environment engine

`MarkovEngine.scala` and related state models load discrete environment states/transitions from JSON and evaluate stochastic transitions through the dice engine.

### Contextual entity management

`EntityManager.scala` deserializes JSON entities with uPickle so dice expressions can be evaluated with named context rather than only raw numeric input.

### Terminal telemetry

`TelemetryVisualizer.scala` renders compact ASCII telemetry/sparklines for the interactive CLI.

## NEXUS integration

### SPARTAN combat compatibility adapter

```bash
python integrations/spartanCombatSim.py
```

The adapter reads the latest SPARTAN snapshot/bootstrap state, evaluates stochastic combat events, and queues fixed-width updates in `SPARTAN/spartan_import.txt`. The live indexed database is updated only when SPARTAN's explicit import tool is run.

### BEAM jamming profile

```bash
python integrations/beamJammingSim.py
```

The adapter generates a JSON jamming profile consumed by BEAM. Sidelobe estimates are taken from local maxima outside the main-lobe region rather than from the immediately adjacent angular sample.

### ASTRA entity input

ASTRA can generate `data/astra_entities.json`. SCALE v0.1.0 treats loaded entity attributes as rollable expressions, so the compatibility exporter limits its payload to values compatible with that interpretation.

These adapters are not a stable NEXUS protocol.

## Reproducibility

JSON state under `data/` provides repository fixtures for entities/environment scenarios. For repeatable stochastic studies, preserve the input JSON, command/configuration, JVM/Scala dependency state, and any explicit seed path used by the experiment.

Because the entropy-fusion layer mixes two RNG sources, reproducibility/cryptographic properties depend on the execution path. Tests validate bounds and logic rather than asserting a particular random sequence.

## JVM and Scala requirements

Current build targets Scala 2.13.12 through `sbt`.

Recommended local toolchain:

- JDK 17;
- sbt 1.9.x or compatible.

Compile/test with:

```bash
cd SCALE
sbt test
```

Python 3 plus `pytest` is also required to run the BEAM-jamming integration regression.

## Repository structure

```text
SCALE/
├── data/
│   ├── astra_entities.json        ASTRA compatibility payload
│   ├── entities.json              Entity fixture
│   └── environment.json           Markov environment fixture
├── integrations/
│   ├── beamJammingSim.py          BEAM jamming-profile generator
│   ├── spartanCombatSim.py        SPARTAN combat adapter
│   └── test_beamJammingSim.py     Python integration regression
├── src/
│   ├── main/scala/
│   │   ├── DiceEngine.scala
│   │   ├── DiceParser.scala
│   │   ├── EntityManager.scala
│   │   ├── EntropyFusionFilter.scala
│   │   ├── KarmaController.scala
│   │   ├── Main.scala
│   │   ├── MarkovEngine.scala
│   │   ├── Models.scala
│   │   ├── StateManager.scala
│   │   └── TelemetryVisualizer.scala
│   └── test/scala/
│       └── DiceEngineTest.scala
├── build.sbt
├── VERSION
└── README.md
```

## Usage

Launch the CLI:

```bash
cd SCALE
sbt run
```

Representative commands include:

```text
scale> 2d20kh1+5
scale> load entities characters.json
scale> load environment weather.json
scale> telemetry show
```

Run the Scala and Python tests with:

```bash
sbt test
python -m pytest -q integrations/test_beamJammingSim.py
```

## Tests and CI

`src/test/scala/DiceEngineTest.scala` is a ScalaTest suite covering parser/evaluator behavior, keep-high logic, invalid dice, bounded entropy fusion, and the PI controller.

`integrations/test_beamJammingSim.py` exercises the BEAM-jamming compatibility calculation.

`.github/workflows/scale.yml` configures JDK 17/sbt, runs Scala tests, then configures Python and runs the integration regression.

## Important modeling assumptions

- The scalar Kalman fusion is an experimental variance-reduction/fusion mechanism and is not intended to preserve a uniform cryptographic roll distribution.
- The karma controller is PI only; no derivative feedback is implemented.
- Dice/parser tests validate logic and bounds, not statistical certification of every distribution.
- Markov transitions are determined by the configured JSON states/thresholds and dice behavior rather than a domain-calibrated stochastic process model.
- The SPARTAN/BEAM scripts are compatibility adapters and may change when formal interchange schemas are introduced.
- SCALE is an experimental stochastic/game-system framework, not a cryptographic randomness service or safety-critical probabilistic engine.
