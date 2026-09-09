"""Rebuild and retain evidence for dependent base change and negative controls."""

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
for module, namespace in [("InitialityBaseChange", "Initiality"),
                          ("MuFinitaryElimBaseChange", "MuFinitary")]:
    source = (META / "KanonMeta" / f"{module}.lean").read_text()
    for modifiers, kind, name in re.findall(
            r"^[ \t]*(?:@\[[^\]]*\][ \t]*)?((?:(?:private|protected|noncomputable)[ \t]+)*)"
            r"(def|theorem|structure|abbrev|inductive|class|instance)\b[ \t]*"
            r"(?:\([^)]*\)[ \t]*)?([\w.]*)",
            source, re.M):
        # Private helpers are audited transitively through their public callers.
        if "private" in modifiers.split():
            continue
        if kind == "instance" or not name:
            raise SystemExit(f"{module}: {kind} {name or '<unnamed>'} cannot be named by a driver")
        public.append(f"KanonMeta.{namespace}.{name}")
permitted = {"propext", "Classical.choice", "Quot.sound"}
unexpected = {name: sorted(set(axioms) - permitted) for name, axioms in reports.items()
              if set(axioms) - permitted}
missing = sorted(expected - reports.keys())
undisclosed = sorted(set(public) - expected)
axiom_report = {"passed": not missing and not undisclosed and not unexpected,
                "reports": len(reports), "missing": missing, "undisclosed": undisclosed,
                "unexpected": unexpected, "base_change_api": {name: reports.get(name) for name in public}}
save("axiom-audit.json", axiom_report)
if not axiom_report["passed"]:
    raise SystemExit("axiom disclosure failed")

run("source-audit", [sys.executable, "-I", str(HERE / "audit.py")], ROOT)

controls = [
    ("omit-transport", "KanonMeta/InitialityBaseChange.lean",
     "    Eq.mp (congrArg E.Fibre (f.comm shape xs).symm)\n"
     "      (E.step shape (fun pos => f.map (xs pos)) witnesses)",
     "    E.step shape (fun pos => f.map (xs pos)) witnesses"),
    ("reset-witness", "test/MuFinitaryElimBaseChange.lean",
     "map := fun (_value) witness => (⟨witness.1.val, witness.1.property⟩, witness.2)",
     "map := fun (_value) witness => (⟨witness.1.val, witness.1.property⟩, 0)"),
    ("drop-second-shift", "test/InitialityBaseChange.lean",
     "(i := ()) (3 : Nat)).2 = 19 :=", "(i := ()) (3 : Nat)).2 = 17 :="),
]
mutations = []
with tempfile.TemporaryDirectory(prefix="kanon-base-change-controls-") as directory:
    for name, relative, old, new in controls:
        source = (META / relative).read_text()
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
        # Count in the mutated file: replacing a multiline anchor can move the error.
        last = (mutated[:start + len(new) + boundary.start()].count("\n") if boundary
                else mutated.count("\n") + 1)
        diagnostic_lines = [int(found) for found in re.findall(
            re.escape(str(path)) + r":(\d+):\d+: error:", result.stdout.decode())]
        killed = result.returncode == 1 and any(line <= found <= last
                                                for found in diagnostic_lines)
        mutations.append({"name": name, "source": relative,
                          "old": old, "new": new, "killed": killed,
                          "source_sha256": hashlib.sha256(mutated.encode()).hexdigest(),
                          "diagnostic_lines": diagnostic_lines})
save("mutations.json", mutations)
if not all(item["killed"] for item in mutations):
    raise SystemExit("a mutation control was not rejected at its edited declaration")

save("results.json", {"passed": True, "axiom_reports": len(reports),
                       "base_change_declarations": len(public), "mutations_killed": len(mutations)})
print(json.dumps({"passed": True, "axiom_reports": len(reports),
                  "base_change_declarations": len(public), "mutations_killed": len(mutations)}))
