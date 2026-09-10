This record validates indexed signature translation on top of
`2c2e6e6831a0b2cf3107fa4aad392606109a2bcf`. Validation runs in the isolated
source copy at `/Users/oobi/Documents/gpt9/kanon-signature-work`.

The increment changes Lean metatheory, its public exports, regression tests
and documentation. Compiler implementation and existing gate settings are
unchanged. OCaml and runtime suites are outside this increment's validation.

| Check | Evidence |
| --- | --- |
| Entire default Lean package | `lean-build.stdout`, `.stderr` and `.json`; includes every existing root and `test.SignatureChange`. Zero errors and warnings are required. |
| Independent downstream package | `client-build` capture triple. The client imports only `KanonMeta`, checks composition and dependent elimination with independent universe levels, and uses different carriers at two indices. |
| Axiom disclosure | `axioms.stdout` contains every driver from `meta/Axioms.lean`. `axiom-audit.json` checks all reports and all 20 public signature-change declarations; only `propext`, `Classical.choice` and `Quot.sound` are permitted. |
| Source conventions | `source-audit-report.json` checks all package and client Lean sources for forbidden declarations and proof blocks. `source-audit` is the command capture triple. |
| Missing index transport | `omit-index-transport` removes the equality transport from child selection. Rejection must occur in `SignatureMap.children`. |
| Wrong selected child | `wrong-branch` selects the left branch instead of the right. `selected_right` must reject the asymmetric result. |
| Omitted permutation | `omit-permutation` keeps the original child order. `swapped_children` must reject the weighted observation. |
| Reset dependent annotation | `reset-witness` zeros the constructor annotation. `arbitrary_witness` must reject it. |

`results.json` records the final verdict and counts. `mutations.json` retains
the exact source replacements, hashes and required diagnostic ranges. Negative
controls run on temporary files and require a Lean type error in the named
declaration, so setup or dependency failures do not count as successful controls.

The regressions cover weighted translation 56, a return translation for every
natural number, an asymmetric right-branch result 2, identity, composition,
fold fusion, dependent certificates and annotations, arbitrary annotations 36
and 44, and child-order observations 20 and 17. An indexed regression retains
an arbitrary `Fin (n + 1)` witness and annotation through the nondefinitional
index equality between `n` and `0 + n`.

Dependencies retain Lean `leanprover/lean4:v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. The client uses the pinned local
dependency caches and requires the metatheory through a relative path.

From the repository root, reproduce validation with:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/validation/2026-09-09-signature-change/validate.py
python3 -I dev/validation/2026-09-09-signature-change/check_sources.py
```

Successful validation regenerates `sources.json` and `captures.json`. Before
the two builds, `validate.py` derives `client/lake-manifest.json` from
`meta/lake-manifest.json` and overwrites the staged file. It also links the
pinned dependency caches under `client/.lake/packages`. The
read-only checker verifies the retained source hashes and the complete record,
excluding ignored client build files. It does not rerun Lean or treat a hash
match alone as evidence of a new build. The staged source files are checked
against these hashes after transfer to the main repository.
