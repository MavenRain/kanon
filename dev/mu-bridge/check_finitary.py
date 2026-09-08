"""Check generic family extraction, exact Lean certificates and ordered runtime.

Run after the OCaml and Lean builds. Complete command output and source hashes
are saved under .gatework/mu-finitary-bridge, or the directory passed with --out.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
FAMILY = "Grove"
CONSTRUCTORS = ("bud", "shoot", "join", "crown")
SAMPLE = (3, ((0, ()), (1, ((0, ()),)), (2, ((0, ()), (1, ((0, ()),))))))


def family_type(family):
    return f'(.lan (.SMu "{family}" []) (.sec (.SColl 0) []))'


def raw_value(family, constructors, value):
    constructor, children = value
    args = ", ".join(raw_value(family, constructors, child) for child in children)
    return f'(.intro (.SMu "{family}" []) (.actor "{constructors[constructor]}") [{args}])'


def certificate(family, constructors, order, sample, arities=None):
    """Specify expected raw records independently of the exporter response."""
    records = []
    if arities is None:
        arities = range(len(constructors))
    for index in order:
        arity = arities[index]
        fields = ", ".join(f'(.many, "_", {family_type(family)})' for _ in range(arity))
        recursive = "true" if arity else "false"
        records.append(f'{{ name := "{constructors[index]}", args := [{fields}], '
                       f'resultIndices := [], fullArity := {arity}, '
                       f'selfRecursive := {recursive} }}')
    status = ", ".join(json.dumps(constructors[index]) for index in order)
    declaration = (f'{{ name := "{family}", params := [], indices := [], level := 1, '
                   f'status := .complete [{status}], constructors := [{", ".join(records)}], '
                   'positive := true }')
    return f'''
namespace KanonMeta.MuFinitary.Control
example : Generated.declaration = {declaration} := rfl
example : (match validate Generated.declaration with
  | .ok (_checked) => true
  | .error (_error) => false) = true := rfl
example : Generated.sample = {raw_value(family, constructors, sample)} := rfl
example : Generated.sampleType = {family_type(family)} := rfl
example : Generated.sampleRecArg = none := rfl
example : Generated.samplePartial = false := rfl
example : Generated.sampleReducible = true := rfl
end KanonMeta.MuFinitary.Control
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=ROOT / ".gatework/mu-finitary-bridge")
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    exporter = ROOT / "_build/default/dev/mu-bridge/export_mu.exe"
    compiler = ROOT / "_build/default/bin/kanon.exe"
    fixture = ROOT / "test/meta/mu-finitary-bridge.kan"
    generated = ROOT / "meta/test/GeneratedMuFinitary.lean"
    expected_extraction = generated.read_bytes()
    source = fixture.read_text()
    observations = []

    def run(name, command, expected=None, error_contains=None):
        argv = [str(arg) for arg in command]
        result = subprocess.run(argv, cwd=ROOT, capture_output=True,
                                timeout=120, check=False)
        (out / (name + ".stdout")).write_bytes(result.stdout)
        (out / (name + ".stderr")).write_bytes(result.stderr)
        if error_contains is not None:
            passed = (result.returncode == 1 and result.stdout == b""
                      and bool(result.stderr) and error_contains in result.stderr)
        else:
            passed = result.returncode == 0 and result.stderr == b""
            if expected is not None:
                passed = passed and result.stdout == expected
        observations.append({"name": name, "command": argv,
                             "exit": result.returncode, "passed": passed})
        return result, passed

    def certify(name, extracted, family, constructors, order, sample, arities=None):
        path = out / (name + ".lean")
        path.write_bytes(extracted + certificate(family, constructors, order, sample,
                                                 arities).encode())
        _, passed = run(name + "-certificate",
                        ["lake", "+leanprover/lean4:v4.33.0-rc1", "--dir", ROOT / "meta",
                         "env", "lean", path], b"")
        return passed

    def runtime(name, path, expected):
        checks = []
        for host in ("kernel", "both"):
            _, passed = run(name + "-" + host,
                            [compiler, "run", path, "--export", "main", "--host", host],
                            expected)
            checks.append(passed)
        return all(checks)

    extracted, fresh = run("extraction", [exporter, "--finitary", FAMILY, fixture],
                           expected_extraction)
    certified = certify("baseline", extracted.stdout, FAMILY, CONSTRUCTORS, range(4), SAMPLE)
    _, axioms = run("axioms", [compiler, "axioms", fixture], b"")
    main_runtime = runtime("main", fixture, b"48\n")

    renamed_family = "Orchard"
    renamed_constructors = ("seed", "stem", "branch", "canopy")
    renamings = dict(zip((FAMILY,) + CONSTRUCTORS,
                        (renamed_family,) + renamed_constructors))
    renamed = re.sub(r"\b(?:Grove|bud|shoot|join|crown)\b",
                     lambda match: renamings[match.group(0)], source)
    declaration_lines = [f"| {name} : " + " -> ".join([FAMILY] * (arity + 1))
                         for arity, name in enumerate(CONSTRUCTORS)]
    declaration_block = "\n".join(declaration_lines)
    reordered = source.replace(declaration_block,
                               "\n".join(declaration_lines[index] for index in (3, 0, 2, 1)))
    original_sample = "crown bud (shoot bud) (join bud (shoot bud))"
    swapped_sample = "crown bud (join bud (shoot bud)) (shoot bud)"
    swapped = source.replace(original_sample, swapped_sample)
    multiple_nullary = """mu Signal : Type 0 with
