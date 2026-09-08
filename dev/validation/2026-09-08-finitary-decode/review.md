Static review completed on 2026-09-08 by a separate review agent in this
increment's Codex development session. This is an internal source review, not an
external audit. The reviewer made no edits and ran no builds; the primary agent
ran the retained validation commands.

The reviewed scope was `meta/KanonMeta/MuFinitaryDecode.lean`, its default Lean
regression target, the extraction harness extension, and the associated API
documentation. The review checked structural termination, exact syntax
certificates, constructor lookup and declaration positions, finite child order,
arity checks, and the validity hypotheses on completeness and injectivity.

The reviewer confirmed that the roundtrip proof establishes successful decoder
execution through the constructor and child-list helpers, then uses encoding
injectivity to identify the returned value. It does not assume successful
decoding as its completeness hypothesis. The exact-input soundness theorem
projects the certificate already carried by every successful result.

The harness expectations come from independently specified declarations and
trees, with Python observations compared to Lean folds. Renaming, reordering,
child-order changes, distinct nullary constructors and malformed inputs are
covered. All five public decoder theorems use term proofs without new axioms or
proof admissions.

One documentation sentence implied that argument count was checked before every
child. The decoder traverses children while enforcing arity, so a malformed child
can be reported before a later length mismatch. The sentence was corrected to
describe the actual traversal. No code defect or remaining finding was reported.

Addendum, written on 2026-09-08 at 13:07 PDT in the checkout
`/Users/oobi/Documents/kanon` after the review round. The sentence above on the
exact-input soundness theorem describes `decode_sound` before that round. The
theorem now takes the decoded value and the acceptance premise
`(decode spec term).map Decoded.value = .ok value`. Its proof derives
`term = value.encode` from that premise. It projects no certificate from a
hypothesis. Its axiom report is unchanged: `propext` and `Quot.sound`.
