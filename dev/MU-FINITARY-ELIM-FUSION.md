Dependent elimination now preserves constructor-respecting transformations
between witness types. Import `KanonMeta` to use these laws.

`Initiality.DisplayedHom D E` maps witnesses over the same base value from
the displayed algebra `D` to `E`. Its `comm` field requires that mapping a
constructor result agrees with applying the target constructor operation to
the mapped child witnesses. Identity and composition preserve this law.

| Declaration | Result |
| --- | --- |
| `Initiality.DisplayedHom.id` | The identity witness map satisfies the constructor law. |
| `Initiality.DisplayedHom.comp` | The composite of two witness maps over the same base satisfies the constructor law. |
| `Initiality.DisplayedHom.totalHom` | A witness map induces an ordinary algebra map on dependent pairs. |
| `Initiality.DisplayedHom.map_transport` | Witness mapping commutes with transport along a base equality. |
| `Initiality.elim_fusion` | Mapping the chosen dependent section equals target elimination. |
| `Initiality.Displayed.constant` | A second algebra gives a displayed algebra whose fibres ignore the base value. |
| `Initiality.elim_constant` | Elimination into constant fibres recovers the ordinary initial fold. |
| `MuFinitary.displayedHom` | Packages a finite-family witness map and its constructor law. |
| `MuFinitary.semanticElim_fusion` | The constructed finite-family eliminator preserves a displayed map. |
| `MuFinitary.Value.inductInterpret_fusion` | Closed structural induction preserves that map. |
| `MuFinitary.OpenTerm.inductInterpret_fusion` | Open induction preserves the map when each supplied variable witness is mapped. |
| `MuFinitary.OpenTerm.inductInterpret_substitute_fusion` | Mapping after substitution transport agrees with target induction using transformed replacement witnesses. |
| `MuFinitary.OpenTerm.inductInterpret_rename_fusion` | Mapping after renaming transport agrees with target induction using the selected transformed witnesses. |

The general theorem uses initiality of the fixed base algebra. A displayed map
induces a map of total algebras, and uniqueness identifies its composite with
the source fold as the target fold. The section laws then identify the two
dependent witnesses. The finite-family instance uses the previously constructed
initial algebra. Structural fusion is also proved directly on closed and open
constructor syntax. The transport results compose map naturality, structural
fusion and the existing substitution or renaming theorem.

Variable witnesses may contain arbitrary data beyond a certificate about the
semantic value. The regression family swaps a dependent certificate and its
annotation, retaining distinct annotations 159 and 179 at identical semantic
inputs. A separate downstream client duplicates annotations into two fields,
retaining both results after substitution and noninjective renaming. A
transformation that resets every annotation to zero fails the constructor law.

The general initiality results retain independent index, shape and position
universes. Carrier and displayed fibre universes must agree. The finite-family
bridge has `Type 0` motives over homogeneous unindexed constructor terms with
direct recursion. Fusion holds over a fixed base, with propositional equality;
it does not transport between different base algebras. Indexed or mutual
compiler declarations, payload fields, general dependent contexts, typed
compiler preservation, the internal Kan-only requirement and M1 exit
ratification remain open.

The [validation record](validation/2026-09-09-finitary-elim-fusion/README.md)
retains the package and downstream builds, proof dependency disclosure,
source audit and mutation controls.
