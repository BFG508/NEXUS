#!/usr/bin/env python3
"""Normalize a SPARTAN fixed-width snapshot as nexus.tactical_state.v1."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import write_contract  # noqa: E402


def parse_snapshot(path: Path, version: str = "0.1.0") -> dict:
    assets = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        if len(raw) < 28:
            continue
        assets.append({
            "type": raw[0:10].strip(),
            "id": raw[10:20].strip(),
            "integrity": int(raw[20:23]),
            "delta_v": int(raw[23:28]),
        })
    return {
        "schema": "nexus.tactical_state.v1",
        "producer": {"project": "SPARTAN", "version": version},
        "payload": {"assets": assets},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    write_contract(args.output, parse_snapshot(args.snapshot))
    print(args.output)


if __name__ == "__main__":
    main()
