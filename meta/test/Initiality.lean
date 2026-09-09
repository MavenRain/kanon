/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.

Concrete models for the conditional initiality bridge. Nat's initiality
is established using Lean's existing Nat recursor, not inferred from Kan
extensions. The negative model has an unconstrained extra inhabitant.
-/

import KanonMeta.Initiality

namespace KanonMeta.Initiality.Tests

inductive NatShape where
  | zero
  | succ

def natPolynomial : Polynomial Unit where
  Shape := fun (_i) => NatShape
  Position := fun shape => match shape with
    | .zero => Empty
    | .succ => Unit
  child := fun (_shape) (_pos) => ()

def natural : Algebra natPolynomial where
  Carrier := fun (_i) => Nat
  roll := fun shape xs => match shape with
    | .zero => 0
    | .succ => Nat.succ (xs ())

def foldNat (B : Algebra natPolynomial) : Nat → B.Carrier () :=
  Nat.rec (B.roll .zero (fun pos => nomatch pos))
    (fun (_n) ih => B.roll .succ (fun (_pos) => ih))

def foldNatHom (B : Algebra natPolynomial) : Hom natural B where
  map := fun {i} => match i with | () => foldNat B
  comm := fun {i} => match i with
    | () => fun shape => match shape with
      | .zero => fun (_xs) =>
        congrArg (B.roll .zero) (funext (fun pos => nomatch pos))
      | .succ => fun (_xs) =>
        congrArg (B.roll .succ) (funext (fun pos => match pos with | () => rfl))

def natInitial : Initial natural where
  fold := foldNatHom
  unique := fun B f g {i} => match i with
    | () => Nat.rec
      ((f.comm .zero Empty.elim).trans
        ((congrArg (B.roll .zero) (funext (fun pos => nomatch pos))).trans
          (g.comm .zero Empty.elim).symm))
      (fun n ih =>
        (f.comm .succ (fun (_pos) => n)).trans
          ((congrArg (B.roll .succ) (funext (fun (_pos) => ih))).trans
            (g.comm .succ (fun (_pos) => n)).symm))

/-- The dependent fibre grows with the input, and each step uses its witness. -/
def boundedCount : Displayed natural where
  Fibre := fun (n : Nat) => Fin (n + 1)
  step := fun shape => match shape with
    | .zero => fun (_xs) (_ih) => ⟨0, Nat.zero_lt_succ 0⟩
    | .succ => fun (_xs) ih => (ih ()).succ

def count (n : Nat) : Fin (n + 1) := elim natInitial boundedCount (i := ()) n

theorem count_zero : count 0 = ⟨0, Nat.zero_lt_succ 0⟩ :=
  elim_beta natInitial boundedCount (i := ()) .zero Empty.elim

theorem count_succ (n : Nat) : count (n + 1) = (count n).succ :=
  elim_beta natInitial boundedCount (i := ()) .succ (fun (_pos) => n)

theorem count_three : (count 3).val = 3 :=
  congrArg Fin.val
    ((count_succ 2).trans
      (congrArg Fin.succ ((count_succ 1).trans
        (congrArg Fin.succ ((count_succ 0).trans
          (congrArg Fin.succ count_zero))))))

theorem nat_projection (n : Nat) :
    ((natInitial.fold boundedCount.total).map (i := ()) n).1 = n :=
  projection_fold natInitial boundedCount n

/-- An independent dependent section defined by the ordinary Nat recursor. -/
def directCount : (n : Nat) → Fin (n + 1) :=
  Nat.rec ⟨0, Nat.zero_lt_succ 0⟩ (fun (_n) ih => ih.succ)

theorem directCount_comm {i : Unit} (shape : natPolynomial.Shape i) (xs) :
    directCount (natural.roll shape xs) =
      boundedCount.step shape xs (fun pos => directCount (xs pos)) :=
  match shape with
  | .zero => rfl
  | .succ => rfl

/-- Initiality identifies the transported eliminator with a direct recursion. -/
theorem count_eq_direct (n : Nat) : count n = directCount n :=
  (elim_unique natInitial boundedCount (fun x => directCount x)
    directCount_comm (i := ()) n).symm

/-- Every lawful section agrees, including sections not chosen by initiality. -/
theorem boundedCount_unique
    (choose : (n : Nat) → Fin (n + 1))
    (zero : choose 0 = ⟨0, Nat.zero_lt_succ 0⟩)
    (succ : ∀ n, choose (n + 1) = (choose n).succ)
    (n : Nat) : choose n = count n :=
  elim_unique natInitial boundedCount (fun x => choose x)
    (fun shape => match shape with
      | .zero => fun (_xs) => zero
      | .succ => fun xs => succ (xs ())) (i := ()) n

