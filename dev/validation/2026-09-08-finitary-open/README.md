The open finite-family constructor fragment passed validation on 2026-09-08,
based on commit `0f7204c3bcbe3dcbcba5ef7d0b9ac273f6c43b73`. Recorded commands ran
in `/Users/oobi/Documents/gpt4/kanon-open-terms/work`, except the dependency
cache copy, whose command JSON records its own working directory. The
independent downstream package is
`/Users/oobi/Documents/gpt4/kanon-open-terms/client`.

| Check | Result and retained evidence |
| --- | --- |
| Full default Lean package | PASS, 74 jobs, zero errors or warnings. Both open-fragment regression roots were added; all previous roots remain enabled. `lean-build.stdout`, `lean-build.json`. |
| Open-fragment regressions | PASS, computational observations distinguish variable permutation, repetition and ordered children. Tests change context size, close variables, exercise raw substitution, and instantiate generic structural and semantic laws. Decoder tests cover boundary and larger variable indices, nested failures, empty contexts and signatures, arbitrary arity, renamed/reordered constructors and every unsupported raw term constructor. Included in the default build. `open-regressions.stdout` and `open-regressions.json` record the run of `meta/test/MuFinitaryOpen.lean`; the default build in `lean-build.stdout` covers `meta/test/MuFinitaryOpenDecode.lean`. |
| Independent downstream package | PASS, 57 jobs, zero errors or warnings. Imports only `KanonMeta`, defines its own four-child family and proves decoding, scope rejection, substitution composition, raw and semantic substitution laws, semantic observation and closed agreement. `Client.lean`, `client-lakefile.lean`, `client-manifest.json`, `client-toolchain`, `client-build.stdout`. |
| Proof dependency disclosure | PASS, 158 reports including all 25 new public laws. Only `propext`, `Classical.choice` and `Quot.sound` occur. `axioms.stdout`, `axiom-audit.json`, `axiom-audit-command.stdout`, `check_axioms.py`. |
| Lean source audit | PASS, 39 files, zero forbidden tokens or unexpected tactic blocks. New proofs use term expressions; the 35 existing tactic blocks use `kan_rfl`. `source-audit.json`, `source-audit-command.stdout`, `audit.py`. |
| Compiler and kernel suite | PASS, zero compiler errors or warnings, `PARSE-OK 127/127`, `SUITE-KERNEL OK`. `compiler.stdout`, `kernel.stdout`. |
| Extraction freshness | PASS, the existing natural, tree, vector and finite-family exports match generated Lean syntax. `freshness.json`. |
| Existing finite-family harness | PASS, all 35 subprocess checks, five Lean decoder certificate runs (the five `*-certificate` observations of `finitary-details.json`) with its 13 `decoder_certificate_checks`, four valid source controls and nine source/invocation rejections. Kernel, Node and Wasmtime observations agree. `finitary.stdout`, `finitary-details.json`. Full subprocess captures remain under `.gatework/mu-finitary-bridge` in the writable checkout. |
| House rules and source review | PASS, `HOUSE OK`; separate static review found no correctness defects or scope overclaims. `house.stdout`, `review.md`. |

The pinned dependencies remain Lean `v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac` and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Dependency caches were copied from
the local kanon checkout, including Git metadata so Lake could recognize their
existing URLs and pins. No dependency pins were updated. `client-cache.json`,
`client-cache.stdout` and `client-cache.stderr` record that copy.

Reproduce from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- _build/default/test/main.exe test
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_finitary.py
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/house.sh
python3 -I dev/validation/2026-09-08-finitary-open/audit.py
python3 -I dev/validation/2026-09-08-finitary-open/check_axioms.py
python3 -I dev/validation/2026-09-08-finitary-open/check_sources.py
```

To reproduce the client, use the retained client files as a separate Lake
package and adjust its local dependency path to the current `meta` package.
Command JSON files retain original arguments, working directories, exit statuses
and output counts. `sources.json` fingerprints the tested source files;
`captures.json` fingerprints the retained evidence. These checks verify the
retained records; a fresh axiom run must replace `axioms.stdout` before auditing
its new output. Refreshed in place on 2026-09-08 after the review round, from
checkout /Users/oobi/Documents/kanon.

The 21-leg compiler battery was not repeated because kernel, elaborator,
erasure, emitter and runtime sources did not change. This increment proves
substitution for homogeneous contexts of the finite direct-recursion constructor
fragment. General typed and dependent substitution, indexed and mutual
declarations, payload fields, recursive programs, compiler preservation, the
internal Kan-only requirement and M1 exit ratification remain open.
