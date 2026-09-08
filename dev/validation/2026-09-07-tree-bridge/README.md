The binary-tree bridge passed validation on 2026-09-07, based on checkout `ddffb0fe32a471f03715771a30ee98f6e7f6f4d4`. The tested source snapshot is `/Users/oobi/Documents/gpt4/kanon-tree-bridge/work`. Integration verifies destination preconditions and copies the tested bytes before staging, then compares the staged content hashes. The record was refreshed in place on 2026-09-08 after the review round, from checkout `/Users/oobi/Documents/kanon`, so the tested snapshot is now that checkout. The two runtime JSON records were regenerated from that checkout with the default output directory of each check script. `commands.jsonl` and `freshness.json` stay as the retained captures of the Codex run.

| Check | Result |
| --- | --- |
| Full default Lake build | 62 jobs, zero errors or warnings. All nine previous regression roots remain enabled; `GeneratedMuTree` and `MuTree` are added. Complete output: `build.log`. |
| Public axiom driver | Exit 0. Reports all 17 public MuTree theorems and its constructed initiality. Raw syntax and structural fold laws have no axioms. Semantic laws disclose only the existing permitted `propext`, `Classical.choice` and `Quot.sound`. Complete output: `axioms.log`. |
| Separate downstream Lake package | 52 jobs, zero errors or warnings. Imports only `KanonMeta`, uses the public decoder, fold, mirror and injection theorems, with `autoImplicit := false`. Source: `Client.lean`; output: `client.log`. |
| Lean source audit | 27 files, zero forbidden tokens, zero unexpected tactic bodies, zero prohibited dash characters. The 35 existing tactic bodies remain `kan_rfl`; all new proofs use term expressions. Hashes and findings: `source-audit.json`; reproduction: `audit.py`. |
| OCaml build | Zero errors or warnings, including the changed exporter. Complete output: `compiler.log`. |
| Generated fixture freshness | Nat and Tree Dune freshness rules exit 0 with empty stdout/stderr. Captured command record: `freshness.json`. The unchanged Nat generated file also matches its previous bytes. The `extraction` observation of each runtime JSON record compares the exporter output with the generated file byte for byte. |
| Kernel regression suite | `SUITE-KERNEL OK`. Complete output: `kernel.log`. |
| Natural bridge regression | `MU-BRIDGE OK`, original answer 6 and changed-recursion answer 3 on the kernel, Node and Wasmtime. Commands, exit codes, pass flags and source hashes: `nat-runtime.json`. |
| Binary-tree bridge and controls | All 14 recorded commands pass. The sample observes 17; its mirror observes 13. Keeping child order yields 17, and dropping the right input yields 5, agreeing on the kernel, Node and Wasmtime. Each fixture discloses no axioms, and each control changes the exported recursive body. Commands, exit codes, pass flags, control flags and source hashes: `tree-runtime.json`. |
| House rules | `HOUSE OK`. Complete output: `house.log`. |
| Static source review | Static review by a review agent of the increment's own pipeline (Codex). No confirmed correctness defect or weakened gate. No separate reviewer artifact is retained beyond `review.md`. Scope and limits: `review.md`. |

The toolchain remains `leanprover/lean4:v4.33.0-rc1`. The kan-tactics and comp-cat-theory revisions remain `3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac` and `cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. The initial scratch copy omitted the cached dependency Git metadata, so it was restored from the existing checkout before the successful package build. No dependency update was needed. The separate client requires the tested package through its local path and sets `autoImplicit := false`. `commands.jsonl` retains the eight captured build, check and axiom invocations, including an initial axiom-driver invocation with the wrong relative file path, followed by the corrected successful invocation. The binary-tree commands are in `tree-runtime.json` and the freshness command is in `freshness.json`.

Reproduce from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_tree.py
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
python3 -I dev/validation/2026-09-07-tree-bridge/audit.py
```

The full 21-leg compiler battery is not repeated because the compiler implementation, kernel, erasure and Wasm sources are unchanged. Its earlier validation remains recorded in `dev/M1-BUILD-LOG.md`. This increment establishes the stated fixed-family constructor and mirror semantics, extraction freshness and concrete runtime agreement. It does not establish general declaration interpretation, checker or compiler preservation, indexed substitution, full Lean parity, the strict internal Kan-only requirement or M1 exit ratification.
