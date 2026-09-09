/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityFusion
import test.Initiality

namespace KanonMeta.Initiality.Tests.Fusion

def forgetBound : DisplayedHom boundedCount (Displayed.constant natural natural) where
  map := fun _value witness => witness.val
  comm := NatShape.rec (fun _xs _ih => rfl) (fun _xs _ih => rfl)

theorem fold_recovered (n : Nat) :
    elim natInitial (Displayed.constant natural natural) (i := ()) n = n :=
  (elim_constant natInitial natural (i := ()) n).trans
    (natInitial.unique natural (natInitial.fold natural) (Hom.id natural) n)

theorem dependent_to_fold (n : Nat) : (count n).val = n :=
  (elim_fusion natInitial forgetBound (i := ()) n).trans (fold_recovered n)

def indexedResult : Displayed point where
  Fibre := fun {i} _value => Nat × Fin (i.toNat + 1)
  step := fun {i} _shape _xs _ih => (i.toNat + 10, ⟨i.toNat, Nat.lt_succ_self i.toNat⟩)

def annotate : DisplayedHom indexedWitness indexedResult where
  map := fun {i} _value witness => (i.toNat + 10, witness)
  comm := fun _shape _xs _ih => rfl

theorem false_index_observation :
    (elim pointInitial indexedResult (i := false) ()).1 = 10 :=
  congrArg Prod.fst (elim_fusion pointInitial annotate (i := false) ()).symm

theorem true_index_observation :
    (elim pointInitial indexedResult (i := true) ()).1 = 11 :=
  congrArg Prod.fst (elim_fusion pointInitial annotate (i := true) ()).symm

theorem true_index_witness :
    (elim pointInitial indexedResult (i := true) ()).2.val = 1 :=
  (congrArg (fun witness => witness.2.val)
    (elim_fusion pointInitial annotate (i := true) ()).symm).trans
    (congrArg Fin.val indexed_elim_true)

theorem identity_composition_retains_map (n : Nat) (witness : Fin (n + 1)) :
    ((DisplayedHom.id (Displayed.constant natural natural)).comp
      (forgetBound.comp (DisplayedHom.id boundedCount))).map (i := ()) n witness = witness.val :=
  rfl

theorem total_map_retains_base (n : Nat) (witness : Fin (n + 1)) :
    forgetBound.totalHom.map (i := ()) ⟨n, witness⟩ = ⟨n, witness.val⟩ := rfl

#print axioms dependent_to_fold
#print axioms false_index_observation
#print axioms true_index_witness

end KanonMeta.Initiality.Tests.Fusion
