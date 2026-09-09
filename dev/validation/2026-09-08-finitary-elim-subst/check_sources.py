"""Check the retained source and command capture fingerprints."""

import hashlib
import json
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
mismatches = []
for manifest, base in [("sources.json", ROOT), ("captures.json", EVIDENCE)]:
    records = json.loads((EVIDENCE / manifest).read_text())
    for relative, expected in records.items():
        path = base / relative
        actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        if actual != expected:
            mismatches.append({"manifest": manifest, "path": relative})
recorded = set(json.loads((EVIDENCE / "captures.json").read_text())) | {"captures.json"}
for name in sorted(str(path.relative_to(EVIDENCE)) for path in EVIDENCE.rglob("*")
                   if path.is_file()):
    if name not in recorded:
        mismatches.append({"manifest": "captures.json", "path": name})
print(json.dumps({"pass": not mismatches, "mismatches": mismatches}))
raise SystemExit(1 if mismatches else 0)
