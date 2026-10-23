#!/usr/bin/env python3
"""Exercise the real HERMES/ATLAS CLI contract without an Apple SDK."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hermes", required=True, type=Path)
    parser.add_argument("--atlas", required=True, type=Path)
    args = parser.parse_args()
    hermes, atlas = str(args.hermes.resolve()), str(args.atlas.resolve())
    root = Path(__file__).resolve().parents[1]

    def run(command: list[str], expected: int = 0) -> str:
        result = subprocess.run(command, capture_output=True, text=True, env=environment, timeout=30)
        output = result.stdout + result.stderr
        if result.returncode != expected:
            raise SystemExit(f"{command}: expected exit {expected}, got {result.returncode}\n{output}")
        return output

    environment = dict(os.environ)
    environment.pop("NEXUS_TEST_UNDEFINED_PREPARATION_VARIABLE", None)
    with tempfile.TemporaryDirectory(prefix="nexus-hermes-atlas-") as directory:
        work = Path(directory)
        runs = work / "runs"
        run([hermes, "run", "--runs-dir", str(runs), "--run-id", "success",
             str(root / "HERMES/scenarios/minimal.yaml")])
        for command in ("validate", "inspect", "timeline"):
            run([atlas, command, str(runs / "success")])
        run([atlas, "artifacts", "--verify", str(runs / "success")])
        print("[OK] Successful HERMES run: ATLAS validation, inspection, timeline and artifact hashes")

        scenario = work / "failure.json"
        scenario.write_text(json.dumps({
            "version": 1, "name": "preparation-failure",
            "steps": {
                "first": {"command": "${NEXUS_TEST_UNDEFINED_PREPARATION_VARIABLE}"},
                "second": {"command": "unused", "depends_on": ["first"]},
            },
        }), encoding="utf-8")
        run([hermes, "run", "--runs-dir", str(runs), "--run-id", "failure", str(scenario)], expected=1)
        manifest = json.loads((runs / "failure/manifest.json").read_text(encoding="utf-8"))
        first, second = manifest["steps"]
        if (manifest["status"] != "failed" or first["status"] != "failed"
                or second["status"] != "blocked" or "exit_code" in first
                or not first.get("started_at") or not first.get("finished_at")):
            raise SystemExit("Invalid preparation-failure lifecycle")
        for command in ("validate", "inspect", "timeline"):
            run([atlas, command, str(runs / "failure")])
        print("[OK] Preparation failure: real HERMES manifest accepted by ATLAS")

        manifest["steps"].append(first.copy())
        duplicate = work / "duplicate.json"
        duplicate.write_text(json.dumps(manifest), encoding="utf-8")
        output = run([atlas, "validate", str(duplicate)], expected=1)
        if "duplicate step name" not in output:
            raise SystemExit(f"Missing duplicate-name diagnostic:\n{output}")
        print("[OK] Duplicate step names: validation error without crashing")


if __name__ == "__main__":
    main()
