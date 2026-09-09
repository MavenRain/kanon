import hashlib
import json
from pathlib import Path
import re

EVIDENCE = Path(__file__).resolve().parent
REPO = EVIDENCE.parents[2]
ROOT = REPO / "meta"


CHAR_LITERAL = re.compile(r"'(?:\\(?:x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|.)|[^'\\\n])'")
NAME_TAIL = "_'!?"


def char_literal_at(source, index):
    """Match a Lean character literal at index, or return None.

    A quote that follows a name character belongs to that name, so it opens
    no literal.
    """
    if source[index] != "'":
        return None
    previous = source[index - 1] if index else ""
    if previous.isalnum() or previous in NAME_TAIL:
        return None
    return CHAR_LITERAL.match(source, index)


def remove_comments_and_strings(source, relative):
    chars = list(source)
    depth = 0
    in_string = False
    index = 0
    while index < len(source):
        pair = source[index:index + 2]
        literal = None if depth or in_string else char_literal_at(source, index)
        if depth:
            if pair == "/-":
                depth += 1
                chars[index:index + 2] = "  "
                index += 2
                continue
            if pair == "-/":
                depth -= 1
                chars[index:index + 2] = "  "
                index += 2
                continue
            if chars[index] != "\n":
                chars[index] = " "
        elif in_string:
            if source[index] == "\\":
                chars[index:index + 2] = "  "
                index += 2
                continue
            if source[index] == '"':
                in_string = False
            if chars[index] != "\n":
                chars[index] = " "
        elif pair == "/-":
            depth = 1
            chars[index:index + 2] = "  "
            index += 2
            continue
        elif pair == "--":
            end = source.find("\n", index)
            end = len(source) if end == -1 else end
            chars[index:end] = " " * (end - index)
            index = end
            continue
        elif literal is not None:
            chars[index:literal.end()] = " " * (literal.end() - index)
            index = literal.end()
            continue
        elif source[index] == '"':
            in_string = True
            chars[index] = " "
        index += 1
    if depth or in_string:
        raise SystemExit(f"unbalanced comment or string in {relative}")
    return "".join(chars)


# The package sources, then the Lean sources that this record retains and that
# a downstream package builds.
audited = [(path, str(path.relative_to(ROOT))) for path in sorted(ROOT.rglob("*.lean"))
           if ".lake" not in path.relative_to(ROOT).parts]
audited += [(path, str(path.relative_to(REPO))) for path in sorted(EVIDENCE.rglob("*.lean"))
            if ".lake" not in path.relative_to(EVIDENCE).parts]

report = {"files": [], "forbidden": [], "proof_blocks": [], "unexpected_proof_blocks": []}
for path, relative in audited:
    source = path.read_text()
    code = remove_comments_and_strings(source, relative)
    report["files"].append({"path": relative, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    for match in re.finditer(r"\b(sorry|sorryAx|axiom|unsafe|partial|native_decide|throw|panic|unreachable)\b", code):
        report["forbidden"].append({"file": relative, "line": code.count("\n", 0, match.start()) + 1,
                                    "token": match.group()})
    for match in re.finditer(r"\bby\b", code):
        line = code.count("\n", 0, match.start()) + 1
        prefix = code[code.rfind("\n", 0, match.start()) + 1:match.start()]
        after = code[match.end():]
        proof = re.match(
            r"[ \t]*(?:kan_rfl[ \t]*(?:\n|$)|\n([ \t]+)kan_rfl[ \t]*(?:\n|$))", after)
        allowed = proof is not None
        if proof is not None:
            limit = (len(proof.group(1)) if proof.group(1) is not None
                     else len(prefix) - len(prefix.lstrip()) + 1)
            following = after[proof.end():].splitlines()
            following = next((row for row in following if row.strip()), "")
            allowed = not following or len(following) - len(following.lstrip()) < limit
        item = {"file": relative, "line": line, "body": "kan_rfl" if allowed else "unexpected"}
        report["proof_blocks"].append(item)
        if not allowed:
            report["unexpected_proof_blocks"].append(item)

report["em_dash_files"] = [relative for path, relative in audited
                          if chr(0x2014) in path.read_text()]
report["pass"] = (not report["forbidden"] and not report["unexpected_proof_blocks"]
                  and not report["em_dash_files"])
# The per-file report keeps its own name; validate.py writes the command
# sidecar of this script to source-audit.json.
(EVIDENCE / "source-audit-report.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"files": len(report["files"]), "forbidden_tokens": len(report["forbidden"]),
                  "proof_blocks": len(report["proof_blocks"]), "tactics": ["kan_rfl"],
                  "unexpected_proof_blocks": report["unexpected_proof_blocks"],
                  "em_dash_files": report["em_dash_files"], "pass": report["pass"]}))
raise SystemExit(0 if report["pass"] else 1)
