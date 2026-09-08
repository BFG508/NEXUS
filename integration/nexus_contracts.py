"""Dependency-free validation helpers for NEXUS versioned JSON contracts."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

SCHEMAS: dict[str, tuple[str, ...]] = {
    "nexus.stellar_system.v1": ("system_id", "star", "planets"),
    "nexus.habitability.v1": ("system_id", "targets"),
    "nexus.semantic_culture_profile.v1": ("analysis_language", "comparison", "concepts"),
    "nexus.eden_initialization.v1": ("population_size", "initial_doctrine_fractions", "genome_centers", "mapping_policy"),
    "nexus.society_state.v1": ("generation", "population_size", "doctrine_fractions", "cooperation_rate"),
    "nexus.stochastic_event.v1": ("event_id", "event_type", "severity", "modifiers"),
    "nexus.tactical_state.v1": ("assets",),
    "nexus.communication_state.v1": ("links",),
    "nexus.trajectory_request.v1": ("origin", "target", "constraints"),
}


def load_contract(path: str | Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as handle:
        value = json.load(handle)
    validate_contract(value)
    return value


def validate_contract(value: dict[str, Any], expected_schema: str | None = None) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError("NEXUS contract must be a JSON object")
    schema = value.get("schema")
    if schema not in SCHEMAS:
        raise ValueError(f"Unsupported NEXUS schema: {schema!r}")
    if expected_schema is not None and schema != expected_schema:
        raise ValueError(f"Expected {expected_schema!r}, got {schema!r}")
    producer = value.get("producer")
    if not isinstance(producer, dict) or not producer.get("project") or not producer.get("version"):
        raise ValueError("Contract producer.project and producer.version are required")
    payload = value.get("payload")
    if not isinstance(payload, dict):
        raise ValueError("Contract payload must be a JSON object")
    missing = [field for field in SCHEMAS[schema] if field not in payload]
    if missing:
        raise ValueError(f"{schema} payload missing fields: {missing}")
    return value


def write_contract(path: str | Path, value: dict[str, Any]) -> Path:
    validate_contract(value)
    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return output
