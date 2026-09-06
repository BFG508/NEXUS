#!/usr/bin/env python3
"""Generate a reproducible BEAM steering schedule from a SPARTAN snapshot.

The target line-of-sight angle and the commanded steering angle are deliberately
separate. A pointing-error model therefore produces non-trivial link-quality
results instead of evaluating the array exactly at its own commanded peak.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
NEXUS_DIR = os.path.dirname(PROJECT_DIR)
if PROJECT_DIR not in sys.path:
    sys.path.insert(0, PROJECT_DIR)

from beam.array import array_factor, half_power_beamwidth_deg, progressive_phase_shift

SPARTAN_DIR = os.path.join(NEXUS_DIR, "SPARTAN")
SPARTAN_SNAPSHOT = os.path.join(SPARTAN_DIR, "spartan_snapshot.txt")
SPARTAN_BOOTSTRAP = os.path.join(SPARTAN_DIR, "spartan_init.txt")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "steering_schedule.json")


def _fleet_source() -> str | None:
    if os.path.exists(SPARTAN_SNAPSHOT):
        return SPARTAN_SNAPSHOT
    if os.path.exists(SPARTAN_BOOTSTRAP):
        return SPARTAN_BOOTSTRAP
    return None


def _read_assets(path: str) -> list[dict[str, object]]:
    assets: list[dict[str, object]] = []
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if len(line) < 28:
                continue
            try:
                integrity = int(line[20:23])
            except ValueError:
                continue
            assets.append(
                {
                    "type": line[0:10].strip(),
                    "id": line[10:20].strip(),
                    "integrity": integrity,
                }
            )
    return assets


def classify_link(gain: float) -> str:
    if gain >= 0.90:
        return "NOMINAL"
    if gain >= 0.60:
        return "MARGINAL"
    return "DEGRADED"


def generate_steering_schedule(seed: int = 42, pointing_sigma_deg: float = 4.0) -> list[dict[str, object]]:
    source = _fleet_source()
    if source is None:
        raise FileNotFoundError(
            "No SPARTAN snapshot/bootstrap found. Generate SPARTAN data first."
        )
    assets = _read_assets(source)
    if not assets:
        raise ValueError(f"No valid SPARTAN records found in {source}")

    rng = random.Random(seed)
    beamwidth = round(half_power_beamwidth_deg(), 2)
    schedule: list[dict[str, object]] = []

    for asset in assets:
        target_deg = rng.uniform(15.0, 165.0)
        pointing_error_deg = rng.gauss(0.0, pointing_sigma_deg)
        commanded_deg = max(5.0, min(175.0, target_deg + pointing_error_deg))
        phase = progressive_phase_shift(commanded_deg)
        gain = array_factor(target_deg, phase)

        schedule.append(
            {
                "asset_id": asset["id"],
                "asset_type": asset["type"],
                "target_angle_deg": round(target_deg, 2),
                "commanded_angle_deg": round(commanded_deg, 2),
                "pointing_error_deg": round(commanded_deg - target_deg, 2),
                "phase_shift_rad": round(phase, 6),
                "gain_at_target": round(gain, 4),
                "beamwidth_deg": beamwidth,
                "link_quality": classify_link(gain),
            }
        )

    with open(OUTPUT_FILE, "w", encoding="utf-8") as handle:
        json.dump(schedule, handle, indent=2)

    counts = {quality: sum(1 for row in schedule if row["link_quality"] == quality)
              for quality in ("NOMINAL", "MARGINAL", "DEGRADED")}
    print(f"[BEAM-SPARTAN] Source: {source}")
    print(f"[BEAM-SPARTAN] Seed={seed}, pointing sigma={pointing_sigma_deg:.2f} deg")
    print(f"[BEAM-SPARTAN] {len(schedule)} assets: {counts}")
    print(f"[BEAM-SPARTAN] Schedule saved to: {OUTPUT_FILE}")
    return schedule


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--pointing-sigma-deg", type=float, default=4.0)
    args = parser.parse_args()
    if args.pointing_sigma_deg < 0:
        parser.error("--pointing-sigma-deg must be non-negative")
    generate_steering_schedule(args.seed, args.pointing_sigma_deg)


if __name__ == "__main__":
    main()
