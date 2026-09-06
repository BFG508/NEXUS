#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════
#  spartanCombatSim.py — Run stochastic combat events on SPARTAN fleet
# ══════════════════════════════════════════════════════════════════════
#
#  Reads the SPARTAN init file, simulates dice-based combat events
#  (solar flares, asteroid impacts, boarding actions) using SCALE-like
#  stochastic mechanics, and writes back the damaged/repaired fleet.
#
#  Usage:
#      python integrations/spartanCombatSim.py
# ══════════════════════════════════════════════════════════════════════

import argparse
import json
import os
import random

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
SIDE_PROJECTS_DIR = os.path.dirname(PROJECT_DIR)

SPARTAN_INIT = os.path.join(SIDE_PROJECTS_DIR, "SPARTAN", "spartan_init.txt")
SPARTAN_SNAPSHOT = os.path.join(SIDE_PROJECTS_DIR, "SPARTAN", "spartan_snapshot.txt")
SPARTAN_IMPORT = os.path.join(SIDE_PROJECTS_DIR, "SPARTAN", "spartan_import.txt")
COMBAT_LOG = os.path.join(PROJECT_DIR, "integrations", "combat_log.json")


def roll_dice(notation):
    """
    Minimal dice roller supporting NdM notation.
    Example: '2d6' rolls 2 six-sided dice.
    """
    if "d" not in notation:
        return int(notation)
    count, sides = notation.split("d")
    count = int(count) if count else 1
    sides = int(sides)
    return sum(random.randint(1, sides) for _ in range(count))


def simulate_event():
    """Generate a random tactical event with dice-based damage/repair."""
    events = [
        {"name": "Solar Flare",        "damage": "2d6",  "repair": "0"},
        {"name": "Asteroid Impact",    "damage": "3d8",  "repair": "0"},
        {"name": "Boarding Action",    "damage": "4d6",  "repair": "0"},
        {"name": "Supply Run",         "damage": "0",    "repair": "1d6"},
        {"name": "Engineering Refit",  "damage": "0",    "repair": "2d4"},
        {"name": "Cosmic Ray Burst",   "damage": "1d10", "repair": "0"},
        {"name": "Nominal Operations", "damage": "0",    "repair": "0"},
    ]
    return random.choice(events)


def run_combat_simulation(seed=42):
    """Process the SPARTAN fleet through a reproducible round of stochastic events."""
    random.seed(seed)
    source = SPARTAN_SNAPSHOT if os.path.exists(SPARTAN_SNAPSHOT) else SPARTAN_INIT
    if not os.path.exists(source):
        print("[SCALE-SPARTAN] No SPARTAN snapshot/bootstrap found.")
        return

    # Read all fleet records
    records = []
    with open(source, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if len(line) < 28:
                continue
            node_type = line[0:10]
            node_id = line[10:20]
            integrity = int(line[20:23])
            delta_v = int(line[23:28])
            records.append({
                "type": node_type,
                "id": node_id,
                "integrity": integrity,
                "delta_v": delta_v,
            })

    if not records:
        print("[SCALE-SPARTAN] No valid records found.")
        return

    # Run combat events
    combat_log = []
    for rec in records:
        event = simulate_event()
        damage = roll_dice(event["damage"])
        repair = roll_dice(event["repair"])

        old_integrity = rec["integrity"]
        rec["integrity"] = max(0, min(100, rec["integrity"] - damage + repair))

        # Delta-V cost for evasive maneuvers
        if damage > 0:
            dv_cost = damage * 25
            rec["delta_v"] = max(0, rec["delta_v"] - dv_cost)

        combat_log.append({
            "asset": rec["id"].strip(),
            "event": event["name"],
            "damage": damage,
            "repair": repair,
            "integrity_before": old_integrity,
            "integrity_after": rec["integrity"],
        })

    # Queue updated fleet for SPARTAN import; do not mutate bootstrap/live DB directly.
    with open(SPARTAN_IMPORT, "a", encoding="utf-8") as f:
        for rec in records:
            node_type = rec["type"][:10].ljust(10)
            node_id = rec["id"][:10].ljust(10)
            integrity = f"{rec['integrity']:03d}"
            delta_v = f"{rec['delta_v']:05d}"
            f.write(f"{node_type}{node_id}{integrity}{delta_v}\n")

    # Save combat log as JSON
    with open(COMBAT_LOG, "w", encoding="utf-8") as f:
        json.dump(combat_log, f, indent=4)

    destroyed = sum(1 for r in records if r["integrity"] == 0)
    print(f"[SCALE-SPARTAN] Combat simulation complete.")
    print(f"[SCALE-SPARTAN] {len(records)} assets processed, "
          f"{destroyed} destroyed.")
    print(f"[SCALE-SPARTAN] Updates queued in: {SPARTAN_IMPORT}")
    print(f"[SCALE-SPARTAN] Combat log saved to: {COMBAT_LOG}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    run_combat_simulation(args.seed)