/-- One nullary constructor at each of two distinct indices. -/
def pointPolynomial : Polynomial Bool where
  Shape := fun (_i) => Unit
  Position := fun (_shape) => Empty
  child := fun {_i} (_shape) pos => nomatch pos

def point : Algebra pointPolynomial where
  Carrier := fun (_i) => Unit
  roll := fun (_shape) (_xs) => ()

def pointFold (B : Algebra pointPolynomial) : Hom point B where
  map := fun (_x) => B.roll () (fun pos => nomatch pos)
  comm := fun shape => match shape with
    | () => fun (_xs) =>
      congrArg (B.roll ()) (funext (fun pos => nomatch pos))

theorem pointUnique (B : Algebra pointPolynomial) (f g : Hom point B)
    {i : Bool} (x : Unit) : f.map (i := i) x = g.map x :=
  PUnit.rec
    ((f.comm (i := i) () Empty.elim).trans
      ((congrArg (B.roll (i := i) ())
        (funext (fun pos => Empty.elim pos))).trans
          (g.comm (i := i) () Empty.elim).symm)) x

def pointInitial : Initial point where
  fold := pointFold
  unique := pointUnique

/-- Distinct fibres and constructor values ensure both indices are retained. -/
def indexedWitness : Displayed point where
  Fibre := fun {i} (_x) => Fin (i.toNat + 1)
  step := fun {i} (_shape) (_xs) (_ih) => ⟨i.toNat, Nat.lt_succ_self i.toNat⟩

def indexedChoice {i : Bool} (x : point.Carrier i) : indexedWitness.Fibre x :=
  ⟨i.toNat, Nat.lt_succ_self i.toNat⟩

theorem indexedChoice_comm {i : Bool} (shape : pointPolynomial.Shape i) (xs) :
    indexedChoice (point.roll shape xs) =
      indexedWitness.step shape xs (fun pos => indexedChoice (xs pos)) :=
  rfl

theorem indexed_elim_false :
    elim pointInitial indexedWitness (i := false) () = ⟨0, Nat.zero_lt_succ 0⟩ :=
  (elim_unique pointInitial indexedWitness indexedChoice indexedChoice_comm
    (i := false) ()).symm

theorem indexed_elim_true :
    elim pointInitial indexedWitness (i := true) () = ⟨1, Nat.lt_succ_self 1⟩ :=
  (elim_unique pointInitial indexedWitness indexedChoice indexedChoice_comm
    (i := true) ()).symm

def junk : Algebra pointPolynomial where
  Carrier := fun (_i) => Bool
  roll := fun (_shape) (_xs) => false

/-- This preserves the sole constructor but disagrees with identity on junk. -/
def collapse : Hom junk junk where
  map := fun (_x) => false
  comm := fun (_shape) (_xs) => rfl

/-- Folds exist to every algebra, so existence alone does not suffice. -/
def junkFold (B : Algebra pointPolynomial) : Hom junk B where
  map := fun (_x) => B.roll () (fun pos => nomatch pos)
  comm := fun shape => match shape with
    | () => fun (_xs) =>
      congrArg (B.roll ()) (funext (fun pos => nomatch pos))

theorem junk_not_initial : ¬ Nonempty (Initial junk) :=
  fun ⟨h⟩ => Bool.noConfusion
    (h.unique junk collapse (Hom.id junk) (i := false) true)

/-- A valid displayed algebra whose fibre over the extra inhabitant is empty. -/
def missingWitness : Displayed junk where
  Fibre := fun (b : Bool) => if b then Empty else Unit
  step := fun (_shape) (_xs) (_ih) => ()

theorem junk_no_section :
    ¬ Nonempty ({i : Bool} → (x : junk.Carrier i) → missingWitness.Fibre x) :=
  fun ⟨chooseWitness⟩ => Empty.elim (chooseWitness (i := true) true)

#print axioms natInitial
#print axioms count_three
#print axioms nat_projection
#print axioms count_eq_direct
#print axioms boundedCount_unique
#print axioms pointInitial
#print axioms indexed_elim_false
#print axioms indexed_elim_true
#print axioms junkFold
#print axioms junk_not_initial
#print axioms junk_no_section

end KanonMeta.Initiality.Tests
