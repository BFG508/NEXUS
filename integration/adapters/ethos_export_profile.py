#!/usr/bin/env python3
"""Export ETHOS result tables as nexus.semantic_culture_profile.v1.

This adapter does not reinterpret semantic shift as a moral parameter. It only
packages ETHOS measurements and provenance for downstream scenario policies.
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import write_contract  # noqa: E402


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _float(value: str | None) -> float | None:
    if value in (None, "", "NaN", "nan"):
        return None
    return float(value)


def build_profile(results_dir: Path, reference: str, target: str, version: str = "1.1.0") -> dict:
    tables = results_dir / "tables"
    frequencies = _rows(tables / "concept_frequency.csv")
    valence = _rows(tables / "contextual_valence.csv")
    shifts = _rows(tables / "semantic_shift.csv")

    freq_index = {(row["group"], row["concept"]): row for row in frequencies}
    valence_index = {(row["group"], row["concept"]): row for row in valence}
    selected = [row for row in shifts if row["from_group"] == reference and row["to_group"] == target]
    if not selected:
        raise ValueError(f"No ETHOS semantic-shift rows for {reference!r} -> {target!r}")

    concepts = []
    for row in selected:
        concept = row["concept"]
        reference_frequency = freq_index.get((reference, concept), {})
        target_frequency = freq_index.get((target, concept), {})
        reference_valence = valence_index.get((reference, concept), {})
        target_valence = valence_index.get((target, concept), {})
        concepts.append({
            "id": concept,
            "label": row.get("label", concept),
            "frequency_reference": _float(reference_frequency.get("frequency")),
            "frequency_target": _float(target_frequency.get("frequency")),
            "semantic_shift": _float(row.get("shift")),
            "ci_low": _float(row.get("ci_lower")),
            "ci_high": _float(row.get("ci_upper")),
            "bootstrap_sufficient": str(row.get("bootstrap_sufficient", "false")).lower() == "true",
            "valid_bootstraps": int(row.get("valid_bootstraps") or 0),
            "anchors": int(row.get("anchors") or 0),
            "anchor_rank": int(row.get("anchor_rank") or 0),
            "valence_reference": _float(reference_valence.get("valence")),
            "valence_target": _float(target_valence.get("valence")),
        })

    return {
        "schema": "nexus.semantic_culture_profile.v1",
        "producer": {"project": "ETHOS", "version": version},
        "payload": {
            "analysis_language": "en",
            "comparison": {"reference": reference, "target": target},
            "concepts": concepts,
            "interpretation": (
                "Text-derived semantic measurements only. Downstream use requires an explicit mapping policy; "
                "semantic displacement is not treated as moral or causal evidence."
            ),
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("results_dir", type=Path)
    parser.add_argument("reference")
    parser.add_argument("target")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    write_contract(args.output, build_profile(args.results_dir, args.reference, args.target))
    print(args.output)


if __name__ == "__main__":
    main()
