#!/usr/bin/env python3
"""Dependency-free structural checks for the NEXUS monorepo."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = ("ASTRA", "BEAM", "EDEN", "ETHOS", "GAIA", "LEVI", "SCALE", "SPARTAN")
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")


def tracked_files_named(filename: str) -> list[Path]:
    """Return tracked files with *filename*, ignoring generated/untracked caches."""
    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files", "-z"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        paths = [
            ROOT / Path(raw.decode("utf-8"))
            for raw in result.stdout.split(b"\0")
            if raw
        ]
        return [path for path in paths if path.name == filename]
    except (FileNotFoundError, subprocess.CalledProcessError, UnicodeDecodeError):
        ignored_parts = {
            ".git", ".pytest_cache", "__pycache__", ".venv", "venv",
            "_release_assets", "_local_assets", "target", "renv", ".julia",
        }
        return [
            path for path in ROOT.rglob(filename)
            if not any(part in ignored_parts for part in path.relative_to(ROOT).parts)
        ]


def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)


def main() -> None:
    for required in ("README.md", "LICENSE", ".gitignore"):
        if not (ROOT / required).is_file():
            fail(f"repository: missing {required}")

    for project in PROJECTS:
        base = ROOT / project
        for required in ("README.md", "VERSION"):
            if not (base / required).is_file():
                fail(f"{project}: missing {required}")
        for forbidden in ("LICENSE", ".gitignore"):
            if (base / forbidden).exists():
                fail(f"{project}: project-level {forbidden} must not exist")

        version = (base / "VERSION").read_text(encoding="utf-8").strip()
        if not SEMVER.fullmatch(version):
            fail(f"{project}: VERSION is not SemVer: {version!r}")
        readme = (base / "README.md").read_text(encoding="utf-8")
        if readme.count("```") % 2:
            fail(f"{project}: unbalanced Markdown code fences")

    nested_git = [p for p in ROOT.rglob(".git") if p != ROOT / ".git"]
    if nested_git:
        fail(f"nested .git metadata found: {nested_git}")

    tracked_tree_ignores = [
        p for p in tracked_files_named(".gitignore")
        if p != ROOT / ".gitignore"
    ]
    if tracked_tree_ignores:
        fail(f"tracked nested .gitignore files found: {tracked_tree_ignores}")

    tracked_tree_licenses = [
        p for p in tracked_files_named("LICENSE")
        if p != ROOT / "LICENSE"
    ]
    if tracked_tree_licenses:
        fail(f"tracked project-level LICENSE files found: {tracked_tree_licenses}")

    integration_root = ROOT / "integration"
    for required in ("README.md", "nexus_contracts.py", "contracts", "adapters", "tests"):
        if not (integration_root / required).exists():
            fail(f"integration: missing {required}")

    for project in PROJECTS:
        for forbidden_dir in ("integration", "integrations"):
            if (ROOT / project / forbidden_dir).exists():
                fail(f"{project}: project-local {forbidden_dir}/ must live under repository integration/")

    required_schemas = {
        "stellar_system.v1.schema.json", "habitability.v1.schema.json",
        "semantic_culture_profile.v1.schema.json", "eden_initialization.v1.schema.json",
        "society_state.v1.schema.json", "stochastic_event.v1.schema.json",
        "tactical_state.v1.schema.json", "communication_state.v1.schema.json",
        "trajectory_request.v1.schema.json",
    }
    found_schemas = {p.name for p in (integration_root / "contracts").glob("*.schema.json")}
    if required_schemas != found_schemas:
        fail(f"integration schema set mismatch: expected {sorted(required_schemas)}, got {sorted(found_schemas)}")

    for path in ROOT.rglob("*.json"):
        if "_release_assets" in path.parts or "_local_assets" in path.parts:
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            fail(f"invalid JSON {path.relative_to(ROOT)}: {exc}")

    if "SPARKLE" in (ROOT / ".gitignore").read_text(encoding="utf-8"):
        fail("root .gitignore still identifies the repository as SPARKLE")

    print("[OK] NEXUS structural preflight passed")
    for project in PROJECTS:
        version = (ROOT / project / "VERSION").read_text(encoding="utf-8").strip()
        print(f"  {project:<8} {version}")


if __name__ == "__main__":
    main()
