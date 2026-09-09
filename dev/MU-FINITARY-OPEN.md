Open constructor terms extend the [finite-family bridge](MU-FINITARY-BRIDGE.md)
with scoped variables and substitution. Import `KanonMeta` and use
`KanonMeta.MuFinitary.OpenTerm`.

`OpenTerm spec n` describes a homogeneous context of `n` values from one family.
Variables carry `Fin n`; constructor nodes carry their declaration position and
exactly the declared number of ordered children. The supported declarations keep
the existing finite, unindexed, direct-recursion fragment. These terms have no
binders, payload fields or recursive function definitions.

Renaming changes variable positions. Substitution replaces each variable with an
open constructor term in another context. Identity and composition laws hold,
and encoding commutes with the existing raw `KanonMeta.subst` whenever its
substitution agrees on the in-scope variables. Values assigned to out-of-scope
raw indices do not affect this law.

Evaluation uses an environment and a constructor algebra. Interpretation uses
the carrier constructed by `FinitaryConstruction`. Substituting terms before
interpretation agrees with interpreting them into the environment first. Closing
an empty context recovers the existing `Value`, with encoding and interpretation
agreement.

The total open decoder returns an `Except` with an exact reconstruction
certificate. It accepts variables only within the supplied context size and
retains the closed decoder's family, shape, address and arity errors. As in the
closed decoder, malformed children can be encountered before a later arity
failure. Completeness and encoding injectivity require `Spec.Valid`, including
constructor-name uniqueness.

This establishes substitution for a scoped constructor fragment. General kernel
typing preservation, dependent contexts, quantities, indexed and mutual
declarations, dependent elimination, recursive-call rules, compiler preservation,
the internal Kan-only requirement and M1 exit ratification remain open.

The [validation record](validation/2026-09-08-finitary-open/README.md) records the
default Lean regressions, downstream client, proof dependencies and retained
compiler checks.
