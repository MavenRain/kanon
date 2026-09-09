The finite-family dependent elimination increment passed validation on
2026-09-08, based on `df7b5fab424f384a9f52dc8c1d953ff7933f87a3`.
Commands ran in `/Users/oobi/Documents/gpt13/kanon-next`; the independent
downstream package is `/Users/oobi/Documents/gpt13/kanon-elim-client`.

| Check | Result and evidence |
| --- | --- |
| Full default Lean package | PASS, 76 jobs, zero errors or warnings. The new regression root is enabled alongside every prior root. `lean-build.stdout`, `lean-build.json`. |
| Generic dependent uniqueness | PASS. An independent `Nat.rec` section with `Fin (n + 1)` fibres agrees with the chosen eliminator. A two-index model has different dependent fibres and results at its two indices. Included in `lean-build.stdout`. |
| Finite-family elimination | PASS. Four ordered children produce 51; permuting the first and last produces 36. The dependent result retains the semantic observation as an equality certificate; zero cannot inhabit the sample fibre. An independently defined lawful section agrees by uniqueness. Open variable witnesses produce 27, and the empty signature has no semantic inhabitants. Both reification directions are exercised. Included in the default regression build. |
| Independent downstream client | PASS, 58 jobs, zero errors or warnings. Imports only `KanonMeta`, defines its own family and dependent fibre, and proves beta, structural agreement, an observation of 13, a nonzero control and the carrier roundtrip. `Client.lean`, `client-build.stdout`, `client-build.json`, `client-lakefile.lean`, `client-manifest.json`, `client-toolchain`. |
| Proof dependency disclosure | PASS, 170 reports, including every new public definition and law. Only `propext`, `Classical.choice` and `Quot.sound` occur. The audit reads the list of declarations to disclose from the module sources. It reads the retained `axioms.stdout`, so a fresh disclosure run is the freshness check. `axioms.stdout`, `axiom-audit.json`, `axiom-audit-command.stdout`, `check_axioms.py`. |
| Source audit | PASS, 43 Lean files, zero forbidden tokens or unexpected tactic blocks. The scan covers the package sources and the Lean files that this record retains. The 35 existing tactic blocks use `kan_rfl`; new proofs use term expressions. `source-audit.json`, `source-audit-command.stdout`, `audit.py`. |
| Independent static review | No correctness defects or concrete coverage gaps found. `review.md`. |

Lean remains pinned to `v4.33.0-rc1`, kan-tactics to
`3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac`, and comp-cat-theory to
`cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Dependency caches were reused
locally, with Git metadata retained. No dependency pins changed.

Reproduce the package and disclosure from the repository root:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean meta/Axioms.lean
python3 -I dev/validation/2026-09-08-finitary-elim/audit.py
python3 -I dev/validation/2026-09-08-finitary-elim/check_axioms.py
python3 -I dev/validation/2026-09-08-finitary-elim/check_sources.py
```

`check_axioms.py` audits the retained `axioms.stdout`; replace that file with
fresh disclosure output before auditing a new run. `audit.py` reuses the
previous increment's source scanner. For a downstream build, place the retained
client files in a separate Lake package and adjust its dependency path to
the current `meta` directory.

Command JSON files retain the original working directories, arguments, exit
statuses and output counts. `sources.json` fingerprints the tested Lean sources
and package pins; `captures.json` fingerprints the retained evidence. Hashes
allow the tested Lean sources and package pins to be compared with the
validated checkout. Refreshed in place on 2026-09-08 after the review round,
from checkout /Users/oobi/Documents/kanon. Refreshed again in place on
2026-09-08 at 20:02 after this fix round, from checkout
/Users/oobi/Documents/kanon.

Compiler, checker, elaborator, erasure, emitter and runtime sources did not
change. The staged path list of the increment is the evidence for that
statement, because this manifest holds no compiler fingerprint. The 21-leg
compiler battery was therefore not repeated. These proofs cover the external
constructed finite-family model, with `Type 0` motives and propositional
computation. General typed and dependent interpretation,
compiler preservation, the internal Kan-only requirement and M1 exit
ratification remain open.
