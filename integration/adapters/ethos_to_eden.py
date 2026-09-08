#!/usr/bin/env python3
"""Apply an explicit, inspectable scenario mapping from ETHOS to EDEN.

No default scientific claim links a textual semantic measurement to an EDEN
ethical trait. The mapping is therefore a separate policy artifact that must be
provided and is recorded verbatim in the output provenance.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import load_contract, write_contract  # noqa: E402

DOCTRINES = ("Egoist", "Altruist", "Utilitarian", "StrictReciprocal")
DEFAULT_GENOMES = {
    "Egoist": [0.02, 0.05, 0.05, 0.02],
    "Altruist": [0.98, 0.20, 0.90, 0.70],
    "Utilitarian": [0.70, 0.25, 0.95, 0.50],
    "StrictReciprocal": [0.95, 1.00, 0.35, 0.05],
}


def _concept_signal(row: dict) -> float:
    """Bounded descriptive signal combining valence change and supported shift.

    This is intentionally a scenario transform, not an estimator. Unsupported
    bootstrap rows contribute no semantic-shift term.
    """
    valence_ref = row.get("valence_reference")
    valence_tgt = row.get("valence_target")
    valence_delta = 0.0 if valence_ref is None or valence_tgt is None else float(valence_tgt) - float(valence_ref)
    shift = float(row.get("semantic_shift") or 0.0) if row.get("bootstrap_sufficient") else 0.0
    raw = valence_delta + 0.25 * shift
    return math.tanh(raw)


def build_initialization(profile: dict, policy: dict, population_size: int = 500) -> dict:
    fractions = {name: float(policy["baseline_doctrine_fractions"][name]) for name in DOCTRINES}
    maximum = float(policy.get("maximum_fraction_adjustment", 0.15))
    weights = policy.get("concept_weights", {})
    signals: dict[str, float] = {}

    for concept in profile["payload"]["concepts"]:
        cid = concept["id"]
        signal = _concept_signal(concept)
        signals[cid] = signal
        for doctrine, weight in weights.get(cid, {}).items():
            if doctrine not in fractions:
                raise ValueError(f"Unknown EDEN doctrine in mapping policy: {doctrine}")
            fractions[doctrine] += maximum * float(weight) * signal

    fractions = {name: max(0.0, value) for name, value in fractions.items()}
    total = sum(fractions.values())
    if total <= 0:
        raise ValueError("Mapping policy produced zero total doctrine mass")
    fractions = {name: value / total for name, value in fractions.items()}

    return {
        "schema": "nexus.eden_initialization.v1",
        "producer": {"project": "NEXUS integration", "version": "1"},
        "payload": {
            "population_size": population_size,
            "initial_doctrine_fractions": fractions,
            "genome_centers": {
                doctrine: {
                    "base_cooperation": genome[0],
                    "reciprocity": genome[1],
                    "other_regard": genome[2],
                    "forgiveness": genome[3]
                }
                for doctrine, genome in DEFAULT_GENOMES.items()
            },
            "mapping_policy": {
                "policy_id": policy["policy_id"],
                "description": policy.get("description", ""),
                "concept_signals": signals,
                "source_profile_schema": profile["schema"],
            },
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("profile", type=Path)
    parser.add_argument("policy", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--population-size", type=int, default=500)
    args = parser.parse_args()
    profile = load_contract(args.profile,)
    if profile["schema"] != "nexus.semantic_culture_profile.v1":
        raise ValueError("profile must use nexus.semantic_culture_profile.v1")
    policy = json.loads(args.policy.read_text(encoding="utf-8"))
    write_contract(args.output, build_initialization(profile, policy, args.population_size))
    print(args.output)


if __name__ == "__main__":
    main()
