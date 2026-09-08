#!/usr/bin/env python3
"""Build isolated per-project GitHub release archives for NEXUS.

Current releases are assembled only from the selected project directory plus the
repository-level MIT LICENSE. Cross-project code under ``integration/`` is never
included. Historical EDEN/ETHOS artifacts are copied from preserved snapshots.
"""
from __future__ import annotations

import argparse
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "_release_assets" / "built"
PROJECTS = ("ASTRA", "BEAM", "EDEN", "ETHOS", "GAIA", "LEVI", "SCALE", "SPARTAN")
SKIP_PARTS = {
    ".git", ".github", ".venv", "__pycache__", ".pytest_cache", "target", ".metals",
    ".bsp", ".scala-build", ".Rproj.user", "library", "staging", "exports",
    "integration", "integrations",
}
SKIP_NAMES = {
    ".gitignore", "LICENSE",
    "spartan_init.txt", "spartan_import.txt", "spartan_snapshot.txt",
    "spartan_tactical.dat", "steering_schedule.json", "jamming_profile.json",
    "combat_log.json", "nasa_exoplanets.csv", "Manifest.toml",
}

EDEN_HISTORY = {
    "0.1.0": ROOT / "_release_assets" / "EDEN" / "EDEN-v0.1.0-Stable-Prototype.zip",
    "0.2.0": ROOT / "_release_assets" / "EDEN" / "EDEN-v0.2.0-Research-Prototype.zip",
}
ETHOS_HISTORY = {
    "semanticlogos-0.1.0": ROOT / "_release_assets" / "ETHOS" / "SemanticLogos-v0.1.0.zip",
    "0.1.1": ROOT / "_release_assets" / "ETHOS" / "ETHOS-v0.1.1.zip",
    "0.2.0": ROOT / "_release_assets" / "ETHOS" / "ETHOS-v0.2.0.zip",
    "1.0.0": ROOT / "_release_assets" / "ETHOS" / "ETHOS-v1.0.0.zip",
}


def version_of(project: str) -> str:
    text = (ROOT / project / "VERSION").read_text(encoding="utf-8").strip()
    if not text:
        raise ValueError(f"Empty VERSION for {project}")
    return text


def should_skip(path: Path, project_dir: Path) -> bool:
    rel = path.relative_to(project_dir)
    if any(part in SKIP_PARTS for part in rel.parts):
        return True
    if path.name in SKIP_NAMES:
        return True
    if path.suffix in {".pyc", ".class", ".o", ".obj"}:
        return True
    if "results" in rel.parts and path.name not in {".gitkeep", "README.md"}:
        return True
    return False


def build_current(project: str) -> Path:
    version = version_of(project)
    source = ROOT / project
    output = OUTPUT / f"{project}-v{version}.zip"
    OUTPUT.mkdir(parents=True, exist_ok=True)
    prefix = f"{project}-v{version}"
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(source.rglob("*")):
            if not path.is_file() or should_skip(path, source):
                continue
            archive.write(path, Path(prefix) / path.relative_to(source))
        archive.write(ROOT / "LICENSE", Path(prefix) / "LICENSE")
    return output


def _copy_historical(source: Path) -> Path:
    if not source.is_file():
        raise FileNotFoundError(f"Missing historical release asset: {source}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    output = OUTPUT / source.name
    shutil.copy2(source, output)
    return output


def build_eden_historical(version: str) -> Path:
    return _copy_historical(EDEN_HISTORY[version])


def build_ethos_historical(version: str) -> Path:
    return _copy_historical(ETHOS_HISTORY[version])


def build_all() -> list[Path]:
    outputs = [build_current(project) for project in PROJECTS]
    outputs.extend(build_eden_historical(version) for version in EDEN_HISTORY)
    outputs.extend(build_ethos_historical(version) for version in ETHOS_HISTORY)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("project", choices=[*PROJECTS, "all"])
    parser.add_argument("--eden-historical", choices=sorted(EDEN_HISTORY))
    parser.add_argument("--ethos-historical", choices=sorted(ETHOS_HISTORY))
    args = parser.parse_args()

    if args.project == "all":
        outputs = build_all()
    elif args.project == "EDEN" and args.eden_historical:
        outputs = [build_eden_historical(args.eden_historical)]
    elif args.project == "ETHOS" and args.ethos_historical:
        outputs = [build_ethos_historical(args.ethos_historical)]
    elif args.eden_historical or args.ethos_historical:
        parser.error("Historical options must match the selected project")
    else:
        outputs = [build_current(args.project)]

    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
