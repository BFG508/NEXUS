#!/usr/bin/env python3
"""Generate SPARTAN import records for promising GAIA targets."""
from __future__ import annotations
import csv
import os
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
NEXUS_DIR = os.path.dirname(PROJECT_DIR)
GAIA_ASTRA = os.path.join(NEXUS_DIR, "GAIA", "data", "raw", "astra_payload.csv")
GAIA_PROCESSED = os.path.join(NEXUS_DIR, "GAIA", "data", "processed", "clean_exoplanets.csv")
OUTPUT_FILE = os.path.join(PROJECT_DIR, "spartan_import.txt")
STATE_FILES = [
    os.path.join(PROJECT_DIR, "spartan_init.txt"),
    os.path.join(PROJECT_DIR, "spartan_snapshot.txt"),
    OUTPUT_FILE,
]


def approximate_esi(radius_earth: float, temp_k: float) -> float:
    r_ratio = min(radius_earth, 1.0 / radius_earth) if radius_earth > 0 else 0.0
    earth_eq_k = 255.0
    t_ratio = min(temp_k / earth_eq_k, earth_eq_k / temp_k) if temp_k > 0 else 0.0
    return (r_ratio ** 0.57) * (t_ratio ** 1.07)


def _next_gaia_index() -> int:
    largest = 0
    pattern = re.compile(r"G(?:PR|RL)-(\d{5})")
    for path in STATE_FILES:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as handle:
            for line in handle:
                if len(line) >= 20:
                    match = pattern.fullmatch(line[10:20].strip())
                    if match:
                        largest = max(largest, int(match.group(1)))
    return largest + 1


def deploy_probes(csv_path: str, output_path: str = OUTPUT_FILE, esi_threshold: float = 0.6) -> int:
    if not os.path.exists(csv_path):
        raise FileNotFoundError(csv_path)
    records = []
    idx = _next_gaia_index()
    with open(csv_path, "r", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            try:
                radius = float(row.get("pl_rade") or row.get("planet_radius_earth") or 0)
                temp = float(row.get("pl_eqt") or row.get("equilibrium_temp_k") or 0)
            except (TypeError, ValueError):
                continue
            if approximate_esi(radius, temp) < esi_threshold:
                continue
            for prefix, node_type in (("GPR", "PROBE"), ("GRL", "RELAY")):
                node_id = f"{prefix}-{idx:05d}".ljust(10)
                records.append(f"{node_type.ljust(10)}{node_id}10050000\n")
            idx += 1
    if records:
        with open(output_path, "a", encoding="utf-8") as handle:
            handle.writelines(records)
    print(f"[SPARTAN-GAIA] Queued {len(records)} records in {output_path}")
    return len(records)


def main() -> None:
    source = GAIA_ASTRA if os.path.exists(GAIA_ASTRA) else GAIA_PROCESSED
    if not os.path.exists(source):
        raise SystemExit("No GAIA data found. Run ASTRA export or GAIA ETL first.")
    deploy_probes(source)
    print("[SPARTAN-GAIA] Run spartan_import_tool to apply the queue to the indexed DB.")


if __name__ == "__main__":
    main()
