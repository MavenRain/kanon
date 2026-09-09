/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityBaseChange
import test.Initiality

namespace KanonMeta.Initiality.Tests.BaseChange

/-- The shifted target has an extra inhabitant zero; no initiality is assumed. -/
def shifted (offset : Nat) : Algebra natPolynomial where
  Carrier := fun (_i) => Nat
  roll := fun shape => match shape with
    | .zero => fun (_xs) => offset
    | .succ => fun xs => Nat.succ (xs ())

def shiftMap : Hom natural (shifted 1) where
  map := Nat.succ
  comm := NatShape.rec (fun (_xs) => rfl) (fun (_xs) => rfl)

def shiftAgain : Hom (shifted 1) (shifted 2) where
  map := Nat.succ
  comm := NatShape.rec (fun (_xs) => rfl) (fun (_xs) => rfl)

def annotation : Nat → Nat := Nat.rec 9 (fun (_n) previous => previous + 2)

def shiftedWitness (offset : Nat) : Displayed (shifted offset) where
  Fibre := fun (n : Nat) => Fin (n + 1) × Nat
  step := fun shape => match shape with
    | .zero => fun (_xs) (_ih) => (directCount offset, annotation offset)
    | .succ => fun (_xs) ih => ((ih ()).1.succ, (ih ()).2 + 2)

def choose (n : Nat) : Fin (n + 1) × Nat := (directCount n, annotation n)

theorem choose_comm (offset : Nat) {i : Unit}
    (shape : natPolynomial.Shape i) (xs) :
    choose ((shifted offset).roll shape xs) =
      (shiftedWitness offset).step shape xs (fun pos => choose (xs pos)) :=
  match shape with
  | .zero => rfl
  | .succ => rfl

theorem shifted_result (n : Nat) :
    elim natInitial ((shiftedWitness 1).pullback shiftMap) (i := ()) n = choose (n + 1) :=
  elim_pullback_section natInitial shiftMap (shiftedWitness 1) choose (choose_comm 1) n

theorem shifted_certificate :
    (elim natInitial ((shiftedWitness 1).pullback shiftMap) (i := ()) (3 : Nat)).1.val = 4 :=
  congrArg (fun witness => witness.1.val) (shifted_result 3)

theorem shifted_annotation :
    (elim natInitial ((shiftedWitness 1).pullback shiftMap) (i := ()) (3 : Nat)).2 = 17 :=
  congrArg Prod.snd (shifted_result 3)

theorem composed_result (n : Nat) :
    elim natInitial (((shiftedWitness 2).pullback shiftAgain).pullback shiftMap)
      (i := ()) n = choose (n + 2) :=
  (elim_pullback_comp natInitial shiftMap shiftAgain (shiftedWitness 2) n).trans
    (elim_pullback_section natInitial (shiftAgain.comp shiftMap) (shiftedWitness 2)
      choose (choose_comm 2) n)

theorem composed_certificate :
    (elim natInitial (((shiftedWitness 2).pullback shiftAgain).pullback shiftMap)
      (i := ()) (3 : Nat)).1.val = 5 :=
  congrArg (fun witness => witness.1.val) (composed_result 3)

theorem composed_annotation :
    (elim natInitial (((shiftedWitness 2).pullback shiftAgain).pullback shiftMap)
      (i := ()) (3 : Nat)).2 = 19 :=
  congrArg Prod.snd (composed_result 3)

structure Box where
  value : Nat

def boxed : Algebra natPolynomial where
  Carrier := fun (_i) => Box
  roll := fun shape => match shape with
    | .zero => fun (_xs) => ⟨0⟩
    | .succ => fun xs => ⟨(xs ()).value + 1⟩

def box : Hom natural boxed where
  map := Box.mk
  comm := NatShape.rec (fun (_xs) => rfl) (fun (_xs) => rfl)

def unbox : Hom boxed natural where
  map := Box.value
  comm := NatShape.rec (fun (_xs) => rfl) (fun (_xs) => rfl)

def boxedInitial : Initial boxed where
  fold := fun B => (natInitial.fold B).comp unbox
  unique := fun B f g {i} => match i with
    | () => fun ⟨n⟩ => natInitial.unique B (f.comp box) (g.comp box) n

