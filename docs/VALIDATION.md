# EDEN validation and inference

EDEN validation separates software correctness, stochastic uncertainty, invasion diagnostics, and reduced-model comparison.

## Software tests

The package test suite exercises game payoffs, strategy probabilities, true LRU memory behavior, parameter validation, evolutionary updates, demographic behavior, metrics, uncertainty helpers, invasion experiments, and theory utilities.

## Ensemble uncertainty

Use independent seeds for population-level claims. `summarize_ensemble` supports Student-t mean intervals and bootstrap mean intervals. Report the number of realizations together with interval method, confidence level, and bootstrap seed/replicate count when applicable.

## Invasion inference

Invasion success is binomial at the replicate level. EDEN therefore reports a Wilson interval for the probability that an invader increases in frequency. ESS-candidate diagnostics require resident coverage against every tested doctrine by default and can classify a resident conservatively using the upper confidence bound.

A finite simulation result is not a formal proof of evolutionary stability.

## ABM-to-replicator comparison

The binary comparison is directional. The convergence grid varies population size and selection intensity while keeping the reduced assumptions controlled. Improved agreement as finite-population/stochastic effects are reduced is evidence of internal consistency for that controlled regime, not proof that the full model is equivalent to replicator dynamics.

## Reporting requirements

For a reproducible campaign preserve:

- EDEN version/tag and environment;
- complete simulation parameters;
- seeds and realization count;
- generation horizon and stopping rules;
- confidence method and level;
- invasion resident/invader matrix coverage; and
- any external NEXUS mapping policy used to generate initialization.
