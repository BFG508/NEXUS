from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
for path in (ROOT, ROOT / "integration", ROOT / "integration" / "adapters", ROOT / "BEAM"):
    sys.path.insert(0, str(path))
