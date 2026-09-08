#!/usr/bin/env python3
"""Export the last row of an EDEN metrics CSV as nexus.society_state.v1."""
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import write_contract  # noqa: E402


def build_state(metrics_csv: Path, version: str = "0.3.0") -> dict:
    with metrics_csv.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise ValueError("EDEN metrics CSV is empty")
    row = rows[-1]
    return {
        "schema": "nexus.society_state.v1",
        "producer": {"project": "EDEN", "version": version},
        "payload": {
            "generation": int(float(row["generation"])),
            "population_size": int(float(row["population_size"])),
            "doctrine_fractions": {
                "Egoist": float(row["egoist_fraction"]),
                "Altruist": float(row["altruist_fraction"]),
                "Utilitarian": float(row["utilitarian_fraction"]),
                "StrictReciprocal": float(row["reciprocal_fraction"]),
            },
            "cooperation_rate": float(row["cooperation_rate"]),
            "mean_energy": float(row.get("mean_energy") or 0.0),
            "strategy_diversity": float(row.get("strategy_diversity") or 0.0),
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("metrics_csv", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    write_contract(args.output, build_state(args.metrics_csv))
    print(args.output)


if __name__ == "__main__":
    main()
