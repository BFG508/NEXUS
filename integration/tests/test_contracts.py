import json
from pathlib import Path

import pytest

from nexus_contracts import load_contract, validate_contract

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"


def test_all_contract_schemas_have_valid_json_and_identity():
    contracts = Path(__file__).resolve().parents[1] / "contracts"
    for path in contracts.glob("*.schema.json"):
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data["title"].startswith("nexus.")
        assert data["properties"]["schema"]["const"] == data["title"]


def test_fixture_contracts_validate():
    for name in ("stellar_system.json", "semantic_profile.json", "stochastic_event.json", "tactical_state.json"):
        validate_contract(load_contract(FIXTURES / name))


def test_invalid_contract_is_rejected():
    with pytest.raises(ValueError):
        validate_contract({"schema": "nexus.tactical_state.v1", "producer": {}, "payload": {}})
