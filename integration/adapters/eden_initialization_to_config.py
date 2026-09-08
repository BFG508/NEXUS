#!/usr/bin/env python3
"""Translate nexus.eden_initialization.v1 into EDEN's generic TOML runner config."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import load_contract  # noqa: E402

DOCTRINES = ("Egoist", "Altruist", "Utilitarian", "StrictReciprocal")


def convert(initialization: dict, output: Path, *, generations: int = 500, seed: int = 42) -> Path:
    if initialization["schema"] != "nexus.eden_initialization.v1":
        raise ValueError("Expected nexus.eden_initialization.v1")
    payload = initialization["payload"]
    fractions = payload["initial_doctrine_fractions"]
    missing = [name for name in DOCTRINES if name not in fractions]
    if missing:
        raise ValueError(f"Missing EDEN doctrine fractions: {missing}")
    total = sum(float(fractions[name]) for name in DOCTRINES)
    if abs(total - 1.0) > 1e-9:
        raise ValueError("EDEN doctrine fractions must sum to one")
    output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "[simulation]",
        f"population_size = {int(payload['population_size'])}",
        f"generations = {int(generations)}",
        f"seed = {int(seed)}",
        "",
        "[initial_doctrine_fractions]",
    ]
    lines.extend(f'{name} = {float(fractions[name]):.17g}' for name in DOCTRINES)
    lines.extend([
        "",
        "[provenance]",
        f'mapping_policy = "{payload["mapping_policy"].get("policy_id", "unknown")}"',
        f'source_schema = "{initialization["schema"]}"',
        "",
    ])
    output.write_text("\n".join(lines), encoding="utf-8")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("initialization", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--generations", type=int, default=500)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    print(convert(load_contract(args.initialization), args.output, generations=args.generations, seed=args.seed))


if __name__ == "__main__":
    main()
