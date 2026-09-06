#!/usr/bin/env python3
"""Dependency-free structural checks for the NEXUS monorepo."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = ("ASTRA", "BEAM", "EDEN", "GAIA", "LEVI", "SCALE", "SPARTAN")
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")


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
        p for p in ROOT.rglob(".gitignore")
        if p != ROOT / ".gitignore" and "_release_assets" not in p.parts
    ]
    if tracked_tree_ignores:
        fail(f"nested .gitignore files found: {tracked_tree_ignores}")

    tracked_tree_licenses = [
        p for p in ROOT.rglob("LICENSE")
        if p != ROOT / "LICENSE" and "_release_assets" not in p.parts
    ]
    if tracked_tree_licenses:
        fail(f"project-level LICENSE files found: {tracked_tree_licenses}")

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
