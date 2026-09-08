#!/usr/bin/env python3
"""Build a LEVI trajectory request from NEXUS stellar and communication state."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import load_contract, write_contract  # noqa: E402


def build_request(stellar: dict, communication: dict, origin_index: int = 0, target_index: int = 1) -> dict:
    if stellar["schema"] != "nexus.stellar_system.v1":
        raise ValueError("Expected stellar system")
    if communication["schema"] != "nexus.communication_state.v1":
        raise ValueError("Expected communication state")
    planets = stellar["payload"]["planets"]
    if len(planets) < 2:
        raise ValueError("At least two planets are required for a transfer request")
    origin = planets[origin_index]
    target = planets[target_index]
    link_quality = min((link["normalized_array_gain"] for link in communication["payload"]["links"]), default=1.0)
    return {
        "schema": "nexus.trajectory_request.v1",
        "producer": {"project": "NEXUS integration", "version": "1"},
        "payload": {
            "origin": {"id": origin["id"], "semimajor_axis_au": origin["semimajor_axis_au"], "eccentricity": origin["eccentricity"]},
            "target": {"id": target["id"], "semimajor_axis_au": target["semimajor_axis_au"], "eccentricity": target["eccentricity"]},
            "constraints": {
                "minimum_communication_gain": link_quality,
                "mu_star_mass_solar": stellar["payload"]["star"]["mass_solar"],
            },
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("stellar", type=Path)
    parser.add_argument("communication", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    write_contract(args.output, build_request(load_contract(args.stellar), load_contract(args.communication)))
    print(args.output)


if __name__ == "__main__":
    main()
