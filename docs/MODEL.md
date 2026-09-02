# EDEN v0.2 scientific model

EDEN separates six levels: game, decision policy, continuous genome, doctrine, evolutionary mechanism, and environment.

## Game

The Prisoner's Dilemma uses `T > R > P > S`. Payoff is game utility and is not identified with energy.

## Genome and doctrine

`EthicalGenome` contains four normalized parameters: baseline cooperation, reciprocity, regard for others' welfare, and forgiveness. `doctrine_tag` selects a policy family; the genome parameterizes that policy.

## Energy

Per interaction, `ΔE = payoff_to_energy * payoff - metabolic_cost`. In biological and hybrid modes, energy can trigger death and reproduction.

## Cultural evolution

Imitation uses the Fermi rule. Updating may be asynchronous or synchronous.

## Biological evolution

Agents with energy less than or equal to the death threshold are removed. Agents above the reproduction threshold may produce offspring up to the carrying capacity. Offspring inherit doctrine and genome, subject to mutation.

## Hybrid evolution

Applies cultural evolution first and biological turnover second in each generation.

## Memory

Memory is bounded by `memory_capacity`. Each agent retains the most recent actions of a limited number of opponents, avoiding the O(N²) scaling of v0.1.

## ESS

Resident–invader experiments generate empirical probabilities of growth/fixation. `empirical_ess_candidates` is an experimental screening procedure, not a mathematical demonstration of evolutionary stability.
