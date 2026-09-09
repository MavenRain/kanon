Dependent structural induction now commutes with substitution and renaming
of open constructor terms. Import `KanonMeta` and use
`KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute` or
`KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename`.

A substitution replaces each variable with a constructor term. One route
substitutes first and then computes dependent witnesses. The other computes
the semantic value and witness of each replacement, then uses them as the
environment for the original term. The substitution theorem equates these
results after transporting the first witness along `interpret_substitute`.
The renaming theorem uses the same construction with `interpret_rename`.
Both laws retain the order and multiplicity of variables and constructor
children.

The `_id` corollaries recover the original witness after identity substitution
or renaming. The `_comp` corollaries equate induction on successive and
composed substitutions or renamings, transporting along the corresponding
syntax composition law.

The later [composition coherence laws](MU-FINITARY-ELIM-COHERENCE.md) compare
the chains of semantic transports themselves. They include congruence for
dependent induction under equal environments and transported variable
witnesses.

The laws accept arbitrary witnesses in the motive at each environment entry.
They do not require those witnesses to agree with `semanticElim`. A motive
can therefore carry additional data that differs between witnesses for the
same semantic value. This distinction matters when using dependent induction
to propagate annotations or other data through syntax.

The context still contains values of one unindexed finite family with direct
recursive fields. Motives inhabit `Type 0`, and the laws use propositional
equality with explicit transport. General dependent contexts, interpretation
of the compiler's typing and recursive-call judgments, indexed and mutual
declarations, payloads, compiler preservation, the internal Kan-only requirement
and M1 exit ratification remain open.

The [validation record](validation/2026-09-08-finitary-elim-subst/README.md)
retains the package build, downstream client, source audit and axiom disclosure.