def boxedCount : Displayed boxed where
  Fibre := fun (b : Box) => Fin (b.value + 1)
  step := fun shape => match shape with
    | .zero => fun (_xs) (_ih) => ⟨0, Nat.zero_lt_succ 0⟩
    | .succ => fun (_xs) ih => (ih ()).succ

def boxedHom : DisplayedHomOver box boundedCount boxedCount where
  map := fun (_n) witness => witness
  comm := NatShape.rec (fun (_xs) (_ih) => rfl) (fun (_xs) (_ih) => rfl)

theorem boxed_elimination (n : Nat) :
    count n = elim boxedInitial boxedCount (i := ()) ⟨n⟩ :=
  elim_fusion_over natInitial boxedInitial boxedHom n

theorem boxed_observation : (elim boxedInitial boxedCount (i := ()) ⟨3⟩).val = 3 :=
  (congrArg Fin.val (boxed_elimination 3)).symm.trans count_three

def unboxedHom : DisplayedHomOver unbox boxedCount boundedCount where
  map := fun (_b) witness => witness
  comm := NatShape.rec (fun (_xs) (_ih) => rfl) (fun (_xs) (_ih) => rfl)

theorem composed_maps_keep_arbitrary_witness (n : Nat) (witness : Fin (n + 1)) :
    (DisplayedHomOver.comp unboxedHom boxedHom).map (i := ()) n witness = witness := rfl

theorem identity_keeps_arbitrary_witness (n : Nat) (witness : Fin (n + 1)) :
    (DisplayedHomOver.id boundedCount).map (i := ()) n witness = witness := rfl

/-- Identity base change is definitional, so the pulled-back eliminator is `count`. -/
theorem identity_base_change (n : Nat) :
    elim natInitial (boundedCount.pullback (Hom.id natural)) (i := ()) n = count n :=
  elim_pullback_id natInitial boundedCount n

theorem identity_base_change_observation :
    (elim natInitial (boundedCount.pullback (Hom.id natural)) (i := ()) (3 : Nat)).val = 3 :=
  (congrArg Fin.val (identity_base_change 3)).trans count_three

/-- The boxed count with the annotation of its value, over the boxed base. -/
def boxedAnnotated : Displayed boxed where
  Fibre := fun (b : Box) => Fin (b.value + 1) × Nat
  step := fun shape => match shape with
    | .zero => fun (_xs) (_ih) => (⟨0, Nat.zero_lt_succ 0⟩, 9)
    | .succ => fun (_xs) ih => ((ih ()).1.succ, (ih ()).2 + 2)

/-- The annotated count over the natural numbers, with every annotation raised by 3. -/
def offsetAnnotated : Displayed natural where
  Fibre := fun (n : Nat) => Fin (n + 1) × Nat
  step := fun shape => match shape with
    | .zero => fun (_xs) (_ih) => (⟨0, Nat.zero_lt_succ 0⟩, 12)
    | .succ => fun (_xs) ih => ((ih ()).1.succ, (ih ()).2 + 2)

/-- A witness map that adds the annotation of the base value: not an identity. -/
def annotateHom : DisplayedHomOver box boundedCount boxedAnnotated where
  map := fun n witness => (witness, annotation n)
  comm := NatShape.rec (fun (_xs) (_ih) => rfl) (fun (_xs) (_ih) => rfl)

/-- A witness map that adds 3 to the annotation: not an identity. -/
def offsetHom : DisplayedHomOver unbox boxedAnnotated offsetAnnotated where
  map := fun (_b) witness => (witness.1, witness.2 + 3)
  comm := NatShape.rec (fun (_xs) (_ih) => rfl) (fun (_xs) (_ih) => rfl)

/-- The composite of two non-identity maps computes annotation 3 + 3 = 18 through fusion. -/
theorem composed_annotation_observation :
    (elim natInitial offsetAnnotated (i := ()) (3 : Nat)).2 = 18 :=
  (congrArg Prod.snd
    (elim_fusion_over natInitial natInitial (DisplayedHomOver.comp offsetHom annotateHom)
      (i := ()) (3 : Nat))).symm

#print axioms shifted_annotation
#print axioms composed_annotation
#print axioms boxed_elimination

end KanonMeta.Initiality.Tests.BaseChange
