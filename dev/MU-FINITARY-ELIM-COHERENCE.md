Dependent induction now has composition laws for its semantic transports.
Import `KanonMeta` and use the laws in `KanonMeta.MuFinitary.OpenTerm`.
They extend the [substitution laws](MU-FINITARY-ELIM-SUBST.md).

| Law in `OpenTerm` | Result |
| --- | --- |
| `inductInterpret_congr` | Equal environments and transported variable witnesses give equal induction results. |
| `inductInterpret_substitute_comp_coherent` | Induction agrees in composed and successive substitution environments. |
| `inductInterpret_substitute_seq` | Applying substitution naturality twice retains the iterated witnesses. |
| `inductInterpret_substitute_comp_routes` | The two successive transports agree with the three composed-route transports. |
| `inductInterpret_rename_seq` | Applying renaming naturality twice retains each selected witness. |
| `inductInterpret_rename_comp_routes` | Successive and composed renaming transports agree. |

An environment assigns a semantic value to each variable, together with a
witness in a motive at that value. Environment congruence states that changing
those values along pointwise equalities preserves dependent induction when
the corresponding transported witnesses agree. Equal values alone do not
force arbitrary witnesses to agree.

For two substitutions, the successive route transports the induction result
first along the second substitution's interpretation equality, then along
the first substitution's equality in the resulting environment. The composed
route instead transports along syntax composition, the interpretation of the
composed substitution, and the equality between the composed and successive
environments. The new laws show that both routes retain the same witnesses.
The proof relates the replacement witnesses with substitution naturality and
then applies environment congruence. Renaming has the corresponding route
comparison, with definitionally equal final environments.

These are propositional equalities with explicit transport. Motives inhabit
`Type 0`; contexts contain values of one unindexed finite family with direct
recursive fields. General dependent contexts, interpretation of compiler
typing and recursive-call judgments, indexed and mutual declarations,
payloads, compiler preservation, the internal Kan-only requirement and M1
exit ratification remain open.

The [validation record](validation/2026-09-08-finitary-elim-coherence/README.md)
retains the package build, downstream client, regression observations and
proof dependency disclosure.
