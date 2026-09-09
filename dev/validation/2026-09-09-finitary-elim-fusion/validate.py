"""Rebuild and retain evidence for dependent fusion, including negative controls."""

import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
META = ROOT / "meta"
TOOLCHAIN = (META / "lean-toolchain").read_text().strip()
LAKE = shutil.which("lake")
if LAKE is None:
    raise SystemExit("lake is required")


def save(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2) + "\n")


def run(name, args, cwd, expected=0):
    start = time.monotonic()
    result = subprocess.run(args, cwd=cwd, capture_output=True, timeout=300)
    (HERE / f"{name}.stdout").write_bytes(result.stdout)
    (HERE / f"{name}.stderr").write_bytes(result.stderr)
    report = {"command": args, "cwd": str(cwd), "exit_code": result.returncode,
              "elapsed_seconds": round(time.monotonic() - start, 3),
              "stdout_sha256": hashlib.sha256(result.stdout).hexdigest(),
              "stderr_sha256": hashlib.sha256(result.stderr).hexdigest()}
    save(f"{name}.json", report)
    print(json.dumps({"check": name, "exit_code": result.returncode}), flush=True)
    if expected is not None and result.returncode != expected:
        raise SystemExit(f"{name} failed; inspect its captured output")
    return result


def lake(name, args, cwd=META, expected=0):
    return run(name, [LAKE, "+" + TOOLCHAIN, *args], cwd, expected)


for name, cwd in [("lean-build", META), ("client-build", HERE / "client")]:
    result = lake(name, ["build"], cwd)
    if re.search(rb"\b(?:warning|error):", result.stdout + result.stderr):
        raise SystemExit(f"{name} emitted a warning or error")

result = lake("axioms", ["env", "lean", "Axioms.lean"])
reports = {}
for match in re.finditer(
        r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",
        result.stdout.decode()):
    reports[match[1]] = [item.strip() for item in (match[2] or "").split(",") if item.strip()]
expected = {name if name.startswith("KanonMeta.") else "KanonMeta." + name
            for name in re.findall(r"^#print axioms (\S+)",
                                   (META / "Axioms.lean").read_text(), re.M)}
public = []
for module, namespace in [("InitialityFusion", "Initiality"),
                          ("MuFinitaryElimFusion", "MuFinitary")]:
    source = (META / "KanonMeta" / f"{module}.lean").read_text()
    for modifiers, kind, name in re.findall(
            r"^[ \t]*(?:@\[[^\]]*\][ \t]*)?((?:(?:private|protected|noncomputable)[ \t]+)*)"
            r"(def|theorem|structure|abbrev|inductive|class|instance)\b[ \t]*"
            r"(?:\([^)]*\)[ \t]*)?([\w.]*)",
            source, re.M):
        # A private declaration, an instance or an unnamed form has no name a driver can print.
        if "private" in modifiers.split() or kind == "instance" or not name:
            raise SystemExit(f"{module}: {kind} {name or '<unnamed>'} cannot be named by a driver")
        public.append(f"KanonMeta.{namespace}.{name}")
permitted = {"propext", "Classical.choice", "Quot.sound"}
unexpected = {name: sorted(set(axioms) - permitted) for name, axioms in reports.items()
              if set(axioms) - permitted}
missing = sorted(expected - reports.keys())
undisclosed = sorted(set(public) - expected)
axiom_report = {"passed": not missing and not undisclosed and not unexpected,
                "reports": len(reports), "missing": missing, "undisclosed": undisclosed,
                "unexpected": unexpected, "fusion_api": {name: reports.get(name) for name in public}}
save("axiom-audit.json", axiom_report)
if not axiom_report["passed"]:
    raise SystemExit("axiom disclosure failed")

run("source-audit", [sys.executable, "-I", str(HERE / "audit.py")], ROOT)

source = (META / "test/MuFinitaryElimFusion.lean").read_text()
controls = [
    ("reset-witness", "(fun _value witness => (witness.2, witness.1))",
     "(fun _value witness => (0, witness.1))"),
    # The whole theorem changes subject, so Lean rejects the numeral 159 itself.
    ("permute-children", "theorem supplied_annotation_retained :\n"
     "    (pattern.inductInterpret Target targetStep environment\n"
     "      (fun i => swapHom.map (environment i) (witnesses i))).1 = 159 :=\n"
     "  (congrArg Prod.fst\n"
     "    (OpenTerm.inductInterpret_fusion swapHom environment witnesses pattern)).symm",
     "theorem supplied_annotation_retained :\n"
     "    (reversed.inductInterpret Target targetStep environment\n"
     "      (fun i => swapHom.map (environment i) (witnesses i))).1 = 159 :=\n"
     "  (congrArg Prod.fst\n"
     "    (OpenTerm.inductInterpret_fusion swapHom environment witnesses reversed)).symm"),
]
mutations = []
with tempfile.TemporaryDirectory(prefix="kanon-fusion-controls-") as directory:
    for name, old, new in controls:
        if source.count(old) != 1:
            raise SystemExit(f"{name}: mutation anchor is not unique")
        path = Path(directory) / f"{name}.lean"
        mutated = source.replace(old, new)
        path.write_text(mutated)
        result = lake(name, ["env", "lean", str(path)], expected=None)
        # Require a Lean type error in the edited definition or theorem,
        # excluding dependency, setup, timeout and unrelated failures.  The
        # window ends before the next declaration header after the anchor.
        start = source.index(old)
        line = source[:start].count("\n") + 1
        boundary = re.search(r"^(?:noncomputable def|def|theorem|structure)\b",
                             source[start + len(old):], re.M)
        last = (source[:start + len(old) + boundary.start()].count("\n") if boundary
                else source.count("\n") + 1)
        diagnostic_lines = [int(found) for found in re.findall(
            re.escape(str(path)) + r":(\d+):\d+: error:", result.stdout.decode())]
        killed = result.returncode == 1 and any(line <= found <= last
                                                for found in diagnostic_lines)
        mutations.append({"name": name, "old": old, "new": new, "killed": killed,
                          "source_sha256": hashlib.sha256(mutated.encode()).hexdigest(),
                          "diagnostic_lines": diagnostic_lines})
save("mutations.json", mutations)
if not all(item["killed"] for item in mutations):
    raise SystemExit("a mutation control was not rejected at its edited declaration")

save("results.json", {"passed": True, "axiom_reports": len(reports),
                       "fusion_declarations": len(public), "mutations_killed": len(mutations)})
print(json.dumps({"passed": True, "axiom_reports": len(reports),
                  "fusion_declarations": len(public), "mutations_killed": len(mutations)}))
