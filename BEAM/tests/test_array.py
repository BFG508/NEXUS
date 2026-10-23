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


@pytest.mark.parametrize("frequency", [0.0, -1.0, math.nan, math.inf])
def test_all_equations_reject_invalid_frequency(frequency):
    for equation in (
        lambda: progressive_phase_shift(90.0, frequency_hz=frequency),
        lambda: array_factor(90.0, 0.0, frequency_hz=frequency),
        lambda: half_power_beamwidth_deg(frequency_hz=frequency),
    ):
        with pytest.raises(ValueError):
            equation()


@pytest.mark.parametrize("spacing", [0.0, -1.0, math.nan, math.inf])
def test_all_equations_reject_invalid_spacing(spacing):
    for equation in (
        lambda: progressive_phase_shift(90.0, spacing_m=spacing),
        lambda: array_factor(90.0, 0.0, spacing_m=spacing),
        lambda: half_power_beamwidth_deg(spacing_m=spacing),
    ):
        with pytest.raises(ValueError):
            equation()


@pytest.mark.parametrize("count", [0, -1, 1.5, True])
def test_invalid_element_counts_are_rejected(count):
    with pytest.raises(ValueError):
        array_factor(90.0, 0.0, n_elements=count)
    with pytest.raises(ValueError):
        half_power_beamwidth_deg(n_elements=count)


def test_nonfinite_angles_are_rejected():
    for value in (math.nan, math.inf, -math.inf):
        with pytest.raises(ValueError):
            progressive_phase_shift(value)
        with pytest.raises(ValueError):
            array_factor(value, 0.0)
        with pytest.raises(ValueError):
            array_factor(90.0, value)
