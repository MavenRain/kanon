"""Verify that the retained evidence identifies the current decoder sources."""

import hashlib
import json
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
sources = json.loads((EVIDENCE / 'sources.json').read_text())
changed = [name for name, expected in sources['sha256'].items()
           if not (ROOT / name).is_file()
           or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != expected]
captures = json.loads((EVIDENCE / 'captures.json').read_text())
damaged = [name for name, expected in captures.items()
           if not (EVIDENCE / name).is_file()
           or hashlib.sha256((EVIDENCE / name).read_bytes()).hexdigest() != expected]
print(json.dumps({'passed': not changed and not damaged,
                  'sources': len(sources['sha256']), 'captures': len(captures),
                  'changed_sources': changed, 'damaged_captures': damaged}))
raise SystemExit(0 if not changed and not damaged else 1)
