"""Verify the retained source and evidence fingerprints."""

import hashlib
import json
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
errors = []
for name, base in (("sources.json", ROOT), ("captures.json", EVIDENCE)):
    manifest = json.loads((EVIDENCE / name).read_text())
    for relative, expected in manifest.items():
        path = base / relative
        if not path.is_file():
            errors.append(f"missing: {relative}")
        elif hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            errors.append(f"changed: {relative}")
recorded = set(json.loads((EVIDENCE / "captures.json").read_text())) | {"captures.json"}
for name in sorted(path.name for path in EVIDENCE.iterdir()):
    if name not in recorded:
        errors.append(f"extra: {name}")
print(json.dumps({"passed": not errors, "errors": errors}))
raise SystemExit(1 if errors else 0)
