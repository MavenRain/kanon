The finite-family raw-term decoder connects closed exported constructor terms to
the values of the [finite-family bridge](MU-FINITARY-BRIDGE.md). It is available
through `import KanonMeta` in `KanonMeta.MuFinitary`.

`decode spec term` returns an explicit `Except DecodeError (Decoded spec term)`.
Each successful result contains a `Value spec` and an equality certificate
`term = value.encode`. It checks the exact family name, empty indices, constructor
address and constructor membership, then traverses children in order while
enforcing exact arity.
Constructor positions come from the supplied declaration, including when
constructors are renamed or reordered. Arity is unrestricted within the finite
direct-recursion fragment.

The decoder accepts canonical closed constructor trees. It does not normalize
aliases, annotations, lets or eliminations. Wrong shapes, foreign families,
nonempty indices, non-constructor addresses, unknown constructors, wrong arities
and unsupported terms return distinct error constructors. A malformed nested
child propagates its decoding error.

Soundness follows from the result's exact equality certificate. Completeness and
encoding injectivity require the constructor-name uniqueness carried by
`Spec.Valid`. Duplicate constructor names would make distinct constructor
positions encode identically, so those laws do not apply to arbitrary unchecked
specifications. `Validated` declarations provide the required validity proof and
the existing exact declaration certificate.

Decoded values enter the existing constructed semantic carrier. Their folds agree
with folds through its initial algebra by the finite-family bridge's semantic
laws. This connection concerns the specified raw constructor fragment. General
typed interpretation and substitution, indexed and mutual declaration decoding,
payload fields, correspondence with checker and recursive-call rules, compiler
preservation, the internal Kan-only requirement and M1 exit ratification remain
open.

The default Lean regression target exercises the generated sample, every term
constructor, nested failures, empty signatures, multiple nullary constructors,
renamed and reordered declarations, a five-child constructor, and observations
that distinguish child order. The extraction harness additionally decodes the
checked source controls while retaining the existing exact exported-record and
kernel/Node/Wasmtime checks.

After building the OCaml compiler and the pinned Lean package:

```sh
zsh dev/dune.sh runtest dev/mu-bridge
python3 -I dev/mu-bridge/check_finitary.py
```

The [validation record](validation/2026-09-08-finitary-decode/README.md) retains the
tested sources, proof dependency disclosure, downstream client and regression
results.
