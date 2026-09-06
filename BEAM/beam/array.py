"""Core uniform-linear-array equations used by BEAM integrations.

The functions intentionally model only the array factor of an ideal uniform
linear array. Element patterns, mutual coupling and RF link budgets are outside
this module and must not be inferred from the returned array factor alone.
"""

from __future__ import annotations

import math

C_M_S = 299_792_458.0


def progressive_phase_shift(
    theta_deg: float,
    *,
    frequency_hz: float = 1.0e9,
    spacing_m: float | None = None,
) -> float:
    """Return progressive phase shift [rad] for steering toward ``theta_deg``."""
    if frequency_hz <= 0:
        raise ValueError("frequency_hz must be positive")
    wavelength = C_M_S / frequency_hz
    spacing = wavelength / 2.0 if spacing_m is None else spacing_m
    if spacing <= 0:
        raise ValueError("spacing_m must be positive")
    k = 2.0 * math.pi / wavelength
    return -k * spacing * math.cos(math.radians(theta_deg))


def array_factor(
    theta_deg: float,
    phase_shift_rad: float,
    *,
    n_elements: int = 10,
    frequency_hz: float = 1.0e9,
    spacing_m: float | None = None,
) -> float:
    """Return normalized magnitude of the ideal uniform-linear-array factor."""
    if n_elements < 1:
        raise ValueError("n_elements must be at least 1")
    if frequency_hz <= 0:
        raise ValueError("frequency_hz must be positive")
    wavelength = C_M_S / frequency_hz
    spacing = wavelength / 2.0 if spacing_m is None else spacing_m
    if spacing <= 0:
        raise ValueError("spacing_m must be positive")

    k = 2.0 * math.pi / wavelength
    psi = k * spacing * math.cos(math.radians(theta_deg)) + phase_shift_rad
    denom = math.sin(psi / 2.0)
    if abs(denom) < 1e-12:
        return 1.0
    value = math.sin(n_elements * psi / 2.0) / (n_elements * denom)
    return min(1.0, abs(value))


def half_power_beamwidth_deg(
    *,
    n_elements: int = 10,
    frequency_hz: float = 1.0e9,
    spacing_m: float | None = None,
) -> float:
    """Broadside HPBW approximation for a uniform linear array [deg]."""
    if n_elements < 2:
        return 180.0
    wavelength = C_M_S / frequency_hz
    spacing = wavelength / 2.0 if spacing_m is None else spacing_m
    ratio = 0.886 * wavelength / (n_elements * spacing)
    return math.degrees(min(math.pi, ratio))
