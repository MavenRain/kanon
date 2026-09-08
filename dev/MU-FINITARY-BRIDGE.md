The finite-family bridge generalizes declaration interpretation to one unindexed family with any finite list of constructors and any finite number of direct recursive children. Family names, constructor names and argument binder names come from the declaration. Names follow the bridge's explicit ASCII identifier grammar, and constructor names must be distinct. The supported fragment uses `Type 0`, no parameters or indices, and unrestricted recursive fields with the canonical direct self type.

`KanonMeta.MuFinitary` validates the complete exported record, including constructor order, quantities, result indices, arity, recursion metadata and positivity status. Successful validation carries an equality certificate between the original declaration and the declaration reconstructed from its validated specification. That specification retains the names and binder lists; its semantic signature retains the constructor positions and arities. It certifies the supported syntax fragment. Correctness of the OCaml checker remains a separate obligation.

The semantic carrier and its initiality come from `FinitaryConstruction`. Constructor shapes retain their positions in the declaration and recursive children retain their ordered finite positions. The bridge proves generic constructor fold equations and uniqueness, agreement between syntax folds and semantic folds, and reconstruction of every interpreted constructor value. Reconstruction proves that interpretation is injective. The public package exposes the bridge through `import KanonMeta`.

`dev/mu-bridge/export_mu.ml --finitary FAMILY FIXTURE.kan` checks the complete source and exports the selected family record and the checked `sample` definition, including its type and recursion metadata. The generated source has a Dune freshness check. The fixture `test/meta/mu-finitary-bridge.kan` exercises four constructor arities, including a ternary constructor. Its harness also checks renamed and reordered declarations and malformed invocation and source controls.

This remains external metatheory for a bounded declaration fragment. The later [raw-term decoder](MU-FINITARY-DECODE.md) reconstructs arbitrary closed constructor trees in this fragment, certifies their exact raw encoding and proves roundtrip laws. The extraction harness now also checks decoding and ordered observations of the exported samples. General indexed and mutual declaration interpretation, payload fields, open typed terms and substitution, recursive-call correspondence, compiler preservation and the internal Kan-only requirement remain open. This increment does not ratify M1 exit.

After the OCaml and pinned Lean package builds, reproduce the extraction and runtime checks with:

```sh
zsh dev/dune.sh runtest dev/mu-bridge
python3 -I dev/mu-bridge/check_finitary.py
```

The [validation record](validation/2026-09-08-finitary-bridge/README.md) records the tested source, proof dependencies, downstream import and regression results.
