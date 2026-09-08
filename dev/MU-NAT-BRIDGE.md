The natural-family bridge connects one actual checked declaration and its closed constructor values to the constructed initial algebra. Its source is `test/meta/mu-nat-bridge.kan`: `N` has constructors `zero : N` and `succ : N -> N`. The fixture constructs three, doubles it by structural recursion, and observes six using the built-in natural arithmetic.

`dev/mu-bridge/export_mu.ml` elaborates and checks that file, reads `Global.find_family "N"`, and exports every field of its `Positivity.family` record. Constructor telescopes, result indices, arities, recursion flags, constructor status, universe level, and positivity are retained. The generated fixture also contains the checked raw bodies, types, and recursion metadata of `three` and `double`. The normal `check --print` output omits family tables, so it cannot supply this evidence by itself.

The checked record stores universe level 1 for this surface `Type 0` declaration. The bridge preserves the stored value. It does not infer it from the surface spelling. The generated file is `meta/test/GeneratedMuNat.lean`; `zsh dev/dune.sh runtest dev/mu-bridge` compares fresh extraction with that file byte for byte.

The public Lean raw syntax now includes `Shape.SMu` and `Addr.actor`. Renaming and substitution traverse the index expressions in their surrounding context. An inductive diagram adds no binder. Motives and branches continue to lift under their own explicit binders. The new substitution equations are raw syntax laws. In particular, an equation for raw `Ran SMu` does not make that form admissible to the checker.

`KanonMeta.MuNat` gives the supported declaration an explicit equality witness, interprets closed zero/successor constructor values, and obtains fold laws from `NatConstruction.recursiveInitial`. The target carrier is the quotient of the countable initial sequence of `NatConstruction`, with the colimit and initiality supplied by the earlier checked construction. Lean's built-in naturals serve as an observation algebra; their initiality is not an input. Constructor equations, observations, and separation are propositional Lean theorems. The tests also compare the exported structural `double` body with the supported template.

This increment covers a fixed unindexed constructor fragment. The OCaml exporter and the correspondence between its serialization and kernel records are tested code, not a verified compiler translation. The declaration equality witness is not a proof of the OCaml checker. The fold interpretation does not prove general recursive-definition checking, erasure, or Wasm preservation. Indexed and mutual declaration interpretation, open typed substitution, general dependent cases, and internal derivation of the admitted diagrams remain separate obligations.

The ambient category remains `Type`-valued families over the singleton index, with functions as morphisms and the countable initial sequence from `InitialChain`. The construction relies on Lean equality, natural-number iteration and quotients, as recorded by the axiom driver. It introduces no new existence premise or kernel rule and does not discharge the strict internal Kan-only requirement or M1 exit ratification.

After the normal OCaml and Lean builds, the focused checks are:

```sh
zsh dev/dune.sh runtest dev/mu-bridge
python3 -I dev/mu-bridge/check.py
```

The second check verifies fresh extraction, the answer six on the kernel and both Wasm hosts, empty fixture axiom disclosure, and a changed-recursion control. Replacing the double successor with a single successor remains well typed, changes the extracted definition, and changes all three runtime observations to three. Dated validation evidence is in `dev/validation/2026-09-07-mu-bridge/`.
