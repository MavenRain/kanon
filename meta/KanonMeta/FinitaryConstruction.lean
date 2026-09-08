/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.ChainColimit
import KanonMeta.FiniteBound

namespace KanonMeta.FinitaryConstruction

open Initiality InitialChain

universe u

structure Signature (Index : Type u) where
  Shape : Index → Type u
  arity : {i : Index} → Shape i → Nat
  child : {i : Index} → (shape : Shape i) → Fin (arity shape) → Index

variable {Index : Type u}

def Signature.polynomial (Q : Signature Index) : Polynomial.{u, u, u} Index where
  Shape := Q.Shape
  Position := fun shape => ULift.{u} (Fin (Q.arity shape))
  child := fun shape pos => Q.child shape pos.down

def node (Q : Signature Index) {X : Family Index} {i : Index} (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → X (Q.child shape pos)) :
    polyObj Q.polynomial X i :=
  ⟨shape, fun pos => xs pos.down⟩

theorem node_eta (Q : Signature Index) {X : Family Index} {i : Index}
    (x : polyObj Q.polynomial X i) : node Q x.1 (fun pos => x.2 ⟨pos⟩) = x := rfl

def iterate (S : Sequence Index) (n : Nat) : (k : Nat) → Map (S.obj n) (S.obj (n + k)) :=
  Nat.rec (fun _i x => x) (fun k previous i x => S.next (n + k) i (previous i x))

def advance (S : Sequence Index) {n m : Nat} (h : n ≤ m) : Map (S.obj n) (S.obj m) :=
  Nat.add_sub_of_le h ▸ iterate S n (m - n)

theorem advance_iterate (S : Sequence Index) (n k : Nat) :
    advance S (Nat.le_add_right n k) = iterate S n k :=
  Eq.rec (motive := fun l (_eq) => (e : n + l = n + k) →
      e ▸ iterate S n l = iterate S n k)
    (fun (_e) => rfl) (Nat.add_sub_cancel_left n k).symm
    (Nat.add_sub_of_le (Nat.le_add_right n k))

theorem advance_self (S : Sequence Index) (n : Nat) :
    advance S (Nat.le_refl n) = (fun _i x => x) := advance_iterate S n 0

theorem advance_next (S : Sequence Index) {n m : Nat} (h : n ≤ m) (i : Index)
    (x : S.obj n i) :
    advance S (Nat.le_succ_of_le h) i x = S.next m i (advance S h i x) :=
  (Nat.le.dest h).elim (fun k e =>
    Eq.rec (motive := fun m (_eq) => (h : n ≤ m) →
      advance S (Nat.le_succ_of_le h) i x = S.next m i (advance S h i x))
      (fun (_h) => (congrFun (congrFun (advance_iterate S n (k + 1)) i) x).trans
        (congrArg (S.next (n + k) i)
          (congrFun (congrFun (advance_iterate S n k) i) x).symm)) e h)

