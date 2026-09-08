"""Check retained proof dependencies and coverage of the public decoder laws."""

import hashlib
import json
from pathlib import Path
import re

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
driver = (ROOT / 'meta/Axioms.lean').read_text()
source = (ROOT / 'meta/KanonMeta/MuFinitaryDecode.lean').read_text()
output = (EVIDENCE / 'axioms.stdout').read_text()
public = ['KanonMeta.MuFinitary.' + name for name in
          re.findall(r'^theorem ([\w.]+)', source, re.M)]
expected = re.findall(r'^#print axioms (KanonMeta\.MuFinitary\.\S+)', driver, re.M)
reports = {}
for match in re.finditer(
        r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)", output):
    reports[match.group(1)] = [name.strip() for name in (match.group(2) or '').split(',')
                             if name.strip()]
permitted = {'propext', 'Classical.choice', 'Quot.sound'}
unexpected = {name: sorted(set(axioms) - permitted) for name, axioms in reports.items()
              if set(axioms) - permitted}
missing = sorted((set(expected) | set(public)) - reports.keys())
undisclosed = sorted(set(public) - set(expected))
passed = bool(public) and not missing and not undisclosed and not unexpected
report = {'passed': passed, 'reports': len(reports), 'missing': missing,
          'undisclosed': undisclosed, 'unexpected': unexpected,
          'decoder_reports': {name: reports.get(name) for name in public},
          'source_sha256': hashlib.sha256(source.encode()).hexdigest(),
          'driver_sha256': hashlib.sha256(driver.encode()).hexdigest(),
          'output_sha256': hashlib.sha256(output.encode()).hexdigest()}
(EVIDENCE / 'axiom-audit.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
raise SystemExit(0 if passed else 1)
