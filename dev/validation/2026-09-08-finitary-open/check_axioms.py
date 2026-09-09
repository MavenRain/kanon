"""Check retained dependencies and coverage of every public open-fragment law."""

import hashlib
import json
from pathlib import Path
import re

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
driver = (ROOT / "meta/Axioms.lean").read_text()
sources = [ROOT / "meta/KanonMeta/MuFinitaryOpen.lean",
           ROOT / "meta/KanonMeta/MuFinitaryOpenDecode.lean"]
output = (EVIDENCE / "axioms.stdout").read_text()
# Public laws may carry attributes or the protected and nonrec modifiers.
PUBLIC_THEOREM = r"^(?:@\[[^\]]*\]\s*)?(?:protected\s+|nonrec\s+)*theorem ([\w.]+)"
public = ["KanonMeta.MuFinitary.OpenTerm." + name for source in sources
          for name in re.findall(PUBLIC_THEOREM, source.read_text(), re.M)]
expected = re.findall(r"^#print axioms (\S+)", driver, re.M)
reports = {}
for match in re.finditer(
        r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)", output):
    reports[match.group(1)] = [name.strip() for name in (match.group(2) or "").split(",")
                             if name.strip()]
# Earlier driver entries use the namespace opened in Axioms.lean.
expected = [name if name in reports else "KanonMeta." + name for name in expected]
permitted = {"propext", "Classical.choice", "Quot.sound"}
unexpected = {name: sorted(set(axioms) - permitted) for name, axioms in reports.items()
              if set(axioms) - permitted}
missing = sorted((set(expected) | set(public)) - reports.keys())
undisclosed = sorted(set(public) - set(expected))
passed = bool(public) and not missing and not undisclosed and not unexpected
report = {"passed": passed, "reports": len(reports), "missing": missing,
          "undisclosed": undisclosed, "unexpected": unexpected,
          "open_fragment_reports": {name: reports.get(name) for name in public},
          "source_sha256": {str(path.relative_to(ROOT)):
                            hashlib.sha256(path.read_bytes()).hexdigest() for path in sources},
          "driver_sha256": hashlib.sha256(driver.encode()).hexdigest(),
          "output_sha256": hashlib.sha256(output.encode()).hexdigest()}
(EVIDENCE / "axiom-audit.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({key: report[key] for key in
                  ("passed", "reports", "missing", "undisclosed", "unexpected")}))
raise SystemExit(0 if passed else 1)
