import importlib.util
from pathlib import Path

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