| idle : Signal
| wake : Signal
| pair : Signal -> Signal -> Signal

def sample : Signal := pair idle wake
def rec weight : Signal -> Nat := fun (t : Signal) => case t as x in Signal return Nat with | idle => 2 | wake => 5 | pair l r => natAdd (natMul 2 (weight l)) (natMul 3 (weight r))
def main : Nat := weight sample
"""
    controls = {}
    for name, changed_source, family, constructors, arities, order, sample, expected, changed_once in (
            ("renamed", renamed, renamed_family, renamed_constructors, range(4), range(4),
             SAMPLE, b"48\n", renamed != source),
            ("reordered", reordered, FAMILY, CONSTRUCTORS, range(4), (3, 0, 2, 1),
             SAMPLE, b"48\n", source.count(declaration_block) == 1),
            ("swapped-children", swapped, FAMILY, CONSTRUCTORS, range(4), range(4),
             (3, (SAMPLE[1][0], SAMPLE[1][2], SAMPLE[1][1])), b"36\n",
             source.count(original_sample) == 1),
            ("multiple-nullary", multiple_nullary, "Signal", ("idle", "wake", "pair"),
             (0, 0, 2), range(3), (2, ((0, ()), (1, ()))), b"19\n", True)):
        path = out / (name + ".kan")
        path.write_text(changed_source)
        result, exported = run(name + "-extraction", [exporter, "--finitary", family, path])
        exact = certify(name, result.stdout, family, constructors, order, sample, arities)
        _, empty_axioms = run(name + "-axioms", [compiler, "axioms", path], b"")
        correct = runtime(name, path, expected)
        controls[name] = {"extraction_changed": changed_once and exported
                          and result.stdout != expected_extraction,
                          "extraction_certified": exact, "empty_axioms": empty_axioms,
                          "runtime_passed": correct}

    # An invalid trailing definition tests that the whole fixture is checked.
    invalid = out / "invalid-trailing-definition.kan"
    invalid.write_text(source + "\ndef broken : Nat := bud\n")
    checked, rejected = run("invalid-check", [compiler, "check", invalid], error_contains=b"")
    refused, refused_export = run("invalid-extraction",
                                  [exporter, "--finitary", FAMILY, invalid], error_contains=b"")
    rejections = {"invalid_fixture": rejected and refused_export
                  and checked.stderr == refused.stderr}
    missing_sample = out / "missing-sample.kan"
    missing_sample.write_text(re.sub(r"\bsample\b", "specimen", source))
    for name, command, error in (
            ("missing-family", [exporter, "--finitary", "Absent", fixture],
             b"the checked fixture has no Absent family"),
            ("missing-sample", [exporter, "--finitary", FAMILY, missing_sample],
             b"missing checked definition sample"),
            ("missing-file", [exporter, "--finitary", FAMILY, out / "missing.kan"],
             b"cannot read fixture"),
            ("missing-arguments", [exporter], b"usage:"),
            ("missing-family-and-file", [exporter, "--finitary"], b"usage:"),
            ("missing-file-argument", [exporter, "--finitary", FAMILY], b"usage:"),
            ("extra-argument", [exporter, "--finitary", FAMILY, fixture, "extra"], b"usage:"),
            ("unknown-mode", [exporter, "--unknown", fixture], b"usage:")):
        _, refused = run(name, command, error_contains=error)
        rejections[name] = refused

    tracked = [fixture, generated, ROOT / "dev/mu-bridge/export_mu.ml",
               ROOT / "dev/mu-bridge/check_finitary.py", ROOT / "dev/mu-bridge/dune",
               ROOT / "meta/KanonMeta/MuNat.lean",
               ROOT / "meta/KanonMeta/FinitaryConstruction.lean",
               ROOT / "meta/KanonMeta/MuFinitary.lean", ROOT / "meta/test/MuFinitary.lean",
               ROOT / "lib/positivity.ml", ROOT / "lib/rules.ml", ROOT / "surface/elab.ml"]
    passed = all([fresh, certified, axioms, main_runtime,
                  all(all(control.values()) for control in controls.values()),
                  all(rejections.values())])
    evidence = {"passed": passed, "controls": controls, "rejections": rejections,
                "observations": observations,
                "sha256": {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                           for path in tracked}}
    (out / "result.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print("MU-FINITARY-BRIDGE " + ("OK" if passed else "FAIL"))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
