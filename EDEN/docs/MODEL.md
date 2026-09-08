# EDEN model

EDEN v0.3.0 is an agent-based evolutionary-game model built around repeated Prisoner's Dilemma interactions. Each agent has an energy state, a doctrine tag, a continuous ethical genome, bounded opponent memory, and demographic metadata.

## Interaction state

The four doctrine tags are `Egoist`, `Altruist`, `Utilitarian`, and `StrictReciprocal`. A continuous `EthicalGenome` stores four normalized traits:

```text
base_cooperation
reciprocity
other_regard
forgiveness
```

The doctrine tag constrains admissible genome regions but does not replace the continuous traits.

## Memory

Opponent memory is bounded LRU state. Remembered opponents are ordered from least to most recently used. A repeated observation updates the stored action and moves that opponent to the most-recent position; a new observation at full capacity evicts the oldest entry.

## Evolution

Cultural evolution uses fitness-dependent imitation. Biological evolution applies mortality and reproduction through the configured energy thresholds, reproduction probability, carrying capacity, inheritance, and mutation. Hybrid evolution enables both mechanisms.

## Demography and energy

Game payoff can be converted into energy through `payoff_to_energy` and reduced by `metabolic_cost`. Energy then participates in biological turnover. This energy is a model resource and should not be interpreted as utility, welfare, or biological fitness outside the configured rules.

## Spatial mode

Well-mixed populations sample partners globally. Spatial populations use a periodic 2-D grid and local neighborhoods, with optional random movement.

## Invasion measurements

An invasion experiment records the resident/invader setup and separates two notions of growth:

\[
\Delta f = f_{final}-f_{initial}
\]

and

\[
\Delta N = N_{final}-N_{initial}.
\]

Frequency growth is the compatibility meaning of `grew`; absolute growth is stored separately as `grew_absolute`.

## Replicator reference

The replicator implementation is a reduced mean-field reference using a payoff matrix. The full EDEN ABM contains memory, stochastic finite populations, continuous traits, optional demography, mutation, and spatial structure that are not all represented by the reduced replicator equation.
