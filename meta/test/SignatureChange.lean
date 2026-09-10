/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.SignatureChange
import KanonMeta.FinitaryConstruction
import test.Initiality

namespace KanonMeta.Initiality.Tests.SignatureChange

noncomputable section

inductive TreeShape where
  | tip
  | join

def treeSignature : FinitaryConstruction.Signature Unit where
  Shape := fun (_i) => TreeShape
  arity := fun s => match s with
    | .tip => 0
    | .join => 2
  child := fun (_s) (_p) => ()

abbrev trees := FinitaryConstruction.recursive treeSignature
abbrev treeInitial := FinitaryConstruction.recursiveInitial treeSignature

/-- A unary successor becomes a binary node containing two copies of its child. -/
def duplicate : SignatureMap natPolynomial treeSignature.polynomial where
  shape := fun s => match s with
    | .zero => .tip
    | .succ => .join
  position := fun s => match s with
    | .zero => fun q => Fin.elim0 q.down
    | .succ => fun (_q) => ()
  child := fun s => match s with
    | .zero => fun q => Fin.elim0 q.down
    | .succ => fun (_q) => rfl

/-- Keep only the right child when turning a binary tree into a natural number. -/
def rightDepth : SignatureMap treeSignature.polynomial natPolynomial where
  shape := fun s => match s with
    | .tip => .zero
    | .join => .succ
  position := fun s => match s with
    | .tip => fun q => nomatch q
    | .join => fun (_q) => ⟨(1 : Fin 2)⟩
  child := fun s => match s with
    | .tip => fun q => nomatch q
    | .join => fun (_q) => rfl

def weighted : Algebra treeSignature.polynomial where
  Carrier := fun (_i) => Nat
  roll := fun s => match s with
    | .tip => fun (_xs) => 2
    | .join => fun xs => 2 * xs ⟨(0 : Fin 2)⟩ + 3 * xs ⟨(1 : Fin 2)⟩ + 1

def full (n : Nat) : trees.Carrier () := (duplicate.translate natInitial trees).map n
def weight {i : Unit} (t : trees.Carrier i) : Nat := (treeInitial.fold weighted).map t
def fullWeight (n : Nat) : Nat := (duplicate.translate natInitial weighted).map (i := ()) n

theorem fullWeight_zero : fullWeight 0 = 2 :=
  duplicate.translate_beta natInitial weighted .zero Empty.elim

theorem fullWeight_succ (n : Nat) : fullWeight (n + 1) = 2 * fullWeight n + 3 * fullWeight n + 1 :=
  duplicate.translate_beta natInitial weighted .succ (fun (_p) => n)

theorem fullWeight_one : fullWeight 1 = 11 :=
  (fullWeight_succ 0).trans (congrArg (fun x => 2 * x + 3 * x + 1) fullWeight_zero)

theorem fullWeight_two : fullWeight 2 = 56 :=
  (fullWeight_succ 1).trans (congrArg (fun x => 2 * x + 3 * x + 1) fullWeight_one)

/-- This route invokes translation into a constructed initial tree algebra. -/
theorem fold_after_translation : weight (full 2) = 56 :=
  (duplicate.translate_fusion natInitial (treeInitial.fold weighted) (i := ()) (2 : Nat)).trans
    fullWeight_two

def roundtripHom : Hom natural ((rightDepth.comp duplicate).restrict natural) where
  map := fun n => n
  comm := NatShape.rec (fun (_xs) => rfl) (fun (_xs) => rfl)

theorem composed_translation (n : Nat) :
    (rightDepth.translate treeInitial natural).map (full n) = n :=
  (rightDepth.translate_comp duplicate natInitial treeInitial natural (i := ()) n).trans
    (SignatureMap.translate_unique (rightDepth.comp duplicate) natInitial natural
      roundtripHom (i := ()) n).symm

def asymmetricChildren : treeSignature.polynomial.Position (i := ()) .join → trees.Carrier () :=
  fun p => Fin.cases (full 0) (fun (_p) => full 1) p.down

def asymmetric : trees.Carrier () := trees.roll .join asymmetricChildren

