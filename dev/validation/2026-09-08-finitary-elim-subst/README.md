This increment proves dependent structural induction is natural under
substitution and renaming in the homogeneous finite-family constructor
fragment. Its baseline is `046689a78ef6708404bd190dc86845cbee0bb36f`.
Validation runs in `/Users/oobi/Documents/gpt3/kanon-next`; the separate
downstream package is `/Users/oobi/Documents/gpt3/kanon-subst-client`.
The coherence increment changed `meta/Axioms.lean`, `meta/KanonMeta.lean` and
`meta/lakefile.lean` after this record was captured. The review of 2026-09-09
refreshed the axiom disclosure, both audits and both manifests from the final
tree. The build and client captures retain the original run.

The new regression fibre combines a semantic equality certificate with an
unconstrained natural number. Two variables denote the same semantic value
but carry different data. This checks that the laws retain arbitrary supplied
witnesses instead of replacing them with the chosen semantic eliminator.
Further cases cover ordered recursive children, repeated variables,
non-injective renaming, nested substitutions and empty contexts.

The default package build includes the new regression root and all existing
roots. The downstream client imports only `KanonMeta` and defines its own
signature and dependent fibre. `axioms.stdout` retains a fresh disclosure of
the package API; `check_axioms.py` checks every new public declaration and
rejects axioms outside `propext`, `Classical.choice` and `Quot.sound`.
`audit.py` scans package and retained Lean sources for forbidden declarations
and tactic blocks outside the kan-tactics convention.

| Check | Result and retained evidence |
| --- | --- |
| Full default Lean package | PASS, 78 jobs, zero errors or warnings. Includes every prior root and `test.MuFinitaryElimSubst`. `lean-build.stdout`, `lean-build.json`. |
| Dependent witness regressions | PASS. All six new laws are exercised. Distinct supplied data produce 159 and 179; reordered children produce 147. Transported substitution produces 78, collapsed renaming 68, nested and composed substitution 2577, closed substitution 27, and empty-context induction 51. Included in the default build. |
| Independent downstream client | PASS, 59 jobs, zero errors or warnings. Its independent ternary family has semantic measurement 2422 and transported annotation 4844; changing the supplied annotation gives 6055. Renaming produces 444. `Client.lean`, `client-build.stdout`, `client-build.json`. |
| Fresh proof dependency disclosure | PASS, 182 reports, including all six new public laws. No missing disclosure or axiom outside `propext`, `Classical.choice`, `Quot.sound`. `axioms.stdout`, `axiom-audit.json`, `axiom-audit-command.stdout`. |
| Source audit | PASS, 47 Lean files, zero forbidden tokens or unexpected proof blocks. The 35 existing tactic blocks use `kan_rfl`; new proofs use term expressions. `source-audit.json`, `source-audit-command.stdout`. |
| Independent static review | No concrete correctness defects found in the core proofs, regressions or client. `review.md`. |

The toolchain remains `leanprover/lean4:v4.33.0-rc1`, with kan-tactics pinned to
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac` and comp-cat-theory to
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Existing dependency caches were
copied locally, retaining Git metadata; no dependency pin changed.

Reproduce from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
python3 -I dev/validation/2026-09-08-finitary-elim-subst/audit.py
python3 -I dev/validation/2026-09-08-finitary-elim-subst/check_axioms.py
python3 -I dev/validation/2026-09-08-finitary-elim-subst/check_sources.py
```

The axiom checker reads the retained `axioms.stdout`. To validate a new run,
replace that file with the complete fresh disclosure before invoking the
checker. For a downstream build, place `Client.lean`, `client-lakefile.lean`,
`client-manifest.json` and `client-toolchain` in a separate package, renaming
the last three to Lake's standard filenames and adjusting the local package
path if needed.

Command JSON records retain arguments, working directories, exit statuses,
and output counts. `sources.json` fingerprints the package Lean sources and
pins that existed when this record was captured. `captures.json` fingerprints
this record's files. `check_sources.py`
compares both manifests with the files on disk. Re-running audits after edits
requires refreshing the manifests as well.

This increment changes the external Lean model and documentation. The compiler,
checker, elaborator, erasure, emitter and runtime sources retain their baseline
bytes, so the compiler battery is outside this validation scope. The result
is limited to homogeneous contexts and `Type 0` motives with explicit
propositional transport. General typed interpretation, dependent contexts,
compiler preservation, the internal Kan-only requirement and M1 exit
ratification remain open.
