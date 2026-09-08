Validation passed on 2026-09-07 for the finite branching increment, based on compiler checkout `e9c1ba7`. The tested package is `/Users/oobi/Documents/gpt4/kanon-finite-branching/work/meta`. Source hashes are retained in `source-audit.json`. The record was refreshed in place on 2026-09-07 after the review round from checkout ROOT, so the tested package is then `ROOT/meta`.

| Check | Result |
| --- | --- |
| Full default Lake build | 55 jobs, zero errors and warnings. All four existing regression roots and both new roots remain enabled. Output: `build.log`. |
| Public axiom driver | Exit 0. New preservation and initiality report exactly `propext`, `Classical.choice`, and `Quot.sound`. The driver also discloses the finitary helpers and the finite bound helper, and no report names another axiom. Output: `axioms.log`. |
| Separate downstream Lake package | 50 jobs, zero errors and warnings. Imports only `KanonMeta` and constructs generic preservation, initiality, and dependent beta. Source: `Client.lean`; output: `client.log`. |
| Source audit | 20 Lean source files, zero forbidden tokens, zero unexpected tactic bodies, and zero em dash characters. All 20 tactic bodies are existing `kan_rfl` proofs. |
| Static source review | Static review by the increment author. No separate reviewer artifact is retained. No existing test root or gate was removed or weakened; see the enabled roots in `meta/lakefile.lean` and the build in `build.log`. |

The package commands used the pinned `leanprover/lean4:v4.33.0-rc1` toolchain. From `meta`, the validation commands are:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 env lean Axioms.lean
```

The independent client uses a local Lake `require` on the tested `meta` directory, the same pinned toolchain, and `autoImplicit := false`. Its complete source is retained here. It was built with the same wrapped Lake command from `/Users/oobi/Documents/gpt4/kanon-finite-branching/evidence/client`.

Dependency sources were reused from the existing validated cache and verified free of tracked changes. The dependency revisions remain `3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac` for kan-tactics and `cc6ced1086a3b5b14c43bd58b5ecbabef09ab201` for comp-cat-theory. No dependency update was needed. Run `python3 -I dev/validation/2026-09-07-finitary/audit.py` from the checkout root to refresh the source audit.

The static review covered these final source hashes:

```text
472bee290ee82479828046d126487e70c648041c2de5f9622261e16c63e47fec  meta/KanonMeta/FinitaryConstruction.lean
87a564b67e8aa841aeb9a6af08ddd28cac73014f8a9c34443a38925b01380daa  meta/KanonMeta/FiniteBound.lean
d711e80120a2ee0a18a4ea19c0c50c472ebccef6cbc4843905ce209f1d58beba  meta/test/FinitaryConstruction.lean
6f5546347f5e25d304acda0599be3df700b9649f0948d0257bcf1b3a00be0429  meta/test/FinitarySequence.lean
```

No compiler or Wasm source changed, so their gate battery was not repeated. These checks establish Lean elaboration and the stated external semantics. They do not establish an interpretation of checked `SMu` syntax or compiler preservation.
