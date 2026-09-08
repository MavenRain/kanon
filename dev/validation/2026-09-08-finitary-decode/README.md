The finite-family raw-term decoder passed validation on 2026-09-08, based on
commit `d6dcbbc1a8b1da9b66f543923a90b7be3ba4c0b5`. Commands ran in
`/Users/oobi/Documents/gpt2/kanon-continue`; the separate downstream package is
`/Users/oobi/Documents/gpt2/kanon-decode-client`.

| Check | Result and retained evidence |
| --- | --- |
| Full default Lean package | PASS, 70 jobs, zero errors or warnings. Every existing regression root remains enabled, with the new decoder root added. `lean-build.stdout`, `lean-build.json`. |
| Decoder regressions | PASS, 42 theorems covering generated raw syntax, exact reconstruction, generic roundtrip and injectivity, checked declaration retention, semantic folds, every raw term constructor, malformed nested children, empty signatures, multiple nullary constructors, renamed/reordered declarations and arity five. Included in the default build. |
| Separate downstream package | PASS, 55 jobs, zero errors or warnings. Imports only `KanonMeta`, validates its own four-child family, decodes raw syntax and proves generic roundtrip, injectivity and semantic observation laws. `Client.lean`, `client-lakefile.lean`, `client-manifest.json`, `client-toolchain`, `client-build.stdout`. |
| Public proof dependency disclosure | PASS, 133 reports. All five new public decoder theorems are disclosed; only `propext`, `Classical.choice` and `Quot.sound` occur. `axioms.stdout`, `axiom-audit.json`, `check_axioms.py`. |
| Lean source audit | PASS, 35 files, zero forbidden tokens or unexpected tactic blocks. New proofs use term expressions; the 35 existing tactic blocks use `kan_rfl`. `source-audit.json`, `source-audit-command.stdout`, `audit.py`. |
| OCaml build and kernel suite | PASS, zero build errors or warnings, `PARSE-OK 127/127` and `SUITE-KERNEL OK`. `compiler.stdout`, `kernel.stdout` and command JSON records. |
| Extraction freshness | PASS for the natural, tree, vector and finite-family generated files. `freshness.json`. |
| Final finite-family harness | PASS, all 35 subprocess checks, five Lean decoder certificates, four valid source controls and nine source/invocation rejections. The baseline, renamed and reordered programs observe 48, the swapped-child program observes 36 and the multiple-nullary program observes 19, with agreement across kernel, Node and Wasmtime. `finitary-final.stdout`, `finitary-details.json`, and the eleven fixtures/certificates under `controls/`. |
| House rules | PASS, `HOUSE OK` over the five house legs. `house.stdout`. |
| Static source review | No remaining findings. One description of error precedence was corrected. Scope, reviewer role and limits are recorded in `review.md`. |

The extended harness checks exact reconstructed encodings and an independent
observation sensitive to declaration positions and child order. Each of its five
certificates checks a reversed-child control, all decoder error classes,
unsupported children at every root position, and all eleven non-introduction
term forms. The existing raw declaration, sample metadata, kernel and host checks
remain in place.

The dependency pins remain Lean `v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Client setup used copied local
dependency caches, as recorded in `client-setup.*`. The source and dependency
pins were not updated. Files named `*-initial.*` retain earlier successful
checks. `finitary-initial.*` records an earlier finite-family harness run.
`decoder-regression-initial.*` records an earlier run of the decoder regression
root `meta/test/MuFinitaryDecode.lean`. The full package and final harness
captures supersede both and attest the final sources.

Command JSON files retain the command arguments, working directory, exit status
and output counts. `sources.json` identifies the tested source hashes;
`captures.json` identifies retained evidence bytes. Reproduce their consistency
check with `python3 -I dev/validation/2026-09-08-finitary-decode/check_sources.py`.
The integration manifest and staging receipt are retained beside the writable
checkout as `kanon-decode-integration.json` and `kanon-decode-staging.json`.

The record was refreshed in place on 2026-09-08 at 12:25 PDT, after the review
round, from the checkout `/Users/oobi/Documents/kanon`. The harness payload
`finitary-details.json` and the retained certificates under `controls/` come
from a run of the check script with its default output directory. The refreshed
sources are therefore the sources of that checkout.

Reproduce from the repository root using the pinned toolchain:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check_finitary.py
kanon-wait run -- kanon-exec run --budget 4000 -- _build/default/test/main.exe test
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/house.sh
python3 -I dev/validation/2026-09-08-finitary-decode/audit.py
python3 -I dev/validation/2026-09-08-finitary-decode/check_axioms.py
```

The separate client builds the retained `Client.lean` with a local path
dependency on the repository's `meta` package. Adjust that path when reproducing
it in a different checkout.

The broad 21-leg compiler battery was not repeated: kernel, elaborator, erasure,
emitter and runtime sources did not change. This increment establishes decoding
for the existing closed finite direct-recursion fragment. General indexed and
mutual declarations, payload fields, open typed terms and substitution, checker
and compiler preservation, the internal Kan-only requirement and M1 exit
ratification remain open.
