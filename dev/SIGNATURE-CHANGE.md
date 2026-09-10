Signature translation now extends the dependent base-change theory to different
indexed polynomials. Import `KanonMeta` and open `KanonMeta.Initiality`.

A `SignatureMap P Q` selects a target shape for each source shape. For each
target recursive position it selects a source position, with a proof that
their child indices agree. Positions run backward so the target constructor
can reorder, duplicate or discard source children. No bijection, injectivity
or inverse translation is implied.

| API | Result |
| --- | --- |
| `SignatureMap.id`, `.comp` | Identity and composition of shape and position selection. |
| `.children`, `.children_map`, `.children_comp` | Index-correct child transport, naturality and composition. |
| `.restrict`, `.restrictHom`, `.restrictId`, `.restrictComp` | Restrict target algebras and their maps to source operations without changing carriers. |
| `.restrictDisplayed`, `.restrict_section` | Restrict dependent constructor operations and lawful sections, retaining supplied witnesses. |
| `.translate`, `.translate_beta`, `.translate_unique` | Fold an initial source into a restricted target, with computation and uniqueness. |
| `.translate_fusion`, `.translate_id`, `.translate_comp` | Fold fusion, identity and composition of translations. |
| `.elim_translate_section`, `.elim_translate` | Dependent elimination agrees with a lawful target section or target elimination. |

Restriction of an initial target need not be initial. Translation requires
only source initiality. The section law permits any target with a lawful
section. The eliminator law also requires target initiality. Composition of
translations requires source and intermediate initiality; its final target
may be arbitrary. The proofs reuse the existing uniqueness and base-change
theorems. All equalities are propositional.

The regressions translate natural numbers into the constructed initial algebra
of a binary-tree signature. A successor duplicates its child into both binary
positions; a weighted fold of the translated value at two yields 56. A return
translation selects the right child and recovers the source natural number.
An asymmetric tree detects choosing the wrong branch. Swapping distinct child
values changes a weighted constructor from 20 to 17; swapping twice restores
20. Independent annotations survive both duplication and permutation.
Dependent certificates and annotations agree with elimination into the
constructed target. Indexed tests transport `Fin (n + 1)` witnesses from child
index `n` to the propositionally equal `0 + n`, for arbitrary `n`.

The general API keeps independent index, shape, position and carrier universe
levels. Source and target polynomials share their shape and position levels,
their index type stays fixed, and displayed fibres share the carrier universe.
No new axioms are introduced. The new public declarations depend at most on
`Quot.sound`; concrete constructed-initiality tests also use the existing
classical dependencies. The Nat source test uses Lean's Nat recursor.

Changing index types, translating validated compiler declarations or open
constructor syntax across signatures, dependent contexts, compiler
preservation, the internal Kan-only requirement and M1 exit ratification remain
open. The [validation record](validation/2026-09-09-signature-change/README.md)
contains the complete builds, axiom disclosure and negative controls.
