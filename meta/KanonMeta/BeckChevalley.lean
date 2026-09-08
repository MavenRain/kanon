/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

Raw Beck-Chevalley substitution equations for the mirrored shapes.

The statement form is the design verdict's, at
kan-lang-design-verdict.md:164-166: substitution slides through an open
shape, `(Lan_s A)[sigma] = Lan_{s[sigma]} (A[sigma^+])`, and the same for
`Ran`, proved one shape at a time.  These are equations of raw syntax,
not typing, reduction, or eta theorems.  In particular, the raw `Ran`
equation at `SMu` does not assert that the checker admits `Ran SMu`.

The proofs use kan-tactics only (M1-PLAN.md:182).  `kan_rfl` closes each
goal because `subst` is structurally recursive, so the two sides are
definitionally equal.
-/

import KanonMeta.Subst
import KanTactics

namespace KanonMeta

/-- Lan at the point shape.  Mirrors SPEC.md:163.  `up sigma` is
`sigma^+` because the point diagram opens one binder
(lib/rules.ml:635). -/
theorem bc_lan_spi (sigma : Subst) (A : Term) (q : Quantity) (x : String)
    (dom : Term) :
    subst sigma (Term.lan (Shape.SPi q x dom) A)
      = Term.lan (Shape.SPi q x (subst sigma dom)) (subst (up sigma) A) := by
  kan_rfl

/-- Ran at the point shape.  Mirrors SPEC.md:162. -/
theorem bc_ran_spi (sigma : Subst) (A : Term) (q : Quantity) (x : String)
    (dom : Term) :
    subst sigma (Term.ran (Shape.SPi q x dom) A)
      = Term.ran (Shape.SPi q x (subst sigma dom)) (subst (up sigma) A) := by
  kan_rfl

/-- Lan at the collection shape.  Mirrors SPEC.md:165, the row with no
eta.  The shape action is the identity here because `SColl` holds an
`int` and no term (lib/shape.ml:12), and `sigma^+` is `sigma` because the
collection diagram opens no binder (lib/rules.ml:637). -/
theorem bc_lan_scoll (sigma : Subst) (A : Term) (n : Nat) :
    subst sigma (Term.lan (Shape.SColl n) A)
      = Term.lan (Shape.SColl n) (subst sigma A) := by
  kan_rfl

/-- Ran at the collection shape.  Mirrors SPEC.md:164, the row that gives
Unit its eta at `SColl 0`. -/
theorem bc_ran_scoll (sigma : Subst) (A : Term) (n : Nat) :
    subst sigma (Term.ran (Shape.SColl n) A)
      = Term.ran (Shape.SColl n) (subst sigma A) := by
  kan_rfl

/-- Lan at the inductive shape.  Its indices and diagram are both in
the outer context because the inductive rule pack opens no binder. -/
theorem bc_lan_smu (sigma : Subst) (A : Term) (name : String)
    (indices : List Term) :
    subst sigma (Term.lan (Shape.SMu name indices) A)
      = Term.lan (Shape.SMu name (substArgs sigma indices)) (subst sigma A) := by
  kan_rfl

/-- The corresponding raw Ran equation.  This states only how the
syntax traversal acts and carries no kernel admissibility claim. -/
theorem bc_ran_smu (sigma : Subst) (A : Term) (name : String)
    (indices : List Term) :
    subst sigma (Term.ran (Shape.SMu name indices) A)
      = Term.ran (Shape.SMu name (substArgs sigma indices)) (subst sigma A) := by
  kan_rfl

end KanonMeta