theorem advance_comp (S : Sequence Index) {n m k : Nat} (h : n ≤ m) (h' : m ≤ k)
    (i : Index) (x : S.obj n i) :
    advance S (Nat.le_trans h h') i x = advance S h' i (advance S h i x) :=
  Nat.le.rec (motive := fun k (h' : m ≤ k) =>
      advance S (Nat.le_trans h h') i x = advance S h' i (advance S h i x))
    (congrFun (congrFun (advance_self S m) i) (advance S h i x)).symm
    (fun {k} h' ih => (advance_next S (Nat.le_trans h h') i x).trans
      ((congrArg (S.next k i) ih).trans
        (advance_next S h' i (advance S h i x)).symm)) h'

theorem cocone_advance {S : Sequence Index} {Y : Family Index} (d : Cocone S Y)
    {n m : Nat} (h : n ≤ m) (i : Index) (x : S.obj n i) :
    d.leg m i (advance S h i x) = d.leg n i x :=
  Nat.le.rec (motive := fun m h => d.leg m i (advance S h i x) = d.leg n i x)
    (congrArg (d.leg n i) (congrFun (congrFun (advance_self S n) i) x))
    (fun {m} h ih => (congrArg (d.leg (m + 1) i) (advance_next S h i x)).trans
      ((d.comm m i (advance S h i x)).trans ih)) h

theorem advance_equal (S : Sequence Index) {n m k l : Nat}
    (hn : n ≤ k) (hm : m ≤ k) (hk : k ≤ l) (i : Index)
    (x : S.obj n i) (y : S.obj m i)
    (h : advance S hn i x = advance S hm i y) :
    advance S (Nat.le_trans hn hk) i x = advance S (Nat.le_trans hm hk) i y :=
  (advance_comp S hn hk i x).trans
    ((congrArg (advance S hk i) h).trans (advance_comp S hm hk i y).symm)

/-- Two representatives agree after moving to one later stage. -/
def Meets (S : Sequence Index) (i : Index) (a b : ChainColimit.Tagged S i) : Prop :=
  ∃ k, ∃ ha : a.1 ≤ k, ∃ hb : b.1 ≤ k, advance S ha i a.2 = advance S hb i b.2

theorem meets_refl (S : Sequence Index) (i : Index) (a : ChainColimit.Tagged S i) :
    Meets S i a a := ⟨a.1, Nat.le_refl a.1, Nat.le_refl a.1, rfl⟩

theorem meets_symm {S : Sequence Index} {i : Index} {a b : ChainColimit.Tagged S i}
    (h : Meets S i a b) : Meets S i b a :=
  h.elim (fun k hk => hk.elim (fun ha hk => hk.elim (fun hb e => ⟨k, hb, ha, e.symm⟩)))

theorem meets_trans {S : Sequence Index} {i : Index} {a b c : ChainColimit.Tagged S i}
    (h : Meets S i a b) (h' : Meets S i b c) : Meets S i a c :=
  h.elim (fun k hk => hk.elim (fun ha hk => hk.elim (fun hb e =>
    h'.elim (fun l hl => hl.elim (fun hb' hl => hl.elim (fun hc e' =>
      ⟨max k l, Nat.le_trans ha (Nat.le_max_left k l),
        Nat.le_trans hc (Nat.le_max_right k l),
        (advance_equal S ha hb (Nat.le_max_left k l) i a.2 b.2 e).trans
          (advance_equal S hb' hc (Nat.le_max_right k l) i b.2 c.2 e')⟩))))))

def eventualSetoid (S : Sequence Index) (i : Index) : Setoid (ChainColimit.Tagged S i) where
  r := Meets S i
  iseqv := ⟨meets_refl S i, fun h => meets_symm h, fun h h' => meets_trans h h'⟩

theorem step_meets (S : Sequence Index) (i : Index) (a b : ChainColimit.Tagged S i)
    (h : ChainColimit.step S i a b) : Meets S i a b :=
  Eq.rec (motive := fun b (_eq) => Meets S i a b)
    (show Meets S i a ⟨a.1 + 1, S.next a.1 i a.2⟩ from
      ⟨a.1 + 1, Nat.le_succ a.1, Nat.le_refl (a.1 + 1),
        (congrFun (congrFun (advance_iterate S a.1 1) i) a.2).trans
          (congrFun (congrFun (advance_self S (a.1 + 1)) i) (S.next a.1 i a.2)).symm⟩)
    h.symm

def eventualClass (S : Sequence Index) (i : Index) :
    ChainColimit.carrier S i → Quotient (eventualSetoid S i) :=
  Quot.lift (Quotient.mk (eventualSetoid S i))
    (fun a b h => Quotient.sound (step_meets S i a b h))

/-- Equality in the adjacent-step quotient has a common-stage witness.
No connecting map is required to be injective. -/
theorem leg_eq_meets (S : Sequence Index) {n m : Nat} (i : Index)
    (x : S.obj n i) (y : S.obj m i)
    (h : (ChainColimit.cocone S).leg n i x = (ChainColimit.cocone S).leg m i y) :
    Meets S i ⟨n, x⟩ ⟨m, y⟩ :=
  Quotient.exact (congrArg (eventualClass S i) h)

theorem meets_leg_eq (S : Sequence Index) {n m : Nat} (i : Index)
    (x : S.obj n i) (y : S.obj m i) (h : Meets S i ⟨n, x⟩ ⟨m, y⟩) :
    (ChainColimit.cocone S).leg n i x = (ChainColimit.cocone S).leg m i y :=
  h.elim (fun k hk => hk.elim (fun hn hk => hk.elim (fun hm e =>
    (cocone_advance (ChainColimit.cocone S) hn i x).symm.trans
      ((congrArg ((ChainColimit.cocone S).leg k i) e).trans
        (cocone_advance (ChainColimit.cocone S) hm i y)))))

theorem has_representative (S : Sequence Index) (i : Index)
    (x : ChainColimit.carrier S i) :
    ∃ a : ChainColimit.Tagged S i, (ChainColimit.cocone S).leg a.1 i a.2 = x :=
  Quot.inductionOn x (fun a => ⟨a, rfl⟩)

/-- Every finite family of children has representatives at one common stage.
The empty family is represented at stage zero. -/
theorem synchronize (Q : Signature Index) (S : Sequence Index) {i : Index}
    (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → ChainColimit.carrier S (Q.child shape pos)) :
    ∃ n, ∃ ys : (pos : Fin (Q.arity shape)) → S.obj n (Q.child shape pos),
      ∀ pos, (ChainColimit.cocone S).leg n (Q.child shape pos) (ys pos) = xs pos :=
  let representatives := fun pos => Classical.choose (has_representative S (Q.child shape pos) (xs pos))
  let stages := fun pos => (representatives pos).1
  ⟨FiniteBound.bound stages,
    (fun pos => advance S (FiniteBound.le_bound stages pos) (Q.child shape pos)
      (representatives pos).2),
    fun pos => (cocone_advance (ChainColimit.cocone S) (FiniteBound.le_bound stages pos)
      (Q.child shape pos) (representatives pos).2).trans
      (Classical.choose_spec (has_representative S (Q.child shape pos) (xs pos)))⟩

theorem advance_node (Q : Signature Index) (S : Sequence Index)
    {n m : Nat} (h : n ≤ m) {i : Index} (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → S.obj n (Q.child shape pos)) :
    advance (mappedSequence Q.polynomial S) h i (node Q shape xs) =
      node Q shape (fun pos => advance S h (Q.child shape pos) (xs pos)) :=
  Nat.le.rec (motive := fun endpoint (h : n ≤ endpoint) =>
    advance (mappedSequence Q.polynomial S) h i (node Q shape xs) =
      node Q shape (fun pos => advance S h (Q.child shape pos) (xs pos)))
    ((congrFun (congrFun (advance_self (mappedSequence Q.polynomial S) n) i)
      (node Q shape xs)).trans
      (congrArg (node Q shape) (funext (fun pos =>
        (congrFun (congrFun (advance_self S n) (Q.child shape pos)) (xs pos)).symm))))
    (fun {m} h ih => (advance_next (mappedSequence Q.polynomial S) h i (node Q shape xs)).trans
      ((congrArg (polyMap Q.polynomial (S.next m) i) ih).trans
        (congrArg (node Q shape) (funext (fun pos =>
          (advance_next S h (Q.child shape pos) (xs pos)).symm))))) h

theorem node_legs_advance (Q : Signature Index) {S : Sequence Index} {Y : Family Index}
    (d : Cocone (mappedSequence Q.polynomial S) Y)
    {n m : Nat} (h : n ≤ m) {i : Index} (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → S.obj n (Q.child shape pos)) :
    d.leg m i (node Q shape (fun pos => advance S h (Q.child shape pos) (xs pos))) =
      d.leg n i (node Q shape xs) :=
  (congrArg (d.leg m i) (advance_node Q S h shape xs).symm).trans
    (cocone_advance d h i (node Q shape xs))

/-- The value assigned by any mapped cocone is independent of the stage
and of every chosen child representative. -/
theorem representatives_respect (Q : Signature Index) {S : Sequence Index} {Y : Family Index}
    (d : Cocone (mappedSequence Q.polynomial S) Y) {n m : Nat} {i : Index}
    (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → S.obj n (Q.child shape pos))
    (ys : (pos : Fin (Q.arity shape)) → S.obj m (Q.child shape pos))
    (h : ∀ pos, (ChainColimit.cocone S).leg n (Q.child shape pos) (xs pos) =
      (ChainColimit.cocone S).leg m (Q.child shape pos) (ys pos)) :
    d.leg n i (node Q shape xs) = d.leg m i (node Q shape ys) :=
  let meetings := fun pos => leg_eq_meets S (Q.child shape pos) (xs pos) (ys pos) (h pos)
  let stages := fun pos => Classical.choose (meetings pos)
  let left := fun pos => Classical.choose (Classical.choose_spec (meetings pos))
  let right := fun pos => Classical.choose (Classical.choose_spec (Classical.choose_spec (meetings pos)))
  let equal := fun pos => Classical.choose_spec
    (Classical.choose_spec (Classical.choose_spec (meetings pos)))
  let common := max n (max m (FiniteBound.bound stages))
  let hn : n ≤ common := Nat.le_max_left n (max m (FiniteBound.bound stages))
  let hm : m ≤ common := Nat.le_trans (Nat.le_max_left m (FiniteBound.bound stages))
    (Nat.le_max_right n (max m (FiniteBound.bound stages)))
  let hk := fun pos => Nat.le_trans (FiniteBound.le_bound stages pos)
    (Nat.le_trans (Nat.le_max_right m (FiniteBound.bound stages))
      (Nat.le_max_right n (max m (FiniteBound.bound stages))))
  (node_legs_advance Q d hn shape xs).symm.trans
    ((congrArg (d.leg common i) (congrArg (node Q shape) (funext (fun pos =>
      advance_equal S (left pos) (right pos) (hk pos) (Q.child shape pos)
        (xs pos) (ys pos) (equal pos))))).trans
      (node_legs_advance Q d hm shape ys))

noncomputable def representativeStage (Q : Signature Index) (S : Sequence Index) {i : Index}
    (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → ChainColimit.carrier S (Q.child shape pos)) : Nat :=
  Classical.choose (synchronize Q S shape xs)

noncomputable def representativeChildren (Q : Signature Index) (S : Sequence Index) {i : Index}
    (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → ChainColimit.carrier S (Q.child shape pos)) :
    (pos : Fin (Q.arity shape)) → S.obj (representativeStage Q S shape xs) (Q.child shape pos) :=
  Classical.choose (Classical.choose_spec (synchronize Q S shape xs))

theorem representative_eq (Q : Signature Index) (S : Sequence Index) {i : Index}
    (shape : Q.Shape i)
    (xs : (pos : Fin (Q.arity shape)) → ChainColimit.carrier S (Q.child shape pos))
    (pos : Fin (Q.arity shape)) :
    (ChainColimit.cocone S).leg (representativeStage Q S shape xs) (Q.child shape pos)
      (representativeChildren Q S shape xs pos) = xs pos :=
  Classical.choose_spec (Classical.choose_spec (synchronize Q S shape xs)) pos

/-- Descent chooses a common finite stage; representatives_respect proves
that all such choices give the same result. -/
noncomputable def descend (Q : Signature Index) (S : Sequence Index) {Y : Family Index}
    (d : Cocone (mappedSequence Q.polynomial S) Y) :
    Map (polyObj Q.polynomial (ChainColimit.carrier S)) Y :=
  fun i x => d.leg (representativeStage Q S x.1 (fun pos => x.2 ⟨pos⟩)) i
    (node Q x.1 (representativeChildren Q S x.1 (fun pos => x.2 ⟨pos⟩)))

theorem descend_on_leg (Q : Signature Index) (S : Sequence Index) {Y : Family Index}
    (d : Cocone (mappedSequence Q.polynomial S) Y) (n : Nat) (i : Index)
    (x : polyObj Q.polynomial (S.obj n) i) :
    descend Q S d i (polyMap Q.polynomial ((ChainColimit.cocone S).leg n) i x) =
      d.leg n i x :=
  (representatives_respect Q d x.1
    (representativeChildren Q S x.1
      (fun pos => (ChainColimit.cocone S).leg n (Q.child x.1 pos) (x.2 ⟨pos⟩)))
    (fun pos => x.2 ⟨pos⟩)
    (representative_eq Q S x.1
      (fun pos => (ChainColimit.cocone S).leg n (Q.child x.1 pos) (x.2 ⟨pos⟩)))).trans
    (congrArg (d.leg n i) (node_eta Q x))

/-- Every finite-arity polynomial preserves the explicit ChainColimit cocone
of every sequence. No claim about other supplied cocones is needed here. -/
noncomputable def preserves (Q : Signature Index) (S : Sequence Index) :
    Colimit (mappedCocone Q.polynomial (ChainColimit.cocone S)) where
  descend := descend Q S
  factor := descend_on_leg Q S
  unique := fun f g h i x => (synchronize Q S x.1 (fun pos => x.2 ⟨pos⟩)).elim
    (fun n hn => hn.elim (fun ys hy =>
      let e : polyMap Q.polynomial ((ChainColimit.cocone S).leg n) i (node Q x.1 ys) = x :=
        (congrArg (node Q x.1) (funext hy)).trans (node_eta Q x)
      (congrArg (f i) e.symm).trans ((h n i (node Q x.1 ys)).trans (congrArg (g i) e))))

abbrev recursiveSequence (Q : Signature Index) := initialSequence Q.polynomial

noncomputable def recursivePreserved (Q : Signature Index) : Colimit
    (mappedCocone Q.polynomial (ChainColimit.cocone (recursiveSequence Q))) :=
  preserves Q (recursiveSequence Q)

/-- The carrier is the quotient of the signature's finite initial stages. -/
noncomputable def recursive (Q : Signature Index) : Algebra Q.polynomial :=
  chainAlgebra (ChainColimit.cocone (recursiveSequence Q)) (recursivePreserved Q)

/-- Initiality follows from the constructed colimit and its proved preservation,
with no existence or initiality hypotheses supplied by the caller. -/
noncomputable def recursiveInitial (Q : Signature Index) : Initial (recursive Q) :=
  chainInitial (ChainColimit.cocone (recursiveSequence Q)) (recursivePreserved Q)
    (ChainColimit.isColimit (recursiveSequence Q))

end KanonMeta.FinitaryConstruction
