#!/usr/bin/env python3
"""Translate a stellar-system contract into GAIA's documented ETL columns."""
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import sys

HERE = Path(__file__).resolve()
NEXUS = HERE.parents[2]
sys.path.insert(0, str(NEXUS / "integration"))
from nexus_contracts import load_contract  # noqa: E402


def convert(contract_path: Path, output: Path) -> Path:
    value = load_contract(contract_path)
    if value["schema"] != "nexus.stellar_system.v1":
        raise ValueError("Expected nexus.stellar_system.v1")
    payload = value["payload"]
    star = payload["star"]
    output.parent.mkdir(parents=True, exist_ok=True)
    fields = ["pl_name", "pl_rade", "pl_bmasse", "pl_eqt", "pl_orbper", "hostname", "st_teff", "st_mass", "st_rad", "discoverymethod", "disc_year", "sy_dist"]
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for planet in payload["planets"]:
            writer.writerow({
                "pl_name": planet["id"],
                "pl_rade": planet["radius_earth"],
                "pl_bmasse": planet["mass_earth"],
                "pl_eqt": planet["equilibrium_temp_k"],
                "pl_orbper": planet.get("orbital_period_days", ""),
                "hostname": star.get("name", payload["system_id"]),
                "st_teff": star["temperature_k"],
                "st_mass": star["mass_solar"],
                "st_rad": star["radius_solar"],
                "discoverymethod": "ASTRA simulation",
                "disc_year": "",
                "sy_dist": "",
            })
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("contract", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    print(convert(args.contract, args.output))


if __name__ == "__main__":
    main()
