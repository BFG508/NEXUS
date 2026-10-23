#!/usr/bin/env python3
"""Build isolated per-project GitHub release archives for NEXUS.

Current releases are assembled only from the selected project directory plus the
repository-level MIT LICENSE. Cross-project code under ``integration/`` is never
included. Built assets contain only current releases, grouped by project.
Historical EDEN/ETHOS archives are preserved separately and selected explicitly.
"""
from __future__ import annotations

import argparse
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "_release_assets" / "built"
HISTORICAL = ROOT / "_release_assets" / "historical"
PROJECTS = ("AEGIS", "ASTRA", "ATLAS", "BEAM", "EDEN", "ETHOS", "GAIA", "HERMES", "LEVI", "SCALE", "SPARTAN")
SKIP_PARTS = {
    ".awx", ".aws", ".agent", ".agents", ".agentws", ".codex",
    ".claude", ".cursor", ".gemini", ".windsurf", ".opencode", ".continue",
    ".git", ".github", ".venv", "__pycache__", ".pytest_cache", "target", ".metals",
    ".bsp", ".scala-build", ".build", ".swiftpm", "xcuserdata", "DerivedData",
    ".Rproj.user", "library", "staging", "exports",
    "integration", "integrations",
}
SKIP_NAMES = {
    ".gitignore", "LICENSE", ".DS_Store",
    "spartan_init.txt", "spartan_import.txt", "spartan_snapshot.txt",
    "spartan_tactical.dat", "steering_schedule.json", "jamming_profile.json",
    "combat_log.json", "nasa_exoplanets.csv", "Manifest.toml",
}

EDEN_HISTORY = {
    version: HISTORICAL / "EDEN" / f"EDEN-v{version}.zip"
    for version in ("0.1.0", "0.2.0")
}
ETHOS_HISTORY = {
    version: HISTORICAL / "ETHOS" / f"ETHOS-v{version}.zip"
    for version in ("0.1.0", "0.1.1", "0.2.0", "1.0.0")
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
    project_output = OUTPUT / project
    output = project_output / f"{project}-v{version}.zip"
    project_output.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".zip.tmp")
    prefix = f"{project}-v{version}"
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(source.rglob("*")):
            if not path.is_file() or should_skip(path, source):
                continue
            archive.write(path, Path(prefix) / path.relative_to(source))
        archive.write(ROOT / "LICENSE", Path(prefix) / "LICENSE")
    temporary.replace(output)
    for stale in project_output.glob(f"{project}-v*.zip"):
        if stale != output:
            stale.unlink()
    return output


def _historical_asset(source: Path) -> Path:
    if not source.is_file():
        raise FileNotFoundError(f"Missing historical release asset: {source}")
    return source


def build_eden_historical(version: str) -> Path:
    return _historical_asset(EDEN_HISTORY[version])


def build_ethos_historical(version: str) -> Path:
    return _historical_asset(ETHOS_HISTORY[version])


def build_all() -> list[Path]:
    return [build_current(project) for project in PROJECTS]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("project", choices=[*PROJECTS, "all"])
    parser.add_argument("--eden-historical", choices=sorted(EDEN_HISTORY))
    parser.add_argument("--ethos-historical", choices=sorted(ETHOS_HISTORY))
    args = parser.parse_args()

    if (args.eden_historical and args.project != "EDEN") or (
        args.ethos_historical and args.project != "ETHOS"
    ):
        parser.error("Historical options must match the selected project")

    if args.project == "all":
        outputs = build_all()
    elif args.project == "EDEN" and args.eden_historical:
        outputs = [build_eden_historical(args.eden_historical)]
    elif args.project == "ETHOS" and args.ethos_historical:
        outputs = [build_ethos_historical(args.ethos_historical)]
    else:
        outputs = [build_current(args.project)]

    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
