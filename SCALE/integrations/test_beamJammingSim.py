import importlib.util
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("beamJammingSim.py")
spec = importlib.util.spec_from_file_location("beamJammingSim", MODULE_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def test_nominal_uniform_array_has_expected_sidelobe_level():
    profiles = mod.generate_profiles(seed=42)
    nominal = profiles[0]
    assert nominal["peak_gain"] > 0.99
    assert -14.5 < nominal["sidelobe_level_db"] < -12.0
    assert nominal["pattern_integrity"] == "NOMINAL"


def test_profiles_are_reproducible():
    assert mod.generate_profiles(seed=7) == mod.generate_profiles(seed=7)
