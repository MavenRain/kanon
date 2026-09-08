The indexed-vector bridge passed validation on 2026-09-08, based on checkout `d9cbbeebb96a5f0656d41371d07f0872464bd650`. The tested source snapshot is `/Users/oobi/Documents/gpt1/kanon-vector-bridge/work`. Integration verifies destination preconditions, copies the tested files, stages all changes and compares each staged content hash. The integration manifest and receipt remain in `/Users/oobi/Documents/gpt1/kanon-vector-bridge`. The record was refreshed in place on 2026-09-08 after the review round, from checkout `/Users/oobi/Documents/kanon`, so the tested snapshot is now that checkout. The three runtime JSON records were regenerated from that checkout with the default output directory of each check script. `commands.json`, `axioms.json`, `freshness.log`, `house-initial.log`, `vector-initial.log`, `vector-intermediate.log`, the fourteen `*.manifest.json` files and the eight files of `controls/` stay as the retained captures of the Codex run.

| Check | Result |
| --- | --- |
| Full default Lake build | 65 jobs, zero errors or warnings. All prior regression roots remain enabled; GeneratedMuVector and MuVector are added. Output: `build.log`. |
| Scoped vector regression | 12 jobs, zero errors or warnings. Checks exact N/V records, sample and copy templates and metadata, semantic observations, payload separation and 25 decoder rejection cases. Output: `regression.log`. |
| Public axiom driver | Exit 0. Includes all 20 public MuVector theorems. The new reports use only the existing permitted `propext` and `Quot.sound`, with no new axioms. Output: `axioms.log`. |
| Separate downstream Lake package | 53 jobs, zero errors or warnings. Imports only KanonMeta, with autoImplicit disabled, and exercises decoding, semantic copy, interpretation injection and the weighted observation. Source: `Client.lean`; output: `client.log`. |
| Lean source audit | 30 files, zero forbidden tokens, zero unexpected tactic bodies and zero prohibited dash characters. The 35 existing tactic bodies remain kan_rfl; new proofs use term expressions. Report: `source-audit.json`; reproduction: `audit.py`. |
| OCaml build and kernel suite | Zero build errors or warnings; SUITE-KERNEL OK. Output: `compiler.log`, `kernel.log`. |
| Generated fixture freshness | Nat, Tree and Vector Dune freshness rules exit 0 with empty stdout and stderr, so the retained `freshness.log` is empty. The runtime checks also compare each generated source byte for byte. Command: `commands.json`. |
| Existing Nat and Tree runtime checks | Both pass on the kernel, Node and Wasmtime, including their existing controls. Reports: `nat-runtime.json`, `tree-runtime.json`. |
| Vector runtime and extraction controls | All 25 commands pass. Sample and copy observe 67; zeroed payloads observe 0; reversed payloads observe 59. Replacing recursion with the original tail preserves 67 while changing the exact body and removing the recursion marker. All three changed extracts receive Lean certificates. Wrong-result-index and wrong-tail-index controls fail both checking and extraction. Report: `vector-runtime.json`. |
| House rules | HOUSE OK. Output: `house.log`. |
| Static source review | Static source review of the staged increment by a review agent of the increment's own pipeline (Codex). No separate reviewer artifact is retained beyond `review.md`. The review found an extraction validation gap, now fixed with exact Lean certificates, and a missing Lean-build prerequisite, now documented. No remaining confirmed correctness defect or weakened gate. Scope and limits: `review.md`. |

The pinned toolchain and dependencies are unchanged: Lean `v4.33.0-rc1`, kan-tactics `3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory `cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. The initial scratch copy omitted dependency Git metadata, which caused Lake to attempt a fetch. Restoring the existing cached metadata and aligning the copied local remote restored builds without a dependency update. An initial vector control certificate expected a recursion marker even after its recursive call was removed. The exporter correctly emitted `none`; the corrected certificate checks that exact change. `commands.json` retains that failed validation and the successful final commands. The fourteen `*.manifest.json` files are kanon-exec capture manifests of the Codex run. Each one holds the artifact directory, the argv, the cwd of the tested snapshot, the exit code and the stdout and stderr byte counts, with `/Users/oobi/Documents/gpt1/kanon-vector-bridge` paths. `house-initial.log` and `vector-intermediate.log` are superseded runs. `house.log` and `vector-runtime.log` are the runs that the rows attest.

Reproduce from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_tree.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_vector.py
kanon-wait run -- kanon-exec run --budget 4000 -- _build/default/test/main.exe test
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/house.sh
python3 -I dev/validation/2026-09-08-vector-bridge/audit.py
```

The separate client package requires this repository's meta package through a local path and builds the retained Client.lean with autoImplicit disabled. The full 21-leg compiler battery is not repeated: compiler implementation, kernel rules, erasure and Wasm code are unchanged. Its earlier validation remains in `dev/M1-BUILD-LOG.md`. This increment establishes the stated fixed indexed fragment and its observations. General declaration interpretation, open typed substitution, checker and compiler preservation, full Lean parity, the internal Kan-only requirement and M1 exit ratification remain open.
