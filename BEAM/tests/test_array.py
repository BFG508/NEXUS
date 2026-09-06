import math

import pytest

from beam.array import array_factor, half_power_beamwidth_deg, progressive_phase_shift


def test_commanded_direction_is_array_peak():
    theta = 70.0
    phase = progressive_phase_shift(theta)
    assert array_factor(theta, phase) == pytest.approx(1.0, abs=1e-10)


def test_pointing_error_reduces_gain():
    target = 90.0
    phase = progressive_phase_shift(105.0)
    assert array_factor(target, phase) < 0.5


def test_beamwidth_and_input_validation():
    assert 5.0 < half_power_beamwidth_deg() < 20.0
    with pytest.raises(ValueError):
        progressive_phase_shift(90.0, frequency_hz=0)
    with pytest.raises(ValueError):
        array_factor(90.0, 0.0, n_elements=0)
