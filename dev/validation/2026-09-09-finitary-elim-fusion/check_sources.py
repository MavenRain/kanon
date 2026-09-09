"""Read-only verification of retained sources and complete evidence fingerprints."""

import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
mismatches = []
for name, base in [("sources.json", ROOT), ("captures.json", HERE)]:
    for relative, expected in json.loads((HERE / name).read_text()).items():
        path = base / relative
        actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        if actual != expected:
            mismatches.append({"manifest": name, "path": relative})
actual = {str(path.relative_to(HERE)) for path in HERE.rglob("*")
          if path.is_file() and ".lake" not in path.relative_to(HERE).parts}
recorded = set(json.loads((HERE / "captures.json").read_text())) | {"captures.json"}
for path in sorted(actual ^ recorded):
    mismatches.append({"manifest": "captures.json", "path": path})
print(json.dumps({"passed": not mismatches, "mismatches": mismatches}))
raise SystemExit(1 if mismatches else 0)
