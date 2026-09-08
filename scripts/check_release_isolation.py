#!/usr/bin/env python3
"""Verify that generated release ZIPs contain only one project tree."""
from __future__ import annotations

import argparse
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILT = ROOT / "_release_assets" / "built"
FORBIDDEN_PARTS = {"integration", "integrations", ".git"}


def check(path: Path) -> None:
    with zipfile.ZipFile(path) as archive:
        names = [Path(name) for name in archive.namelist() if not name.endswith("/")]
        if not names:
            raise SystemExit(f"[FAIL] empty archive: {path}")
        top = {name.parts[0] for name in names if name.parts}
        if len(top) != 1:
            raise SystemExit(f"[FAIL] {path.name}: expected one top-level project directory, got {sorted(top)}")
        for name in names:
            lowered = {part.lower() for part in name.parts}
            bad = lowered & FORBIDDEN_PARTS
            if bad:
                raise SystemExit(f"[FAIL] {path.name}: integration/repository metadata leaked into {name}")
    print(f"[OK] {path.name}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archives", nargs="*", type=Path)
    args = parser.parse_args()
    archives = args.archives or sorted(BUILT.glob("*.zip"))
    if not archives:
        raise SystemExit("No release ZIPs found; run build_release_assets.py first")
    for archive in archives:
        check(archive)


if __name__ == "__main__":
    main()
