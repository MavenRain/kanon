"""Rebuild and retain evidence for signature translation and negative controls."""

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


# Reuse the pinned local dependencies in an independent client package.
# Its only source dependency is the public package, through a relative path.
client = HERE / "client"
manifest = json.loads((META / "lake-manifest.json").read_text())
for package in manifest["packages"]:
    package["inherited"] = True
manifest["packages"].insert(0, {
    "type": "path", "scope": "", "name": "«kanon-meta»",
    "manifestFile": "lake-manifest.json", "inherited": False,
    "dir": "../../../../meta", "configFile": "lakefile.lean"})
manifest["name"] = "signatureChangeClient"
(client / "lake-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
packages = client / ".lake" / "packages"
packages.mkdir(parents=True, exist_ok=True)
for package in manifest["packages"]:
    if package["type"] != "git":
        continue
    name = package["name"].strip("«»")
    target = META / ".lake" / "packages" / name
    link = packages / name
    if target.is_dir() and not link.exists():
        link.symlink_to(target, target_is_directory=True)

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
for module, namespace in [("SignatureChange", "Initiality")]:
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
                "unexpected": unexpected, "signature_change_api": {name: reports.get(name) for name in public}}
save("axiom-audit.json", axiom_report)
if not axiom_report["passed"]:
    raise SystemExit("axiom disclosure failed")

run("source-audit", [sys.executable, "-I", str(HERE / "audit.py")], ROOT)

controls = [
    ("omit-index-transport", "KanonMeta/SignatureChange.lean",
     "fun q => f.child s q ▸ xs (f.position s q)",
     "fun q => xs (f.position s q)", "def SignatureMap.children"),
    ("wrong-branch", "test/SignatureChange.lean",
     "| .join => fun (_q) => ⟨(1 : Fin 2)⟩",
     "| .join => fun (_q) => ⟨(0 : Fin 2)⟩", "theorem selected_right"),
    ("omit-permutation", "test/SignatureChange.lean",
     "| .join => fun q => ⟨Fin.cases (1 : Fin 2) (fun (_p) => (0 : Fin 2)) q.down⟩",
     "| .join => fun q => q", "theorem swapped_children"),
    ("reset-witness", "test/SignatureChange.lean",
     "2 * (ws ⟨(0 : Fin 2)⟩).2 + 3 * (ws ⟨(1 : Fin 2)⟩).2 + 1)",
     "0)", "theorem arbitrary_witness"),
]
mutations = []
with tempfile.TemporaryDirectory(prefix="kanon-signature-controls-") as directory:
    for name, relative, old, new, declaration in controls:
        source = (META / relative).read_text()
        if source.count(old) != 1:
            raise SystemExit(f"{name}: mutation anchor is not unique")
        path = Path(directory) / f"{name}.lean"
        mutated = source.replace(old, new)
        path.write_text(mutated)
        result = lake(name, ["env", "lean", str(path)], expected=None)
        # Require a type error in the named regression or edited definition.
        # A failed dependency, setup or unrelated declaration does not count.
        if mutated.count(declaration + " ") != 1:
            raise SystemExit(f"{name}: declaration anchor is not unique")
        start = mutated.index(declaration + " ")
        line = mutated[:start].count("\n") + 1
        boundary = re.search(r"^(?:(?:private|noncomputable) )?(?:def|theorem|structure)\b",
                             mutated[start + len(declaration):], re.M)
        last = (mutated[:start + len(declaration) + boundary.start()].count("\n") if boundary
                else mutated.count("\n") + 1)
        diagnostic_lines = [int(found) for found in re.findall(
            re.escape(str(path)) + r":(\d+):\d+: error:", result.stdout.decode())]
        killed = result.returncode == 1 and any(line <= found <= last
                                                for found in diagnostic_lines)
        mutations.append({"name": name, "source": relative,
                          "old": old, "new": new, "killed": killed,
                          "source_sha256": hashlib.sha256(mutated.encode()).hexdigest(),
                          "diagnostic_lines": diagnostic_lines,
                          "required_declaration": declaration, "required_lines": [line, last]})
save("mutations.json", mutations)
if not all(item["killed"] for item in mutations):
    raise SystemExit("a mutation control was not rejected at its edited declaration")

save("results.json", {"passed": True, "axiom_reports": len(reports),
                       "signature_change_declarations": len(public), "mutations_killed": len(mutations)})
sources = [path for path in META.rglob("*.lean") if ".lake" not in path.relative_to(META).parts]
sources += [META / "lean-toolchain", META / "lake-manifest.json", ROOT / "README.md",
            ROOT / "dev" / "FOUNDATION-AUDIT.md", ROOT / "dev" / "SIGNATURE-CHANGE.md"]
save("sources.json", {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                      for path in sorted(sources)})
save("captures.json", {str(path.relative_to(HERE)): hashlib.sha256(path.read_bytes()).hexdigest()
                       for path in sorted(HERE.rglob("*"))
                       if path.is_file() and ".lake" not in path.relative_to(HERE).parts
                       and path.name != "captures.json"})
print(json.dumps({"passed": True, "axiom_reports": len(reports),
                  "signature_change_declarations": len(public), "mutations_killed": len(mutations)}))
