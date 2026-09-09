The constructed finite-family carrier now supports dependent elimination,
propositional constructor computation and uniqueness. Import `KanonMeta` and
use `KanonMeta.MuFinitary.semanticElim`.

A motive assigns a `Type` to each semantic value. A constructor step receives
the ordered semantic children and a dependent witness for each child, then
produces a witness for the constructed parent. `semanticElim_node` proves
the resulting constructor equation. `semanticElim_unique` proves that any
section satisfying that equation agrees pointwise with the constructed one.

The eliminator comes from the previously constructed initial algebra.
The generic `Initiality.elim_unique` compares the graph of another section
with the chosen fold into the displayed total algebra. This adds no
initiality assumption or primitive induction rule to the finite-family bridge.

`Value.inductInterpret` computes dependent witnesses structurally over closed
constructor syntax. `Value.semanticElim_interpret` proves agreement with
elimination of its semantic interpretation. `OpenTerm.inductInterpret`
also accepts a witness for each variable in a homogeneous environment.
Its agreement theorem uses the chosen semantic eliminator at those environment
entries. Arbitrary supplied variable witnesses need not equal that choice.
The subsequent [substitution increment](MU-FINITARY-ELIM-SUBST.md) proves
transport-aware substitution and renaming laws for arbitrary supplied witnesses
in this homogeneous fragment.

`interpret_reify` proves that reifying and interpreting returns every inhabitant
of the constructed carrier. Together with the existing `reify_interpret`,
this gives both inverse laws between constructor syntax and the semantic
carrier. `reify_injective` derives from the first law that constructor syntax
separates the inhabitants of the carrier. The new laws work for every `Spec`, including empty signatures;
they do not need `Spec.Valid`. Name validity and uniqueness still govern the
separate connection to validated declarations and exact raw syntax.

The bridge retains finite unindexed declarations with direct recursive fields.
Its motives inhabit `Type 0` and its beta law is propositional. The construction
uses the existing external Lean model, equality, dependent pairs and quotient
colimits. General typed interpretation, dependent contexts and substitution,
indexed and mutual declarations, payloads, correspondence with kernel case
analysis and recursive-call rules, compiler preservation, the internal Kan-only
requirement and M1 exit ratification remain open.

The [validation record](validation/2026-09-08-finitary-elim/README.md) records
the default regression build, an independent downstream client, source audit
and proof dependency disclosure.
