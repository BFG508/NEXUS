#!/usr/bin/env python3
"""Exploratory SETI detectability proxy using GAIA catalog distances.

The adapter deliberately refuses to invent distances: rows without a positive
catalog distance are skipped.  The calculation is a toy radiometric proxy for
NEXUS integration testing, not a validated SETI sensitivity analysis.
"""

import csv
import json
import math
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SIDE_PROJECTS = os.path.dirname(os.path.dirname(SCRIPT_DIR))
GAIA_CSV = os.path.join(SIDE_PROJECTS, "GAIA", "data", "raw", "astra_payload.csv")
GAIA_PROC = os.path.join(
    SIDE_PROJECTS, "GAIA", "data", "processed", "clean_exoplanets.csv"
)
OUTPUT = os.path.join(SCRIPT_DIR, "seti_report.json")

FREQ = 1e9
C = 3e8
LAM = C / FREQ
D = LAM / 2
N = 10
K_B = 1.38e-23
T_SYS = 50
BW = 1e6
T_INT = 3600


def s_min(snr=5.0):
    """Return an exploratory flux-density threshold for the toy array model."""
    aperture_length = 2 * N * D / LAM
    a_eff = aperture_length * LAM**2 / (4 * math.pi)
    return snr * K_B * T_SYS / (a_eff * math.sqrt(BW * T_INT))


def flux(distance_pc, p_w=1e12):
    """Isotropic narrow-band flux-density proxy at ``distance_pc``."""
    d_m = distance_pc * 3.0857e16
    return p_w / (4 * math.pi * d_m**2 * BW) if d_m > 0 else 0.0


def _positive_float(row, *keys):
    for key in keys:
        value = row.get(key)
        if value in (None, ""):
            continue
        try:
            number = float(value)
        except (TypeError, ValueError):
            continue
        if math.isfinite(number) and number > 0:
            return number
    return None


def main():
    csv_path = GAIA_CSV if os.path.exists(GAIA_CSV) else GAIA_PROC
    if not os.path.exists(csv_path):
        print("[BEAM-GAIA] No GAIA data found.")
        return

    threshold = s_min()
    results = []
    skipped_no_distance = 0

    with open(csv_path, "r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            name = row.get("pl_name") or row.get("planet_name") or "?"
            temp = _positive_float(row, "pl_eqt", "equilibrium_temp_k")
            distance_pc = _positive_float(row, "distance_parsecs", "sy_dist")

            if temp is None or not 250 <= temp <= 350:
                continue
            if distance_pc is None:
                skipped_no_distance += 1
                continue

            signal = flux(distance_pc)
            snr = signal / (threshold / 5.0) if threshold > 0 else 0.0
            results.append(
                {
                    "planet": name,
                    "temp_k": temp,
                    "distance_pc": round(distance_pc, 3),
                    "snr_proxy": round(snr, 3),
                    "detectable_proxy": snr >= 5,
                    "status": "ABOVE PROXY THRESHOLD" if snr >= 5 else "BELOW PROXY THRESHOLD",
                }
            )

    if not results:
        print(
            "[BEAM-GAIA] No rows had both the selected temperature range "
            "and a measured positive distance."
        )
        return

    with open(OUTPUT, "w", encoding="utf-8") as handle:
        json.dump(results, handle, indent=2)
        handle.write("\n")

    detected = sum(1 for result in results if result["detectable_proxy"])
    print(
        f"[BEAM-GAIA] {detected}/{len(results)} above proxy threshold; "
        f"skipped {skipped_no_distance} rows without catalog distance. "
        f"Report: {OUTPUT}"
    )


if __name__ == "__main__":
    main()