/-- An asymmetric input detects selecting the left branch instead of the right. -/
theorem selected_right : (rightDepth.translate treeInitial natural).map asymmetric = (2 : Nat) :=
  (rightDepth.translate_beta treeInitial natural (i := ()) .join asymmetricChildren).trans
    (congrArg Nat.succ (composed_translation 1))

theorem identity_translation (t : trees.Carrier ()) :
    ((SignatureMap.id treeSignature.polynomial).translate treeInitial trees).map t = t :=
  SignatureMap.translate_id treeInitial t

/-- The fibre depends on the numeric base; annotations remain independent. -/
def certificate : Displayed weighted where
  Fibre := fun (n : Nat) => {v : Nat // v = n} × Nat
  step := fun s => match s with
    | .tip => fun (_xs) (_ws) => (⟨2, rfl⟩, 2)
    | .join => fun xs ws =>
        (⟨2 * (ws ⟨(0 : Fin 2)⟩).1.val + 3 * (ws ⟨(1 : Fin 2)⟩).1.val + 1,
          (congrArg (fun x => 2 * x + 3 * (ws ⟨(1 : Fin 2)⟩).1.val + 1)
            (ws ⟨(0 : Fin 2)⟩).1.property).trans
            (congrArg (fun y : Nat => Nat.add (Nat.add (Nat.mul 2 (xs ⟨(0 : Fin 2)⟩)) (Nat.mul 3 y)) 1)
              (ws ⟨(1 : Fin 2)⟩).1.property)⟩,
          2 * (ws ⟨(0 : Fin 2)⟩).2 + 3 * (ws ⟨(1 : Fin 2)⟩).2 + 1)

def choose (n : Nat) : certificate.Fibre (i := ()) n := (⟨n, rfl⟩, n)

theorem choose_comm {i : Unit} (s : treeSignature.polynomial.Shape i) (xs) :
    choose (weighted.roll s xs) = certificate.step s xs (fun p => choose (xs p)) :=
  match s with
  | .tip => rfl
  | .join => rfl

theorem dependent_translation (n : Nat) :
    elim natInitial ((duplicate.restrictDisplayed certificate).pullback
      (duplicate.translate natInitial weighted)) (i := ()) n = choose (fullWeight n) :=
  duplicate.elim_translate_section natInitial certificate (fun n => choose n) choose_comm n

theorem dependent_certificate :
    (elim natInitial ((duplicate.restrictDisplayed certificate).pullback
      (duplicate.translate natInitial weighted)) (i := ()) (2 : Nat)).1.val = 56 :=
  (congrArg (fun w => w.1.val) (dependent_translation 2)).trans fullWeight_two

theorem dependent_annotation :
    (elim natInitial ((duplicate.restrictDisplayed certificate).pullback
      (duplicate.translate natInitial weighted)) (i := ()) (2 : Nat)).2 = 56 :=
  (congrArg Prod.snd (dependent_translation 2)).trans fullWeight_two

def treeCertificate : Displayed trees := certificate.pullback (treeInitial.fold weighted)

theorem initial_target (n : Nat) :
    elim natInitial ((duplicate.restrictDisplayed treeCertificate).pullback
      (duplicate.translate natInitial trees)) (i := ()) n =
      elim treeInitial treeCertificate (full n) :=
  duplicate.elim_translate natInitial treeInitial treeCertificate n

theorem initial_target_annotation :
    (elim natInitial ((duplicate.restrictDisplayed treeCertificate).pullback
      (duplicate.translate natInitial trees)) (i := ()) (2 : Nat)).2 = 56 :=
  (congrArg Prod.snd ((initial_target 2).trans
    (elim_pullback_section treeInitial (treeInitial.fold weighted) certificate
      (fun n => choose n) choose_comm (full 2)))).trans fold_after_translation

/-- Restriction duplicates the supplied annotation, even when it differs from the base. -/
theorem arbitrary_witness :
    ((duplicate.restrictDisplayed certificate).step (i := ()) .succ
      (fun (_p) => (2 : Nat)) (fun (_p) => (⟨2, rfl⟩, 7))).2 = 36 := rfl

def swap : SignatureMap treeSignature.polynomial treeSignature.polynomial where
  shape := fun s => s
  position := fun s => match s with
    | .tip => fun q => Fin.elim0 q.down
    | .join => fun q => ⟨Fin.cases (1 : Fin 2) (fun (_p) => (0 : Fin 2)) q.down⟩
  child := fun s => match s with
    | .tip => fun q => Fin.elim0 q.down
    | .join => fun (_q) => rfl

def distinctChildren : (p : treeSignature.polynomial.Position (i := ()) .join) → Nat :=
  fun p => Fin.cases 2 (fun (_p) => 5) p.down

theorem ordered_children : weighted.roll (i := ()) .join distinctChildren = (20 : Nat) := rfl
theorem swapped_children : (swap.restrict weighted).roll (i := ()) .join distinctChildren = (17 : Nat) := rfl
theorem restored_children :
    ((swap.comp swap).restrict weighted).roll (i := ()) .join distinctChildren = (20 : Nat) := rfl

theorem distinct_witnesses :
    ((swap.restrictDisplayed certificate).step (i := ()) .join distinctChildren
      (fun p => (⟨distinctChildren p, rfl⟩, Fin.cases 7 (fun (_p) => 11) p.down))).2 = 44 := rfl

/-- Different child indices must not be silently interchanged. -/
def indexedSource : Polynomial Nat where
  Shape := fun (_i) => Unit
  Position := fun (_s) => Unit
  child := fun {i} (_s) (_p) => i

def indexedTarget : Polynomial Nat where
  Shape := fun (_i) => Unit
  Position := fun (_s) => Unit
  child := fun {i} (_s) (_p) => 0 + i

def indexedMap : SignatureMap indexedSource indexedTarget where
  shape := fun s => s
  position := fun (_s) p => p
  child := fun {i} (_s) (_p) => (Nat.zero_add i).symm

private theorem fin_transport {i j : Nat} (e : i = j) (x : Fin (i + 1)) :
    (e ▸ x : Fin (j + 1)).val = x.val :=
  @Eq.rec Nat i (fun j e => (e ▸ x : Fin (j + 1)).val = x.val) rfl j e

theorem indexed_child (n : Nat) (x : Fin (n + 1)) :
    (indexedMap.children (X := fun i => Fin (i + 1)) (i := n) () (fun (_p) => x) ()).val = x.val :=
  fin_transport (Nat.zero_add n).symm x

def indexedAlgebra : Algebra indexedTarget where
  Carrier := fun n => Fin (n + 1)
  roll := fun {i} (_s) (_xs) => ⟨0, Nat.zero_lt_succ i⟩

def indexedDisplay : Displayed indexedAlgebra where
  Fibre := fun x => {v : Nat // v = x.val} × Nat
  step := fun (_s) (_xs) ws => (⟨0, rfl⟩, (ws ()).2)

private theorem annotation_transport {i j : Nat} (e : i = j) (x : Fin (i + 1))
    (w : {v : Nat // v = x.val} × Nat) :
    (@Eq.rec Nat i (fun j e => {v : Nat // v = (e ▸ x : Fin (j + 1)).val} × Nat) w j e).2 = w.2 :=
  @Eq.rec Nat i (fun j e =>
    (@Eq.rec Nat i (fun j e => {v : Nat // v = (e ▸ x : Fin (j + 1)).val} × Nat) w j e).2 = w.2)
    rfl j e

theorem indexed_annotation (n : Nat) (x : Fin (n + 1))
    (w : {v : Nat // v = x.val} × Nat) :
    ((indexedMap.restrictDisplayed indexedDisplay).step (i := n) ()
      (fun (_p) => x) (fun (_p) => w)).2 = w.2 :=
  annotation_transport (Nat.zero_add n).symm x w

#print axioms fold_after_translation
#print axioms composed_translation
#print axioms selected_right
#print axioms identity_translation
#print axioms dependent_certificate
#print axioms dependent_annotation
#print axioms initial_target_annotation
#print axioms indexed_child
#print axioms indexed_annotation

end

end KanonMeta.Initiality.Tests.SignatureChange
