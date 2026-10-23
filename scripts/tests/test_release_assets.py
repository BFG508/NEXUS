import tempfile
import subprocess
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from scripts import build_release_assets as builder
from scripts import check_release_isolation as isolation


class ReleaseAssetTests(unittest.TestCase):
    def test_local_metadata_is_ignored_and_excluded_from_releases(self):
        local_directories = (
            ".awx", ".aws", ".agent", ".agents", ".agentws", ".codex",
            ".claude", ".cursor", ".gemini", ".windsurf", ".opencode", ".continue",
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".gitignore").write_bytes((builder.ROOT / ".gitignore").read_bytes())
            subprocess.run(["git", "init", "--quiet", str(root)], check=True)
            (root / "LICENSE").write_text("test license")
            project = root / "HERMES"
            project.mkdir()
            (project / "VERSION").write_text("0.1.0")
            (project / "README.md").write_text("standalone project")
            for name in local_directories:
                for parent in (root, project, project / "nested"):
                    path = parent / name / "private.json"
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text('{"local": true}')
                    result = subprocess.run(
                        ["git", "-C", str(root), "check-ignore", "--quiet", str(path)],
                        capture_output=True,
                    )
                    self.assertEqual(result.returncode, 0, str(path))
            with patch.object(builder, "ROOT", root), patch.object(builder, "OUTPUT", root / "built"):
                asset = builder.build_current("HERMES")
            with zipfile.ZipFile(asset) as archive:
                self.assertIn("HERMES-v0.1.0/README.md", archive.namelist())
                self.assertFalse(any(set(Path(name).parts) & set(local_directories) for name in archive.namelist()))
            for name in local_directories:
                with self.subTest(directory=name):
                    bad = root / "contaminated.zip"
                    with zipfile.ZipFile(bad, "w") as archive:
                        archive.writestr(f"HERMES-v0.1.0/nested/{name}/private.json", "{}")
                    with self.assertRaisesRegex(SystemExit, "local metadata leaked"):
                        isolation.check(bad)

    def test_all_builds_current_projects_without_historical_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "LICENSE").write_text("test license")
            for project in ("EDEN", "ETHOS"):
                (root / project).mkdir()
                (root / project / "VERSION").write_text("2.0.0")
                (root / project / "README.md").write_text(project)
            output = root / "_release_assets" / "built"
            with patch.object(builder, "ROOT", root), patch.object(builder, "OUTPUT", output), \
                    patch.object(builder, "PROJECTS", ("EDEN", "ETHOS")):
                assets = builder.build_all()
                self.assertEqual(assets, [output / p / f"{p}-v2.0.0.zip" for p in ("EDEN", "ETHOS")])
                for asset in assets:
                    with zipfile.ZipFile(asset) as archive:
                        self.assertIn(f"{asset.stem}/LICENSE", archive.namelist())
                (root / "EDEN" / "VERSION").write_text("2.1.0")
                current = builder.build_current("EDEN")
                self.assertFalse(assets[0].exists())
                self.assertTrue(assets[1].exists())
                self.assertEqual(list((output / "EDEN").glob("*.zip")), [current])

    def test_historical_selection_preserves_bytes_and_does_not_build(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "historical" / "EDEN" / "EDEN-v0.1.0.zip"
            archive.parent.mkdir(parents=True)
            archive.write_bytes(b"preserved archive")
            output = Path(directory) / "built"
            with patch.object(builder, "EDEN_HISTORY", {"0.1.0": archive}), \
                    patch.object(builder, "OUTPUT", output):
                self.assertEqual(builder.build_eden_historical("0.1.0"), archive)
            self.assertEqual(archive.read_bytes(), b"preserved archive")
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
