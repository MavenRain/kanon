This record validates dependent base change on top of
`45f74406c4574d7cb00d8944cebf79193cd01f9b`. Validation ran in
`/Users/oobi/Documents/gpt3/kanon-base-change`. The changes concern Lean
metatheory, regression tests, documentation and this record.
The review round of 2026-09-09 reran the omit-transport, reset-witness and
drop-second-shift controls from `/Users/oobi/Documents/kanon`. It rewrote
`mutations.json`, the three control capture triples and
`source-audit-report.json`. Every other capture keeps its original workspace
path.

| Check | Result |
| --- | --- |
| Full default Lean package | PASS, 88 jobs, zero errors or warnings. All existing roots and both new regression roots are included. See `lean-build.stdout` and `lean-build.json`. |
| Independent downstream package | PASS, 64 jobs, zero errors or warnings. `client/BaseChangeClient.lean` imports only `KanonMeta`, constructs its own initial source, and changes base to a noninitial numeric target at two indices. Dependent certificates are 5 and 13, with annotations 105 and 113. See `client-build.stdout` and `client-build.json`. |
| Generic regressions | PASS. A single shift gives certificate 4 and annotation 17; successive shifts give certificate 5 and annotation 19. The successive and composed routes agree without intermediate or target initiality. Changing carriers between natural numbers and boxed naturals preserves elimination. Identity and composed displayed maps retain arbitrary witnesses; those two tests pin the map action only. A composite of two non-identity annotation maps computes 18 through fusion over the composed base map, and identity base change reaches count 3. |
| Finite-family regressions | PASS. A base map into the weighted numeric fold retains closed observations 51 and 36, supplied open annotations 159 and 179, and dependent certificate 17. Substitution retains 78 and noninjective renaming retains 68. Constructed elimination agrees with a lawful target section at 51, and with the target eliminator along the identity base map at 51. |
| Axiom disclosure | PASS, all 219 reports including all 23 new public declarations. No dependencies outside `propext`, `Classical.choice`, `Quot.sound`. Eleven general declarations have no axiom dependencies; the two using target elimination depend on `Quot.sound`. The private transport helper is covered transitively. See `axioms.stdout`, `axiom-audit.json` and `results.json`. |
| Source conventions | PASS, 55 Lean files including the retained client. No forbidden tokens, unexpected proof blocks or em dash characters. The 35 existing tactic blocks use `kan_rfl`; all new proofs are term expressions. See `source-audit-report.json`. The driver capture is `source-audit.stdout`; its sidecar `source-audit.json` is the command record and the report is `source-audit-report.json`. |
| Mutation controls | PASS, 3/3 rejected at the edited declarations. Omitting pullback transport fails the dependent constructor type; resetting annotations to zero fails the displayed constructor law; replacing the composed annotation 19 with 17 fails its observation theorem. See `mutations.json` and each control's captured output. |

Dependencies retain Lean `leanprover/lean4:v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Builds reused local dependency
caches. The client requires `meta` through a relative path.

From the repository root, reproduce validation with:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/validation/2026-09-09-finitary-elim-base-change/validate.py
```

This refreshes captures and elapsed times while leaving their sealed fingerprints
unchanged. To check the retained evidence without modifying it, run:

```sh
python3 -I dev/validation/2026-09-09-finitary-elim-base-change/check_sources.py
```

`sources.json` pins package sources, configuration and updated documentation.
`captures.json` pins every retained record file except itself, excluding Lake
caches. Refreshing the record requires reviewing and resealing the fingerprints.
Earlier validation records remain historical snapshots of their own revisions.

These checks concern maps over one polynomial and the homogeneous finite-family
constructor fragment. They do not establish compiler preservation, general
dependent contexts, an internal Kan-only construction or M1 exit ratification.
The OCaml and Wasm suites were not rerun because their inputs did not change.
