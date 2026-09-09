Dependent elimination now supports constructor-preserving maps between base
algebras. Import `KanonMeta` to use these laws.

For an algebra map `f : Hom A B` and a displayed algebra `E` over `B`,
`E.pullback f` has fibre `E.Fibre (f.map x)` over each source value `x`.
Its constructor operation transports the target witness along the inverse of
`f.comm`. This equality is needed because applying `f` to a source constructor
only propositionally agrees with the target constructor on mapped children.

| API | Result |
| --- | --- |
| `Initiality.Displayed.pullback` | Pull back a dependent constructor operation along a base map. |
| `Initiality.Displayed.pullbackId`, `pullbackComp` | Identity and successive pullbacks preserve the witness itself. |
| `Initiality.DisplayedHom.pullback` | Pull back a constructor-preserving witness map. |
| `Initiality.DisplayedHomOver`, `.id`, `.comp` | Package and compose witness maps over changing bases. |
| `Initiality.Displayed.section_transport` | A dependent section respects equality transport. |
| `Initiality.elim_pullback_section` | Source elimination equals a lawful target section at the mapped value; only the source must be initial. |
| `Initiality.elim_pullback`, `elim_fusion_over` | Elimination and fusion commute with maps between initial bases. |
| `Initiality.elim_pullback_id`, `elim_pullback_comp` | Elimination respects identity and composition of base maps. |
| `MuFinitary.pullbackFibre`, `pullbackStep`, `pullbackDisplayedHom` | Connect the finite-family motive and constructor operation to the indexed pullback. |
| `MuFinitary.semanticElim_pullback_section`, `semanticElim_pullback` | Constructed elimination agrees with the target section or target eliminator. |
| `MuFinitary.pullbackFusionHom` | Connect a map over another base to finite-family structural fusion. |
| `MuFinitary.Value.inductInterpret_fusion_over` | Closed induction retains witnesses over the mapped base. |
| `MuFinitary.OpenTerm.inductInterpret_fusion_over` | Open induction transforms each supplied variable witness. |
| `MuFinitary.OpenTerm.inductInterpret_substitute_fusion_over` | Substitution transport followed by base change equals induction with transformed replacement witnesses. |
| `MuFinitary.OpenTerm.inductInterpret_rename_fusion_over` | Renaming transport retains the selected transformed witnesses, including noninjective renamings. |

The proofs reuse displayed fusion and elimination uniqueness. Composition
coherence identifies the two equality transports; it does not assume that the
intermediate or final algebra is initial. The lawful-section theorem identifies
the pulled-back section by source initiality. Choosing the target eliminator
as that section gives naturality between initial bases.

The finite-family regressions map constructed syntax into its weighted numeric
fold. Dependent certificates and independent annotations survive this change.
Equal semantic inputs with different supplied annotations retain 159 and 179.
Substitution retains 78, and noninjective renaming retains 68. Separate generic
tests change natural values by one and then two, and change carriers between
`Nat` and a boxed natural. A downstream client imports only the public root and
uses two indices with certificates 5 and 13 and annotations 105 and 113.

All results are propositional and concern maps over a common polynomial.
The general theory retains independent index, shape and position universes,
with carriers and displayed fibres sharing one universe. The finite-family
bridge retains `Type 0` motives and homogeneous unindexed constructor syntax
with direct recursive children. Signature changes, general indexed and mutual
compiler declarations, payload fields, dependent contexts, typed compiler
preservation, the internal Kan-only requirement and M1 exit ratification remain
open.

The [validation record](validation/2026-09-09-finitary-elim-base-change/README.md)
retains both builds, complete axiom disclosure, source checks and three mutation
controls.
