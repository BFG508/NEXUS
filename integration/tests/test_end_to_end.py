import csv
import json
from pathlib import Path

from nexus_contracts import load_contract, validate_contract
from ethos_to_eden import build_initialization
from eden_initialization_to_config import convert as initialization_to_config
from apply_scale_event import apply_event
from beam_from_tactical import build_communication_state
from build_levi_request import build_request
from stellar_to_gaia_csv import convert
from spartan_snapshot_to_contract import parse_snapshot

BASE = Path(__file__).resolve().parents[1]
FIXTURES = BASE / "fixtures"
POLICY = BASE / "policies" / "ethos_to_eden.example.json"


def test_semantic_profile_to_eden_initialization():
    profile = load_contract(FIXTURES / "semantic_profile.json")
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    result = build_initialization(profile, policy, population_size=240)
    validate_contract(result, "nexus.eden_initialization.v1")
    fractions = result["payload"]["initial_doctrine_fractions"]
    assert result["payload"]["population_size"] == 240
    assert abs(sum(fractions.values()) - 1.0) < 1e-12
    assert result["payload"]["mapping_policy"]["policy_id"] == policy["policy_id"]


def test_scale_spartan_beam_levi_contract_chain_uses_project_core():
    tactical = load_contract(FIXTURES / "tactical_state.json")
    event = load_contract(FIXTURES / "stochastic_event.json")
    updated = apply_event(tactical, event)
    validate_contract(updated, "nexus.tactical_state.v1")
    a1 = next(asset for asset in updated["payload"]["assets"] if asset["id"] == "A-001")
    assert a1["integrity"] == 75
    assert a1["delta_v"] == 480

    communication = build_communication_state(updated)
    validate_contract(communication, "nexus.communication_state.v1")
    assert len(communication["payload"]["links"]) == 2
    assert communication["payload"]["links"][0]["normalized_array_gain"] == 1.0
    assert communication["payload"]["links"][1]["normalized_array_gain"] < 1.0

    stellar = load_contract(FIXTURES / "stellar_system.json")
    request = build_request(stellar, communication)
    validate_contract(request, "nexus.trajectory_request.v1")
    assert request["payload"]["origin"]["id"] == "fixture-b"
    assert request["payload"]["target"]["id"] == "fixture-c"


def test_stellar_contract_translates_to_gaia_etl_columns(tmp_path):
    output = tmp_path / "gaia.csv"
    convert(FIXTURES / "stellar_system.json", output)
    with output.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    assert len(rows) == 2
    assert rows[0]["pl_name"] == "fixture-b"
    assert rows[0]["st_mass"] == "1.0"
    assert rows[0]["discoverymethod"] == "ASTRA simulation"


def test_spartan_snapshot_adapter_preserves_fixed_width_state(tmp_path):
    snapshot = tmp_path / "snapshot.txt"
    # 10-char type + 10-char ID + 3-char integrity + 5-char delta-v
    snapshot.write_text(f"{'SCOUT':<10}{'A-001':<10}{90:03d}{500:05d}\n", encoding="utf-8")
    result = parse_snapshot(snapshot)
    validate_contract(result, "nexus.tactical_state.v1")
    assert result["payload"]["assets"] == [{"type": "SCOUT", "id": "A-001", "integrity": 90, "delta_v": 500}]


def test_eden_initialization_translates_to_generic_runner_config(tmp_path):
    profile = load_contract(FIXTURES / "semantic_profile.json")
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    initialization = build_initialization(profile, policy, population_size=120)
    output = tmp_path / "eden.toml"
    initialization_to_config(initialization, output, generations=25, seed=9)
    text = output.read_text(encoding="utf-8")
    assert "population_size = 120" in text
    assert "generations = 25" in text
    assert "seed = 9" in text
    assert "[initial_doctrine_fractions]" in text
