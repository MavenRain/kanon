The binary-tree bridge connects a checked family with two recursive children to the finite branching construction. Its source is `test/meta/mu-tree-bridge.kan`: `Tree` has constructors `leaf : Tree` and `fork : Tree -> Tree -> Tree`. The fixture mirrors an asymmetric tree and observes its children with different weights, so child order affects the answer.

`dev/mu-bridge/export_mu.ml --tree` checks the fixture and exports the complete `Positivity.family` record together with the checked bodies, types and recursion metadata of `sample` and `mirror`. It reuses the natural bridge's raw serializer and declaration records. The original natural-family command retains its output. Both generated files have Dune freshness checks.

`KanonMeta.MuTree` identifies the exact declaration with a Lean equality witness. Its total decoder accepts only closed `leaf` and `fork` introductions of this family. It rejects incorrect shapes, indices, addresses, arities and unsupported children on either side. Encode/decode roundtrip and encoder injection are proved for the supported fragment.

The semantic signature has the singleton index and constructor arities zero and two. Its carrier and initiality come from `FinitaryConstruction.recursive` and `recursiveInitial`, whose quotient construction synchronizes finite children at a common sequence stage. The bridge obtains fold equations and uniqueness from that proved initiality. Structural folding agrees with the semantic fold, and interpreting values is injective. In particular, the quotient does not identify distinct trees in the supported constructor fragment.

The mirror theorem relates structural child swapping to the fold into the constructed algebra. The extracted recursive body is separately checked against the exact supported raw template, including its de Bruijn indices. This is a fixed recursive-program interpretation. The observation algebra assigns one to a leaf and `2 * left + 3 * right` to a fork. The sample observes seventeen and its mirror observes thirteen. Runtime controls that keep the original child order or discard one child remain well typed and produce seventeen and five respectively.

This remains external metatheory for one unindexed family. The OCaml serializer is tested code, and raw declaration equality is not a proof of the checker. General recursive definitions, indexed and mutual declaration interpretation, open typed substitution, compiler preservation and the internal Kan-only requirement remain open. The existing natural bridge and broader finite branching construction retain their separate scopes. No kernel rule, dependency pin, performance bound or M1 exit decision changes here.

After the normal OCaml and Lean builds, run:

```sh
zsh dev/dune.sh runtest dev/mu-bridge
python3 -I dev/mu-bridge/check.py
python3 -I dev/mu-bridge/check_tree.py
```

The package build checks the generated data and proof certificates. The two Python checks exercise the kernel and both Wasm hosts. The dated [validation record](validation/2026-09-07-tree-bridge/README.md) records complete output, proof dependencies and a static source review by a review agent of the increment's own pipeline.
