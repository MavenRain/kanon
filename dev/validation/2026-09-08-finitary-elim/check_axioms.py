"""Check disclosure of the dependent elimination API and permitted axioms."""

import hashlib
import json
from pathlib import Path
import re

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
driver = (ROOT / "meta/Axioms.lean").read_text()
sources = {
    "meta/KanonMeta/Initiality.lean": "KanonMeta.Initiality.",
    "meta/KanonMeta/MuFinitaryElim.lean": "KanonMeta.MuFinitary.",
}
# Public definitions of Initiality that predate this increment. They carry no
# driver line, and the disclosure rule applies to the declarations of the new
# module and to the declarations this increment adds.
legacy = {
    "KanonMeta.Initiality.Hom.id",
    "KanonMeta.Initiality.Hom.comp",
    "KanonMeta.Initiality.Displayed.total",
    "KanonMeta.Initiality.Displayed.projection",
}
public = []
for relative, namespace in sources.items():
    source = (ROOT / relative).read_text()
    public.extend(name for name in (namespace + found for found in re.findall(
        r"^(?:@\[[^\]]*\]\s*)?(?:protected\s+|nonrec\s+|noncomputable\s+)*"
        r"(?:theorem|def) ([\w.]+)", source, re.M)) if name not in legacy)
output = (EVIDENCE / "axioms.stdout").read_text()
reports = {}
for match in re.finditer(
        r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)", output):
    reports[match.group(1)] = [name.strip() for name in (match.group(2) or "").split(",")
                             if name.strip()]
expected = [name if name.startswith("KanonMeta.") else "KanonMeta." + name
            for name in re.findall(r"^#print axioms (\S+)", driver, re.M)]
permitted = {"propext", "Classical.choice", "Quot.sound"}
unexpected = {name: sorted(set(axioms) - permitted) for name, axioms in reports.items()
              if set(axioms) - permitted}
missing = sorted((set(expected) | set(public)) - reports.keys())
undisclosed = sorted(set(public) - set(expected))
passed = bool(public) and not missing and not undisclosed and not unexpected
report = {"passed": passed, "reports": len(reports), "missing": missing,
          "undisclosed": undisclosed, "unexpected": unexpected,
          "elimination_api_reports": {name: reports.get(name) for name in public},
          "source_sha256": {relative: hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()
                            for relative in sources},
          "driver_sha256": hashlib.sha256(driver.encode()).hexdigest(),
          "output_sha256": hashlib.sha256(output.encode()).hexdigest()}
(EVIDENCE / "axiom-audit.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({key: report[key] for key in
                  ("passed", "reports", "missing", "undisclosed", "unexpected")}))
raise SystemExit(0 if passed else 1)
