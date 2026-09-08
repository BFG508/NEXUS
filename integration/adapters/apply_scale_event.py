#!/usr/bin/env python3
"""Apply a SCALE event contract deterministically to a SPARTAN tactical contract."""
from __future__ import annotations

import argparse
from copy import deepcopy
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import load_contract, write_contract  # noqa: E402


def apply_event(tactical: dict, event: dict) -> dict:
    if tactical["schema"] != "nexus.tactical_state.v1":
        raise ValueError("Expected tactical state")
    if event["schema"] != "nexus.stochastic_event.v1":
        raise ValueError("Expected stochastic event")
    result = deepcopy(tactical)
    modifiers = event["payload"]["modifiers"]
    target_ids = set(modifiers.get("asset_ids", []))
    integrity_delta = int(modifiers.get("integrity_delta", 0))
    delta_v_delta = int(modifiers.get("delta_v_delta", 0))
    for asset in result["payload"]["assets"]:
        if target_ids and asset["id"] not in target_ids:
            continue
        asset["integrity"] = max(0, min(100, int(asset["integrity"]) + integrity_delta))
        asset["delta_v"] = max(0, int(asset["delta_v"]) + delta_v_delta)
    result["producer"] = {"project": "SPARTAN", "version": "0.1.0", "source_event": event["payload"]["event_id"]}
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tactical", type=Path)
    parser.add_argument("event", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    write_contract(args.output, apply_event(load_contract(args.tactical), load_contract(args.event)))
    print(args.output)


if __name__ == "__main__":
    main()
