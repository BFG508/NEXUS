#!/usr/bin/env python3
"""Build an AEGIS input case from NEXUS states using an explicit policy.

The adapter deliberately does not claim that tactical integrity or communication
status is physically equivalent to a component failure rate. The mapping is an
inspectable scenario policy supplied by the caller.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def _load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def build_case(
    tactical: dict[str, Any],
    communication: dict[str, Any],
    policy: dict[str, Any],
) -> str:
    assets = tactical.get("payload", {}).get("assets", [])
    links = communication.get("payload", {}).get("links", [])
    link_by_asset = {link.get("asset_id"): link for link in links}

    if not assets:
        raise ValueError("tactical state contains no assets")

    rates = policy["asset_failure_rate_per_hour"]
    integrity_factor = float(policy["integrity_loss_rate_multiplier_per_percent"])
    degraded_factor = float(policy["communication_degraded_multiplier"])
    failed_factor = float(policy["communication_failed_multiplier"])
    repair_rate = float(policy["repair_rate_per_hour"])

    lines = [
        f'name = "{_toml_string(policy["policy_id"])}"',
        f'mission_hours = {float(policy["mission_hours"]):.17g}',
        f'architecture = "{_toml_string(policy["architecture"])}"',
        f'monte_carlo_runs = {int(policy["monte_carlo_runs"])}',
        f'seed = {int(policy["seed"])}',
        "",
    ]

    for asset in assets:
        asset_id = str(asset["id"])
        asset_type = str(asset.get("type", "default"))
        integrity = float(asset.get("integrity", 100.0))
        base_rate = float(rates.get(asset_type, rates["default"]))
        multiplier = 1.0 + max(0.0, 100.0 - integrity) * integrity_factor

        link = link_by_asset.get(asset_id)
        if link is not None:
            status = str(link.get("status", "NOMINAL")).upper()
            if status == "DEGRADED":
                multiplier *= degraded_factor
            elif status == "FAILED":
                multiplier *= failed_factor

        failure_rate = base_rate * multiplier
        lines.extend(
            [
                "[[components]]",
                f'id = "{_toml_string(asset_id)}"',
                'distribution = "exponential"',
                f'failure_rate_per_hour = {failure_rate:.17g}',
                f'repair_rate_per_hour = {repair_rate:.17g}',
                "",
            ]
        )

    return "\n".join(lines)


def _toml_string(value: object) -> str:
    return str(value).replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("tactical", type=Path)
    parser.add_argument("communication", type=Path)
    parser.add_argument("policy", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    text = build_case(_load(args.tactical), _load(args.communication), _load(args.policy))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(args.output)


if __name__ == "__main__":
    main()
