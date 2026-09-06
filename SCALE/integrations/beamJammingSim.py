#!/usr/bin/env python3
"""Generate reproducible stochastic array-element errors for BEAM."""

from __future__ import annotations

import argparse
import json
import math
import os
import random

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
NEXUS_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))
BEAM_OUTPUT = os.path.join(NEXUS_DIR, "BEAM", "integrations", "jamming_profile.json")
LOCAL_OUTPUT = os.path.join(SCRIPT_DIR, "jamming_profile.json")

N_ELEMENTS = 10
SCENARIOS = [
    {"name": "Nominal", "phase_std_deg": 0.0, "amp_std": 0.0},
    {"name": "Light Interference", "phase_std_deg": 5.0, "amp_std": 0.02},
    {"name": "Moderate Jamming", "phase_std_deg": 15.0, "amp_std": 0.05},
    {"name": "Heavy Jamming", "phase_std_deg": 45.0, "amp_std": 0.15},
    {"name": "Catastrophic EW", "phase_std_deg": 90.0, "amp_std": 0.30},
]


def roll_dice(notation: str, rng: random.Random) -> int:
    if "d" not in notation:
        return int(notation)
    count, sides = notation.split("d", 1)
    return sum(rng.randint(1, int(sides)) for _ in range(int(count) if count else 1))


def generate_element_errors(phase_std_deg: float, amp_std: float, rng: random.Random) -> list[dict]:
    errors = []
    for i in range(N_ELEMENTS):
        phase_err = rng.gauss(0.0, phase_std_deg) if phase_std_deg > 0 else 0.0
        amp_err = max(0.0, 1.0 + rng.gauss(0.0, amp_std)) if amp_std > 0 else 1.0
        errors.append({
            "element": i + 1,
            "phase_error_deg": round(phase_err, 3),
            "amplitude_factor": round(amp_err, 4),
        })
    return errors


def compute_degraded_pattern(errors: list[dict], n_angles: int = 721) -> tuple[list[float], list[float]]:
    """Compute broadside ULA array factor over 0..180 degrees."""
    if n_angles < 5:
        raise ValueError("n_angles must be at least 5")
    wavelength = 0.3
    spacing = wavelength / 2.0
    k = 2.0 * math.pi / wavelength
    normalization = sum(row["amplitude_factor"] for row in errors)
    if normalization <= 0:
        normalization = float(N_ELEMENTS)

    angles = [180.0 * i / (n_angles - 1) for i in range(n_angles)]
    pattern: list[float] = []
    for theta_deg in angles:
        theta = math.radians(theta_deg)
        real = 0.0
        imag = 0.0
        for n, err in enumerate(errors):
            psi = k * spacing * n * math.cos(theta) + math.radians(err["phase_error_deg"])
            amp = err["amplitude_factor"]
            real += amp * math.cos(psi)
            imag += amp * math.sin(psi)
        pattern.append(math.hypot(real, imag) / normalization)
    return angles, pattern


def sidelobe_level_db(angles: list[float], pattern: list[float], exclusion_deg: float = 12.5) -> float:
    """Estimate highest local sidelobe, excluding the main-lobe neighbourhood."""
    if len(angles) != len(pattern) or len(pattern) < 3:
        raise ValueError("angles and pattern must have the same length >= 3")
    main_idx = max(range(len(pattern)), key=pattern.__getitem__)
    main_angle = angles[main_idx]
    peak = pattern[main_idx]
    local_maxima = [
        i for i in range(1, len(pattern) - 1)
        if pattern[i] >= pattern[i - 1] and pattern[i] > pattern[i + 1]
        and abs(angles[i] - main_angle) > exclusion_deg
    ]
    if not local_maxima or peak <= 0:
        return -99.0
    side = max(pattern[i] for i in local_maxima)
    if side <= 0:
        return -99.0
    return 20.0 * math.log10(side / peak)


def classify_integrity(peak_gain: float, sll_db: float) -> str:
    if peak_gain >= 0.85 and sll_db <= -10.0:
        return "NOMINAL"
    if peak_gain >= 0.60 and sll_db <= -6.0:
        return "MARGINAL"
    return "DEGRADED"


def generate_profiles(seed: int = 42) -> list[dict]:
    rng = random.Random(seed)
    profiles = []
    for scenario in SCENARIOS:
        intensity_roll = roll_dice("2d6", rng)
        intensity_mod = intensity_roll / 12.0
        adjusted_phase = scenario["phase_std_deg"] * (0.5 + intensity_mod)
        adjusted_amp = scenario["amp_std"] * (0.5 + intensity_mod)
        errors = generate_element_errors(adjusted_phase, adjusted_amp, rng)
        angles, pattern = compute_degraded_pattern(errors)
        peak = max(pattern)
        sll = sidelobe_level_db(angles, pattern)
        profiles.append({
            "scenario": scenario["name"],
            "seed": seed,
            "dice_roll": f"2d6={intensity_roll}",
            "adjusted_phase_std": round(adjusted_phase, 2),
            "adjusted_amp_std": round(adjusted_amp, 4),
            "element_errors": errors,
            "peak_gain": round(peak, 4),
            "sidelobe_level_db": round(sll, 2),
            "pattern_integrity": classify_integrity(peak, sll),
            "angles_deg": [round(v, 3) for v in angles],
            "normalized_pattern": [round(v, 6) for v in pattern],
        })
    return profiles


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    profiles = generate_profiles(args.seed)
    output = BEAM_OUTPUT if os.path.isdir(os.path.dirname(BEAM_OUTPUT)) else LOCAL_OUTPUT
    with open(output, "w", encoding="utf-8") as handle:
        json.dump(profiles, handle, indent=2)
    print(f"[SCALE-BEAM] {len(profiles)} scenarios generated with seed={args.seed}.")
    print(f"[SCALE-BEAM] Profile saved to: {output}")
    for row in profiles:
        print(f"  {row['scenario']:<20} peak={row['peak_gain']:.3f} SLL={row['sidelobe_level_db']:.2f} dB {row['pattern_integrity']}")


if __name__ == "__main__":
    main()
