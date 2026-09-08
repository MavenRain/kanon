Validation passed on 2026-09-07 for the natural-family bridge, based on checkout `ca31fca0f1cb29ea69cd9ed2de8301815f608585`. The tested source snapshot is `/Users/oobi/Documents/gpt4/kanon-mu-bridge/work`. Integration compares destination hashes before copying these tested sources and staging the changes. The record was refreshed in place on 2026-09-07 after the review round from checkout `/Users/oobi/Documents/kanon`, so the tested snapshot is then that checkout.

| Check | Result |
| --- | --- |
| Full default Lake build | 59 jobs, zero errors or warnings. All six existing regression roots remain enabled; `MuSyntax`, `GeneratedMuNat` and `MuNat` are added. Complete output: `build.log`. |
| Public axiom driver | Exit 0. The driver discloses all 29 public theorems of `KanonMeta.MuNat`. New raw substitution, decoder roundtrip, encoder injection and value fold declarations have no axioms. New semantic fold, case, observation and separation declarations use exactly `Quot.sound`. Existing finitary declarations retain their disclosed dependencies. Output: `axioms.log`. |
| Separate downstream Lake package | 51 jobs, zero errors or warnings. Imports only `KanonMeta`, checks the public decoder, fold correspondence and separation. Source: `Client.lean`; output: `client.log`. |
| Lean source audit | 24 files, zero forbidden tokens, zero unexpected tactic bodies, zero em dash characters. All 35 tactic bodies are `kan_rfl`; other proofs are term expressions. Hashes: `source-audit.json`. |
| OCaml build | Zero errors and warnings, including the new exporter. Output: `compiler.log`. |
| Generated fixture freshness | `zsh dev/dune.sh runtest dev/mu-bridge` exits 0. Dune regenerates the Lean data from the checked fixture and compares the bytes. The retained equivalent is the `extraction` observation of `runtime.json`, which compares exporter output with `meta/test/GeneratedMuNat.lean` byte for byte. |
| Kernel regression suite | `SUITE-KERNEL OK`, including all existing fixtures. Complete output: `kernel.log`. |
| Fixture and changed-recursion control | `MU-BRIDGE OK`. Original answer 6 and control answer 3 agree on kernel, Node and Wasmtime; original axiom disclosure is empty. The changed recursive body produces different exported bytes. Commands, outputs and relevant hashes: `runtime.json`. |
| House rules | `HOUSE OK`. Output: `house.log`. |
| Static source review | Static review by a review agent of the increment's own pipeline. No actionable finding or gate weakening. No separate reviewer artifact is retained beyond `review.md`. Scope and limits: `review.md`. |

The Lean toolchain remains `leanprover/lean4:v4.33.0-rc1`. The kan-tactics and comp-cat-theory revisions remain pinned at `3317f7ac5a22ca0d85b90a3286b8fe0c36cea8ac` and `cc6ced1086a3b5b14c43bd58b5ecbabef09ab201`. Their existing dependency caches were copied; no dependency update was needed. The separate client requires the tested package through its local path and sets `autoImplicit := false`.

Reproduce the checks after building the OCaml package:

```sh
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dunecho.sh build
kanon-wait run -- kanon-exec run --budget 4000 -- zsh dev/dune.sh runtest dev/mu-bridge
kanon-wait run -- kanon-exec run --budget 4000 -- python3 -I dev/mu-bridge/check.py
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta build
kanon-wait run -- kanon-exec run --budget 4000 -- lake +leanprover/lean4:v4.33.0-rc1 --dir meta env lean Axioms.lean
python3 -I dev/validation/2026-09-07-mu-bridge/audit.py
```

The full 21-leg compiler battery is not repeated: the compiler, kernel, erasure and Wasm implementation sources are unchanged. Its earlier validation remains recorded in `dev/M1-BUILD-LOG.md`. This increment validates the fixed constructor and restricted fold bridge and its extraction path. It does not establish general checker/compiler preservation, indexed declaration interpretation, full Lean parity, or the strict internal Kan-only requirement.
