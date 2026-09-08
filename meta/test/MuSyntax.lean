/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

Concrete regressions for the M1 raw inductive syntax mirror.  The
expected terms spell out which indices are bound at each scope.
-/

import KanonMeta.BeckChevalley

namespace KanonMeta.Tests.MuSyntax

private def point : Shape := .SPi .many "x" (.var 0)
private def pairBinders : List (Quantity × String) := [(.many, "x"), (.many, "y")]
private def replace : Subst := fun i => .lit (i + 7)
private def openReplacement : Subst := fun _ =>
  .intro (.SMu "Family" [.var 0]) (.actor "mk") [.var 1]

theorem ren_indices_preserves_order :
    renShape Nat.succ (.SMu "Vec" [.var 1, .var 0])
      = .SMu "Vec" [.var 2, .var 1] := by
  kan_rfl

theorem subst_indices_preserves_order :
    substShape replace (.SMu "Vec" [.var 1, .var 0])
      = .SMu "Vec" [.lit 8, .lit 7] := by
  kan_rfl

theorem empty_indices_stay_empty :
    substShape openReplacement (.SMu "Nat" []) = .SMu "Nat" [] := by
  kan_rfl

-- Inductive diagrams open no binder, including in the raw Ran syntax.
theorem lan_has_no_diagram_binder :
    ren Nat.succ (.lan (.SMu "Vec" [.var 0]) (.var 0))
      = .lan (.SMu "Vec" [.var 1]) (.var 1) := by
  kan_rfl

theorem ran_has_no_diagram_binder :
    subst replace (.ran (.SMu "Vec" [.var 0]) (.var 0))
      = .ran (.SMu "Vec" [.lit 7]) (.lit 7) := by
  kan_rfl

-- A Pi domain is outside its binder, while nested inductive indices
-- distinguish that binder from free variables.
theorem ren_indices_under_pi :
    ren Nat.succ
      (.ran point (.lan (.SMu "Vec" [.var 0, .var 1]) (.var 1)))
      = .ran (.SPi .many "x" (.var 1))
          (.lan (.SMu "Vec" [.var 0, .var 2]) (.var 2)) := by
  kan_rfl

theorem subst_indices_under_pi :
    subst openReplacement
      (.ran (.SPi .many "x" (.univ 0))
        (.lan (.SMu "Vec" [.var 0, .var 1]) (.var 1)))
      = .ran (.SPi .many "x" (.univ 0))
          (.lan (.SMu "Vec"
            [.var 0, .intro (.SMu "Family" [.var 1]) (.actor "mk") [.var 2]])
            (.intro (.SMu "Family" [.var 1]) (.actor "mk") [.var 2])) := by
  kan_rfl

-- The motive binds one index and self, and the branch binds two fields.
-- The outer shape and scrutinee remain outside both scopes.
theorem ren_indices_under_motive_and_branch :
    ren Nat.succ
      (.elim (.SMu "Vec" [.var 0]) (.var 1) .many
        (some (.mk (some "Vec") ["n"] "self"
          (.lan (.SMu "Vec" [.var 0, .var 1, .var 2]) (.var 2))))
        [(.actor "cons", .mk pairBinders
          (.intro (.SMu "Vec" [.var 0, .var 1, .var 2]) (.actor "cons")
            [.var 0, .var 2]))])
      = .elim (.SMu "Vec" [.var 1]) (.var 2) .many
          (some (.mk (some "Vec") ["n"] "self"
            (.lan (.SMu "Vec" [.var 0, .var 1, .var 3]) (.var 3))))
          [(.actor "cons", .mk pairBinders
            (.intro (.SMu "Vec" [.var 0, .var 1, .var 3]) (.actor "cons")
              [.var 0, .var 3]))] := by
  kan_rfl

theorem subst_indices_under_motive_and_branch :
    subst (fun _ => .var 0)
      (.elim (.SMu "Vec" [.var 1]) (.var 1) .many
        (some (.mk (some "Vec") ["n"] "self"
          (.lan (.SMu "Vec" [.var 0, .var 1, .var 3]) (.var 3))))
        [(.actor "cons", .mk pairBinders
          (.intro (.SMu "Vec" [.var 0, .var 1, .var 3]) (.actor "cons")
            [.var 0, .var 3]))])
      = .elim (.SMu "Vec" [.var 0]) (.var 0) .many
          (some (.mk (some "Vec") ["n"] "self"
            (.lan (.SMu "Vec" [.var 0, .var 1, .var 2]) (.var 2))))
          [(.actor "cons", .mk pairBinders
            (.intro (.SMu "Vec" [.var 0, .var 1, .var 2]) (.actor "cons")
              [.var 0, .var 2]))] := by
  kan_rfl

-- Weakening replacement terms must traverse their own inductive indices.
theorem open_replacement_under_motive :
    substMotive openReplacement
      (.mk (some "Vec") ["n"] "self" (.ann (.var 0) (.var 2)))
      = .mk (some "Vec") ["n"] "self"
          (.ann (.var 0)
            (.intro (.SMu "Family" [.var 2]) (.actor "mk") [.var 3])) := by
  kan_rfl

theorem open_replacement_under_branch :
    substBranch openReplacement
      (.actor "cons", .mk pairBinders (.ann (.var 1) (.var 2)))
      = (.actor "cons", .mk pairBinders
          (.ann (.var 1)
            (.intro (.SMu "Family" [.var 2]) (.actor "mk") [.var 3]))) := by
  kan_rfl

-- Constructor names are invariant while their surrounding terms change.
theorem constructor_address_in_intro :
    subst replace (.intro (.SMu "Vec" [.var 0]) (.actor "cons") [.var 1])
      = .intro (.SMu "Vec" [.lit 7]) (.actor "cons") [.lit 8] := by
  kan_rfl

theorem constructor_address_in_out :
    ren Nat.succ (.out (.SMu "Vec" [.var 0]) (.actor "cons") (.var 1))
      = .out (.SMu "Vec" [.var 1]) (.actor "cons") (.var 2) := by
  kan_rfl

end KanonMeta.Tests.MuSyntax
