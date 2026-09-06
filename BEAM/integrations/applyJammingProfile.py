#!/usr/bin/env python3
"""Consume SCALE's jamming profile and report BEAM pattern degradation."""

from __future__ import annotations

import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROFILE_PATH = os.path.join(SCRIPT_DIR, "jamming_profile.json")


def load_profile(path: str = PROFILE_PATH) -> list[dict]:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError("jamming profile must be a JSON list")
    required = {"scenario", "peak_gain", "sidelobe_level_db", "pattern_integrity"}
    for row in data:
        missing = required.difference(row)
        if missing:
            raise ValueError(f"jamming profile row missing fields: {sorted(missing)}")
    return data


def main() -> None:
    if not os.path.exists(PROFILE_PATH):
        raise SystemExit("No jamming_profile.json found. Run SCALE/integrations/beamJammingSim.py first.")
    rows = load_profile()
    print("[BEAM-SCALE] Jamming profile loaded")
    for row in rows:
        print(
            f"  {row['scenario']:<20} peak={row['peak_gain']:.3f} "
            f"SLL={row['sidelobe_level_db']:.2f} dB  {row['pattern_integrity']}"
        )


if __name__ == "__main__":
    main()
