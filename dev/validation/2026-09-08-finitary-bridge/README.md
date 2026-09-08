The finite-family bridge passed validation on 2026-09-08, based on commit `0feabec9baadebc5e47645809d5e5c3d682e23f4`. Commands ran in `/Users/oobi/Documents/gpt11/kanon`; the separate downstream package is `/Users/oobi/Documents/gpt11/kanon-client`. Integration checks the destination against the baseline, copies the tested files, stages all changes and verifies every staged content hash. The integration manifest and receipt remain in `/Users/oobi/Documents/gpt11`. The record was refreshed in place on 2026-09-08 after the review round, from checkout `/Users/oobi/Documents/kanon`, so the tested snapshot is now that checkout. The four harness payloads were regenerated from that checkout with the default output directory of each check script. `client-setup.*`, `client-build.*`, `client-build-final.*` and `compiler.manifest.json` stay as the retained captures of the Codex run.

| Check | Result and retained evidence |
| --- | --- |
| Full default Lean build | PASS, 68 jobs, zero errors or warnings. All prior roots remain enabled. `lean-build.stdout`, `lean-build.json`. |
| Generic Lean regression | Exact declaration and constructor encoding, checked sample observation 48, swapped semantic children observing 27, interpretation reconstruction, 25 declaration rejection cases, empty families, repeated nullary arities and retained binder names. Included in the default build. |
| Public dependency disclosure | PASS, 128 reports including all nine new public theorems and constructed initiality. Only the existing permitted `propext`, `Classical.choice` and `Quot.sound` occur. `axioms.stdout`, `axiom-audit.json`; re-audit the retained `axioms.stdout` and the driver coverage with `check_axioms.py`. |
| Separate downstream package | PASS, 54 jobs, zero errors or warnings. Imports only `KanonMeta`, disables implicit variables, validates its own named ternary family and checks arity rejection, count observation 7, reconstruction and injectivity. `Client.lean`, `client-lakefile.lean`, `client-build-final.stdout`. |
| Lean source audit | PASS, 33 source files, zero forbidden tokens or unexpected tactic bodies. All 35 existing tactic blocks use `kan_rfl`; new proofs use term expressions. `source-audit.json`, `audit-command.stdout`; reproduce with `audit.py`. |
| OCaml build and kernel suite | PASS, zero build errors or warnings and `SUITE-KERNEL OK`. `compiler.stdout`, `compiler.manifest.json`, `kernel.stdout`, `kernel.json`. |
| Generated extraction freshness | PASS for all four natural, tree, vector and generic files. Existing generated files are unchanged. `generic-freshness.json`. |
| Generic extraction and runtime controls | PASS, 35 commands, five exact Lean certificates, four valid controls and nine rejection cases. Baseline, renamed and reordered families observe 48; swapped children observe 36; a distinct family with repeated nullary arities observes 19. Results agree across the kernel, Node and Wasmtime. `finitary-runtime-final.stdout`, `finitary-runtime-details.json`, and eleven retained files in `controls/`: four control fixtures, two rejection fixtures and five Lean certificates. |
| Existing bridge regressions | PASS for natural, tree and vector extraction and runtime checks, including their existing controls. `nat-runtime-details.json`, `tree-runtime-details.json`, `vector-runtime-details.json` and corresponding command captures. |
| House rules and diff checks | PASS, `HOUSE OK` and clean whitespace checks. `house.stdout`. |
| Static source review | Static source review of the staged increment by a review agent of the increment's own pipeline (Codex). No separate reviewer artifact is retained beyond `review.md`. No unresolved findings. Scope, corrected documentation wording and limits: `review.md`. |
| Retained command captures | Client dependency setup with `lake update` against copied local dependency caches: `client-setup.json`, `client-setup.stdout`, `client-setup.stderr`. Direct fixture run on both hosts, observing 48: `generic-runtime.json`, `generic-runtime.stdout`. |

The pinned toolchain and dependencies remain Lean `v4.33.0-rc1`, kan-tactics `3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory `cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Client setup ran `lake update` against copied local dependency caches. It did not change these pins. Its first build exposed missing explicit `Fin 2` annotations in the new client; `client-build.*` retains that failed attempt. `client-build-final.*` records the corrected client. `finitary-runtime.*` retains the earlier harness run. `finitary-runtime-final.*` records the later run that the generic extraction row attests. All twelve hashes in the final detailed report match the tested files.

The command JSON records retain argv, working directory, exit status, elapsed time and output hashes. `sources.json` identifies the final changed source files and downstream client. The broad 21-leg compiler battery was not repeated because compiler implementation, kernel rules, erasure and Wasm code did not change; its earlier validation remains in `dev/M1-BUILD-LOG.md`.

Reproduce from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_finitary.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_tree.py
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_vector.py
kanon-wait run -- kanon-exec run --budget 4000 -- _build/default/test/main.exe test
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/house.sh
python3 -I dev/validation/2026-09-08-finitary-bridge/audit.py
python3 -I dev/validation/2026-09-08-finitary-bridge/check_axioms.py
```

The separate client requires the repository's `meta` package through a local path and builds the retained `Client.lean` with the same pinned toolchain. Generic raw decoding, indexed and mutual declarations, payload fields, open typed terms, checker and compiler preservation, the internal Kan-only requirement and M1 exit ratification remain open.
