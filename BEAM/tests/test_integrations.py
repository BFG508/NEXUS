import json
from pathlib import Path

from integrations.applyJammingProfile import load_profile
from integrations.gaiaSetiScanner import _positive_float


def test_jamming_profile_validation(tmp_path: Path):
    path = tmp_path / "profile.json"
    path.write_text(json.dumps([{
        "scenario": "Nominal",
        "peak_gain": 1.0,
        "sidelobe_level_db": -13.0,
        "pattern_integrity": "NOMINAL",
    }]))
    assert load_profile(str(path))[0]["scenario"] == "Nominal"


def test_gaia_seti_scanner_never_synthesizes_missing_distance():
    assert _positive_float({}, "distance_parsecs", "sy_dist") is None
    assert _positive_float({"distance_parsecs": ""}, "distance_parsecs") is None
    assert _positive_float({"sy_dist": "12.5"}, "distance_parsecs", "sy_dist") == 12.5
