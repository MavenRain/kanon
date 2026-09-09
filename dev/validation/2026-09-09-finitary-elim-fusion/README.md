This record validates dependent fusion on top of
`988e66834059d31bfddcd38f450699326e9c203a`. The build workspace was
`/Users/oobi/Documents/gpt1/kanon-fusion`. Only Lean metatheory, regression
tests, documentation and this record change; compiler sources are unchanged.
The review round of 2026-09-09 reran the permute-children control from
`/Users/oobi/Documents/kanon`. It rewrote `mutations.json`, the
`permute-children` capture triple and `source-audit-report.json`. Every other
capture keeps its original workspace path.

| Check | Result |
| --- | --- |
| Full default Lean package | PASS, 84 jobs, zero errors or warnings. Every existing root and both new regression roots are included. `lean-build.stdout`, `lean-build.json`. |
| Independent downstream package | PASS, 62 jobs, zero errors or warnings. The binary family in `client/FusionClient.lean` imports only `KanonMeta`. Paired annotations are `(57, 57)` or `(63, 63)` at equal semantic inputs, substitution gives `(172, 172)`, and noninjective renaming gives `(32, 32)`. Dependent certificates are 16 and 86. `client-build.stdout`, `client-build.json`. |
| Dependent regressions | PASS. Ordered closed observations are 51 and 36; arbitrary open annotations are 159, 179 and 147. Actual substitution transport retains annotation 78 and certificate 27; renaming retains annotation 68 and certificate 17. Empty contexts give 51. Composed maps retain 159. Two indexed fibres retain 10 and 11, with the second fibre's witness equal to 1. Constant-fibre elimination recovers the natural fold for every input. |
| Axiom disclosure | PASS, all 196 driver reports, including all 14 new declarations. No dependencies outside `propext`, `Classical.choice`, `Quot.sound`. The eight general initiality declarations have no axiom dependencies. `axioms.stdout`, `axiom-audit.json`. |
| Source conventions | PASS, 51 Lean files, no forbidden tokens or unexpected proof blocks. The 35 existing tactic blocks use `kan_rfl`; all new proofs are term expressions. The audit includes the retained client. The per-file report lists all 51 audited paths with their sha256. `source-audit-report.json`, `source-audit.stdout`. |
| Mutation controls | PASS, 2/2 rejected by Lean at the edited declarations. Resetting annotations to zero invalidates the displayed constructor law. Reversing the open term's child order, in the statement and in the proof, invalidates the observation 159. Each starts from the passing regression source and runs in a temporary file. `mutations.json`, `reset-witness.stdout`, `permute-children.stdout`. |

Dependencies retain Lean `leanprover/lean4:v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Validation reused local dependency
caches. The client requires the package through a relative path so its retained
configuration also works at the repository destination.

From the repository root, reproduce the checks with:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/validation/2026-09-09-finitary-elim-fusion/validate.py
```

This command refreshes captured evidence, including elapsed times. It deliberately
leaves the source and capture fingerprints unchanged. Check the sealed record
without changing any files with:

```sh
python3 -I dev/validation/2026-09-09-finitary-elim-fusion/check_sources.py
```

`sources.json` pins the package sources, configuration and updated documentation.
`captures.json` pins every retained record file except itself, excluding Lake
caches. Refreshing evidence requires review and resealing these fingerprints.
Earlier committed validation records remain historical snapshots of their own
source revisions.

These checks concern semantic fusion over a fixed base algebra. They do not
establish compiler preservation, full dependent-context interpretation, an
internal Kan-only construction or M1 exit ratification. The OCaml and Wasm
suites were not rerun because their inputs did not change.
