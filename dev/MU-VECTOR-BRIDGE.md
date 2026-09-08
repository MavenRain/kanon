The indexed-vector bridge connects one checked length-indexed family to the constructed indexed algebra. Its source is `test/meta/mu-vector-bridge.kan`: `N` has zero and successor constructors, and `V` has an erased `N` index, a zero-length constructor, and a successor constructor carrying an erased predecessor, a natural payload and a vector at the predecessor length.

`dev/mu-bridge/export_mu.ml --vector` checks the complete fixture and exports both complete family records, the raw constructor sample, and the dependent copy body with their types and recursion metadata. The exact declaration certificates include quantities, de Bruijn indices, constructor arities and positivity fields. The natural and tree commands retain their existing output, and all three generated files have Dune freshness checks.

`KanonMeta.MuVector.Value n` carries its length in its Lean type. Encoding retains the raw result index and erased constructor index argument. The total `Except` decoder validates both indices using the existing closed `N` decoder, requires a literal natural payload, and checks the recursive child at the predecessor length. It rejects open terms, malformed indices, inconsistent lengths, wrong addresses and constructor arities. The library proves encoding roundtrip and injection; a checked value additionally carries equality witnesses for both exported declarations.

The semantic carrier comes from `VectorConstruction.recursive Nat`, whose initiality is constructed from the initial sequence. The bridge derives length-dependent fold equations and uniqueness from that initiality. Reifying interpreted values recovers the same payloads at the same length, proving interpretation is injective. Copy preserves the length in its type and preserves each interpreted value by the constructed algebra's copy law. Raw equality separately identifies the fixed recursive copy template, including its motive, erased length application and recursive argument position.

The sample has payloads seventeen and twenty-five. Its observation is `head + 2 * tail`, giving sixty-seven before and after copy. Reversing those payloads gives fifty-nine; replacing copied payloads with zero gives zero. A control that substitutes the original tail for the recursive call still gives sixty-seven, but changes the raw body and removes the recursion marker. The harness checks these changes with Lean certificates as well as executing the kernel, Node and Wasmtime. Wrong-result-index and wrong-tail-index controls must fail both checking and extraction.

This is external metatheory for one indexed declaration pair, canonical closed constructor values with literal payloads, and one fixed recursive template. Lean naturals interpret canonical indices through the existing natural-value decoder. Exact declaration equality does not prove the OCaml checker. General declaration interpretation, open typed substitution, mutual-family interpretation, arbitrary recursive definitions, compiler preservation and the internal Kan-only requirement remain open. This increment does not ratify M1 exit.

After the normal OCaml and Lean package builds, run:

```sh
zsh dev/dune.sh runtest dev/mu-bridge
python3 -I dev/mu-bridge/check.py
python3 -I dev/mu-bridge/check_tree.py
python3 -I dev/mu-bridge/check_vector.py
```

The vector harness also invokes the pinned Lean toolchain to check each changed extraction against its expected raw syntax and metadata. The [validation record](validation/2026-09-08-vector-bridge/README.md) retains command output, dependency disclosure, source hashes, downstream import checks and a static source review by a review agent of the increment's own pipeline.
