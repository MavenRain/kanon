/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.FinitaryConstruction

/-! Preservation must also work when sequence transitions identify values.
The three children below occupy different stages and different index fibres.
-/

namespace KanonMeta.FinitarySequence.Tests

open Initiality InitialChain FinitaryConstruction

def collapsing : Sequence Nat where
  obj := fun _ _ => Nat × Bool
  next := fun _ _ x => (x.1, false)

def signature : Signature Nat where
  Shape := fun _ => Nat
  arity := fun _ => 3
  child := fun _ p => p.val

abbrev point (n i : Nat) (x : Nat × Bool) := (ChainColimit.cocone collapsing).leg n i x

theorem point_step (n i : Nat) (x : Nat × Bool) :
    point (n + 1) i (x.1, false) = point n i x :=
  (ChainColimit.cocone collapsing).comm n i x

theorem identifies (n i a : Nat) : point n i (a, true) = point n i (a, false) :=
  (point_step n i (a, true)).symm.trans (point_step n i (a, false))

def payload : Cocone (mappedSequence signature.polynomial collapsing) (fun _ => Nat) where
  leg := fun _ _ x => (show Nat from x.1) + 2 * (x.2 ⟨(0 : Fin 3)⟩).1 +
    3 * (x.2 ⟨(1 : Fin 3)⟩).1 + 5 * (x.2 ⟨(2 : Fin 3)⟩).1
  comm := fun _ _ _ => rfl

def mixed (p : Fin 3) : ChainColimit.carrier collapsing p.val :=
  Fin.cases (point 0 0 (3, true))
    (Fin.cases (point 1 1 (5, true)) (fun _ => point 2 2 (4, false))) p

def retained : Fin 3 → Nat := Fin.cases 3 (Fin.cases 5 (fun _ => 4))

theorem mixed_at_three (p : Fin 3) : mixed p = point 3 p.val (retained p, false) :=
  Fin.cases
    (((point_step 2 0 (3, false)).trans (point_step 1 0 (3, false))).trans
      (point_step 0 0 (3, true))).symm
    (Fin.cases
      ((point_step 2 1 (5, false)).trans (point_step 1 1 (5, true))).symm
      (fun _ => (point_step 2 2 (4, false)).symm)) p

def mixedNode : polyObj signature.polynomial (ChainColimit.carrier collapsing) 99 :=
  node signature (1 : Nat) mixed

theorem mixed_node_at_three : mixedNode =
    polyMap signature.polynomial ((ChainColimit.cocone collapsing).leg 3) 99
      (node signature (1 : Nat) (fun p => (retained p, false))) :=
  congrArg (fun children =>
    (⟨(1 : Nat), children⟩ : polyObj signature.polynomial (ChainColimit.carrier collapsing) 99))
    (funext (fun p => mixed_at_three p.down))

theorem mixed_payload :
    (preserves signature collapsing).descend payload 99 mixedNode = 42 :=
  (congrArg ((preserves signature collapsing).descend payload 99)
    mixed_node_at_three).trans
    ((preserves signature collapsing).factor payload 3 99
      (node signature (1 : Nat) (fun p => (retained p, false))))

#print axioms identifies
#print axioms mixed_payload

end KanonMeta.FinitarySequence.Tests
