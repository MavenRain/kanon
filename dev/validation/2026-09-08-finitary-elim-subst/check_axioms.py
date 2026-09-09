"""Check disclosure of the dependent substitution API and permitted axioms."""

import hashlib
import json
from pathlib import Path
import re

EVIDENCE = Path(__file__).resolve().parent
ROOT = EVIDENCE.parents[2]
driver = (ROOT / "meta/Axioms.lean").read_text()
# Both increment modules are scanned for disclosure, so a public law of either
# one needs a driver line. The report leg below uses the owned module alone,
# because this record retains the axiom output of the substitution increment.
owned = "meta/KanonMeta/MuFinitaryElimSubst.lean"
sources = {
    "meta/KanonMeta/MuFinitaryElimSubst.lean": "KanonMeta.MuFinitary.",
    "meta/KanonMeta/MuFinitaryElimCoherence.lean": "KanonMeta.MuFinitary.",
}
legacy = set()
public = []
declared = {}
for relative, namespace in sources.items():
    source = (ROOT / relative).read_text()
    names = [name for name in (namespace + found for found in re.findall(
        r"^(?:@\[[^\]]*\]\s*)?(?:protected\s+|nonrec\s+|noncomputable\s+)*"
        r"(?:theorem|lemma|def|abbrev|instance|structure|inductive|opaque)"
        r" ([\w.]+)", source, re.M)) if name not in legacy]
    declared[relative] = names
    public.extend(names)
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
missing = sorted(set(declared[owned]) - reports.keys())
undisclosed = sorted(set(public) - set(expected))
passed = bool(public) and not missing and not undisclosed and not unexpected
report = {"passed": passed, "reports": len(reports), "missing": missing,
          "undisclosed": undisclosed, "unexpected": unexpected,
          "substitution_api_reports": {name: reports.get(name)
                                       for name in declared[owned]},
          "source_sha256": {relative: hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()
                            for relative in sources},
          "driver_sha256": hashlib.sha256(driver.encode()).hexdigest(),
          "output_sha256": hashlib.sha256(output.encode()).hexdigest()}
(EVIDENCE / "axiom-audit.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({key: report[key] for key in
                  ("passed", "reports", "missing", "undisclosed", "unexpected")}))
raise SystemExit(0 if passed else 1)
