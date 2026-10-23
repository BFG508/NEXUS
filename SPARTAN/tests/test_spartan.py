import importlib.util
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).parents[1]

spec = importlib.util.spec_from_file_location("spartanGen", ROOT / "spartanGen.py")
gen = importlib.util.module_from_spec(spec); spec.loader.exec_module(gen)


def test_generator_creates_fixed_width_unique_records(tmp_path):
    path = tmp_path / "init.txt"
    gen.generate_spartan_init_load(str(path), 50)
    lines = path.read_text().splitlines()
    assert len(lines) == 50
    assert all(len(line) == 28 for line in lines)
    assert len({line[10:20] for line in lines}) == 50


@pytest.mark.skipif(shutil.which("cobc") is None, reason="GnuCOBOL is required")
def test_import_updates_existing_assets_and_inserts_new_assets(tmp_path):
    initializer = tmp_path / "initialize.cbl"
    initializer.write_text('''identification division.
program-id. initialize-db.
environment division.
input-output section.
file-control.
    select db assign to "spartan_tactical.dat"
        organization is indexed
        record key is node-id.
data division.
file section.
fd db.
01 db-record.
    05 node-type pic x(10).
    05 node-id pic x(10).
    05 integrity pic 9(3).
    05 delta-v pic 9(5).
procedure division.
    open output db
    move "SCOUT" to node-type
    move "A-001" to node-id
    move 90 to integrity
    move 500 to delta-v
    write db-record end-write
    close db
    stop run.
''')
    programs = {
        "initialize": initializer,
        "import": ROOT / "spartan_import_tool.cbl",
        "snapshot": ROOT / "spartan_snapshot_tool.cbl",
    }
    for name, source in programs.items():
        subprocess.run(["cobc", "-x", "-free", "-o", str(tmp_path / name), str(source)], check=True, capture_output=True)
    subprocess.run([str(tmp_path / "initialize")], cwd=tmp_path, check=True)
    (tmp_path / "spartan_import.txt").write_text(
        f"{'SCOUT':<10}{'A-001':<10}07500480\n"
        f"{'RELAY':<10}{'A-002':<10}08000600\n"
    )
    subprocess.run([str(tmp_path / "import")], cwd=tmp_path, check=True)
    subprocess.run([str(tmp_path / "snapshot")], cwd=tmp_path, check=True)
    assert (tmp_path / "spartan_snapshot.txt").read_text().splitlines() == [
        f"{'SCOUT':<10}{'A-001':<10}07500480",
        f"{'RELAY':<10}{'A-002':<10}08000600",
    ]
    assert (tmp_path / "spartan_import.txt").read_text() == ""
