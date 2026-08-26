"""Reusable numerical core for BEAM."""

from .array import (
    array_factor,
    half_power_beamwidth_deg,
    progressive_phase_shift,
)

__all__ = ["array_factor", "half_power_beamwidth_deg", "progressive_phase_shift"]
