#!/usr/bin/env python3
"""Evaluate BEAM ideal-array gain for tactical assets with explicit target angles."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
sys.path.insert(0, str(NEXUS / "BEAM"))
from nexus_contracts import load_contract, write_contract  # noqa: E402
from beam.array import array_factor, progressive_phase_shift  # noqa: E402


def build_communication_state(tactical: dict, frequency_hz: float = 1.0e9) -> dict:
    if tactical["schema"] != "nexus.tactical_state.v1":
        raise ValueError("Expected nexus.tactical_state.v1")
    links = []
    for index, asset in enumerate(tactical["payload"]["assets"]):
        target_deg = float(asset.get("beam_target_deg", 90.0))
        pointing_error_deg = float(asset.get("pointing_error_deg", 0.0))
        phase = progressive_phase_shift(target_deg, frequency_hz=frequency_hz)
        realized = target_deg + pointing_error_deg
        gain = array_factor(realized, phase, frequency_hz=frequency_hz)
        links.append({
            "asset_id": asset["id"],
            "target_deg": target_deg,
            "realized_angle_deg": realized,
            "normalized_array_gain": gain,
            "status": "NOMINAL" if gain >= 0.8 else "DEGRADED",
        })
    return {
        "schema": "nexus.communication_state.v1",
        "producer": {"project": "BEAM", "version": "0.1.0"},
        "payload": {"links": links, "frequency_hz": frequency_hz},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tactical", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--frequency-hz", type=float, default=1.0e9)
    args = parser.parse_args()
    write_contract(args.output, build_communication_state(load_contract(args.tactical), args.frequency_hz))
    print(args.output)


if __name__ == "__main__":
    main()
