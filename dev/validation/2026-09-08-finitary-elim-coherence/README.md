This increment compares the successive and composed semantic transport routes
for dependent induction in the homogeneous finite-family constructor fragment.
It builds on `046689a78ef6708404bd190dc86845cbee0bb36f` and the existing staged
dependent substitution increment. Validation ran in
`/Users/oobi/Documents/gpt1/kanon-coherence`; the separate downstream package
was `/Users/oobi/Documents/gpt1/kanon-coherence-client`.

The six public laws include pointwise environment and witness congruence,
coherence between direct and iterated replacement witnesses, two successive
substitution transports, and comparison with the three transports in the
composed route. Renaming has the corresponding successive and composed laws.
The proofs use the existing naturality laws and environment congruence, while
retaining arbitrary `Type`-valued witness data.

| Check | Result and retained evidence |
| --- | --- |
| Full default Lean package | PASS, 80 jobs, zero errors or warnings. Includes every existing root and `test.MuFinitaryElimCoherence`. `lean-build.stdout`, `lean-build.json`. |
| Transport regressions | PASS. All six APIs are exercised. Two successive transports retain annotations 2577 and 2849 at the same semantic inputs; the dependent certificate is 299. The three-transport route also returns 2577. Ordered children give 2574, collapsed renaming gives 187 or 221, identity substitution gives 159, closing substitution gives 27, and empty contexts give 51. Included in the default build. |
| Independent downstream package | PASS, 62 jobs, zero errors or warnings. Its own binary family, ordered algebra and dependent fibre use only the public package. Sequential and composed routes retain annotation 10064; changing supplied witnesses yields 10952. The dependent certificate is 2368, renaming gives 473, and the empty context gives 16. Complete source and configuration under `client/`; `client-build.stdout`, `client-build.json`. |
| Fresh axiom disclosure | PASS, 182 reports, including all six new laws. No missing disclosure or axiom outside `propext`, `Classical.choice`, `Quot.sound`. `axioms.stdout`, `axiom-audit.json`, `axiom-audit-command.stdout`. |
| Source convention audit | PASS, 48 Lean files, zero forbidden tokens or unexpected proof blocks. The 35 existing tactic blocks use `kan_rfl`; the new proofs use term expressions. Includes the retained downstream sources and configuration. `source-audit.json`, `source-audit-command.stdout`. |
| Independent static review | No concrete correctness defects found in the new proof module, regressions or client. `review.md`. |

The package keeps Lean `leanprover/lean4:v4.33.0-rc1`, kan-tactics
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Dependency caches and package build
artifacts were copied locally. Lake reused valid cached jobs and compiled
changed sources. Dependency pins were not changed and no fetch was needed.

Reproduce the package checks from the repository's `meta` directory:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 env lean Axioms.lean
```

From the repository root, run the record checkers:

```sh
python3 -I dev/validation/2026-09-08-finitary-elim-coherence/audit.py
python3 -I dev/validation/2026-09-08-finitary-elim-coherence/check_axioms.py
python3 -I dev/validation/2026-09-08-finitary-elim-coherence/check_sources.py
```

The axiom checker reads the retained `axioms.stdout`. For a new validation,
replace that file with the complete fresh disclosure before checking it.
`sources.json` fingerprints the tested package sources and dependency pins;
`captures.json` fingerprints the retained evidence, including nested client
files. The source checker detects changed files and additional capture files.
The command JSON records retain arguments, working directories, exit status
and output counts. `scoped-build.*` retains the first module compilation.

To rebuild the client, copy `client/` to a separate writable package and adjust
the local kanon-meta path in its Lake configuration and manifest to the
checkout under test. Retain the recorded toolchain and dependency revisions,
then run its default Lake build.

Motives remain in `Type 0`, with homogeneous contexts for one unindexed family
and direct recursive fields. Dependent contexts, compiler typing and
recursive-call interpretation, indexed and mutual declarations, payloads,
compiler preservation, the internal Kan-only requirement and M1 exit
ratification remain open. This increment changes metatheory and its evidence;
the compiler suites were outside its validation scope.
