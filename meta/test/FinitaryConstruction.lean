/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.FinitaryConstruction

/-!
The quotient algebra retains payloads and every ordered child. Shapes choose
arbitrary natural-number indices for zero, two, or three recursive positions.
The main tree combines children of heights one, two, and three. Observations
use the constructed initiality witness.
-/

namespace KanonMeta.FinitaryConstruction.Tests

open Initiality

noncomputable section

inductive Shape : Nat → Type where
  | leaf (i payload : Nat) : Shape i
  | binary (i left right : Nat) : Shape i
  | ternary (i first second third : Nat) : Shape i

def signature : Signature Nat where
  Shape := Shape
  arity := fun {i} shape => match shape with
    | .leaf .(i) (_payload) => 0
    | .binary .(i) (_left) (_right) => 2
    | .ternary .(i) (_first) (_second) (_third) => 3
  child := fun {i} shape => match shape with
    | .leaf .(i) (_payload) => Fin.elim0
    | .binary .(i) left right => Fin.cases left (fun (_pos) => right)
    | .ternary .(i) first second third =>
        Fin.cases first (Fin.cases second (fun (_pos) => third))

abbrev Tree := (recursive signature).Carrier

def leaf (i payload : Nat) : Tree i :=
  (recursive signature).roll (.leaf i payload) (fun pos => Fin.elim0 pos.down)

def binary (i : Nat) {j k : Nat} (left : Tree j) (right : Tree k) : Tree i :=
  (recursive signature).roll (.binary i j k)
    (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.binary i j k) p))
      left (fun (_pos) => right) pos.down)

def ternary (i : Nat) {j k l : Nat}
    (first : Tree j) (second : Tree k) (third : Tree l) : Tree i :=
  (recursive signature).roll (.ternary i j k l)
    (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.ternary i j k l) p)) first
      (Fin.cases
        (motive := fun p => Tree (signature.child (.ternary i j k l) p.succ))
        second (fun (_pos) => third)) pos.down)

theorem arities : signature.arity (.leaf 99 42) = 0 ∧
    signature.arity (.binary 99 3 8) = 2 ∧
    signature.arity (.ternary 99 3 8 21) = 3 := ⟨rfl, rfl, rfl⟩

theorem arbitrary_child_indices (i j k l : Nat) :
    signature.child (.ternary i j k l) (0 : Fin 3) = j ∧
    signature.child (.ternary i j k l) (1 : Fin 3) = k ∧
    signature.child (.ternary i j k l) (2 : Fin 3) = l := ⟨rfl, rfl, rfl⟩

theorem nullary_positions_empty (i payload : Nat) :
    ¬ Nonempty (signature.polynomial.Position (.leaf i payload)) :=
  fun ⟨pos⟩ => Fin.elim0 pos.down

def observationAlgebra (onLeaf : Nat → Nat) (onBinary : Nat → Nat → Nat)
    (onTernary : Nat → Nat → Nat → Nat) : Algebra signature.polynomial where
  Carrier := fun (_i) => Nat
  roll := fun {i} shape => match shape with
    | .leaf .(i) payload => fun (_xs) => onLeaf payload
    | .binary .(i) (_j) (_k) => fun xs =>
        onBinary (xs ⟨(0 : Fin 2)⟩) (xs ⟨(1 : Fin 2)⟩)
    | .ternary .(i) (_j) (_k) (_l) => fun xs =>
        onTernary (xs ⟨(0 : Fin 3)⟩) (xs ⟨(1 : Fin 3)⟩) (xs ⟨(2 : Fin 3)⟩)

def observe (onLeaf : Nat → Nat) (onBinary : Nat → Nat → Nat)
    (onTernary : Nat → Nat → Nat → Nat) {i : Nat} (tree : Tree i) : Nat :=
  ((recursiveInitial signature).fold
    (observationAlgebra onLeaf onBinary onTernary)).map tree

section Observation

variable (onLeaf : Nat → Nat) (onBinary : Nat → Nat → Nat)
  (onTernary : Nat → Nat → Nat → Nat)

theorem observe_leaf (i payload : Nat) :
    observe onLeaf onBinary onTernary (leaf i payload) = onLeaf payload :=
  ((recursiveInitial signature).fold
    (observationAlgebra onLeaf onBinary onTernary)).comm
    (.leaf i payload) (fun pos => Fin.elim0 pos.down)

theorem observe_binary (i : Nat) {j k : Nat} (left : Tree j) (right : Tree k) :
    observe onLeaf onBinary onTernary (binary i left right) =
      onBinary (observe onLeaf onBinary onTernary left)
        (observe onLeaf onBinary onTernary right) :=
  ((recursiveInitial signature).fold
    (observationAlgebra onLeaf onBinary onTernary)).comm
    (.binary i j k) (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.binary i j k) p))
      left (fun (_pos) => right) pos.down)

theorem observe_ternary (i : Nat) {j k l : Nat}
    (first : Tree j) (second : Tree k) (third : Tree l) :
    observe onLeaf onBinary onTernary (ternary i first second third) =
      onTernary (observe onLeaf onBinary onTernary first)
        (observe onLeaf onBinary onTernary second)
        (observe onLeaf onBinary onTernary third) :=
  ((recursiveInitial signature).fold
    (observationAlgebra onLeaf onBinary onTernary)).comm
    (.ternary i j k l)
    (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.ternary i j k l) p)) first
      (Fin.cases
        (motive := fun p => Tree (signature.child (.ternary i j k l) p.succ))
        second (fun (_pos) => third)) pos.down)

theorem observe_binary_eq (i : Nat) {j k : Nat} (left : Tree j) (right : Tree k)
    {a b : Nat} (hl : observe onLeaf onBinary onTernary left = a)
    (hr : observe onLeaf onBinary onTernary right = b) :
    observe onLeaf onBinary onTernary (binary i left right) = onBinary a b :=
  (observe_binary onLeaf onBinary onTernary i left right).trans
    ((congrArg (fun x => onBinary x (observe onLeaf onBinary onTernary right)) hl).trans
      (congrArg (onBinary a) hr))

theorem observe_ternary_eq (i : Nat) {j k l : Nat}
    (first : Tree j) (second : Tree k) (third : Tree l) {a b c : Nat}
    (hf : observe onLeaf onBinary onTernary first = a)
    (hs : observe onLeaf onBinary onTernary second = b)
    (ht : observe onLeaf onBinary onTernary third = c) :
    observe onLeaf onBinary onTernary (ternary i first second third) =
      onTernary a b c :=
  (observe_ternary onLeaf onBinary onTernary i first second third).trans
    ((congrArg (fun x => onTernary x
      (observe onLeaf onBinary onTernary second)
      (observe onLeaf onBinary onTernary third)) hf).trans
      ((congrArg (fun x => onTernary a x
        (observe onLeaf onBinary onTernary third)) hs).trans
        (congrArg (onTernary a b) ht)))

end Observation

def firstChild : Tree 3 := leaf 3 2
def secondChild : Tree 8 := binary 8 (leaf 13 3) (leaf 34 5)
def deepChild : Tree 55 := ternary 55 (leaf 89 11) (leaf 144 6) (leaf 233 8)
def thirdChild : Tree 21 := binary 21 (leaf 377 7) deepChild
def values : Tree 99 := ternary 99 firstChild secondChild thirdChild

section ConcreteObservation

variable (onLeaf : Nat → Nat) (onBinary : Nat → Nat → Nat)
  (onTernary : Nat → Nat → Nat → Nat)

theorem observe_first :
    observe onLeaf onBinary onTernary firstChild = onLeaf 2 :=
  observe_leaf onLeaf onBinary onTernary 3 2

theorem observe_second : observe onLeaf onBinary onTernary secondChild =
    onBinary (onLeaf 3) (onLeaf 5) :=
  observe_binary_eq onLeaf onBinary onTernary 8 _ _
    (observe_leaf onLeaf onBinary onTernary 13 3)
    (observe_leaf onLeaf onBinary onTernary 34 5)

theorem observe_deep : observe onLeaf onBinary onTernary deepChild =
    onTernary (onLeaf 11) (onLeaf 6) (onLeaf 8) :=
  observe_ternary_eq onLeaf onBinary onTernary 55 _ _ _
    (observe_leaf onLeaf onBinary onTernary 89 11)
    (observe_leaf onLeaf onBinary onTernary 144 6)
    (observe_leaf onLeaf onBinary onTernary 233 8)

theorem observe_third : observe onLeaf onBinary onTernary thirdChild =
    onBinary (onLeaf 7) (onTernary (onLeaf 11) (onLeaf 6) (onLeaf 8)) :=
  observe_binary_eq onLeaf onBinary onTernary 21 _ _
    (observe_leaf onLeaf onBinary onTernary 377 7)
    (observe_deep onLeaf onBinary onTernary)

theorem observe_values : observe onLeaf onBinary onTernary values =
    onTernary (onLeaf 2) (onBinary (onLeaf 3) (onLeaf 5))
      (onBinary (onLeaf 7) (onTernary (onLeaf 11) (onLeaf 6) (onLeaf 8))) :=
  observe_ternary_eq onLeaf onBinary onTernary 99 _ _ _
    (observe_first onLeaf onBinary onTernary)
    (observe_second onLeaf onBinary onTernary)
    (observe_third onLeaf onBinary onTernary)

end ConcreteObservation

abbrev total {i : Nat} (tree : Tree i) : Nat :=
  observe id Nat.add (fun x y z => x + y + z) tree

abbrev weighted {i : Nat} (tree : Tree i) : Nat :=
  observe id (fun x y => 2 * x + 3 * y) (fun x y z => 2 * x + 3 * y + 5 * z) tree

abbrev height {i : Nat} (tree : Tree i) : Nat :=
  observe (fun (_payload) => 1) (fun x y => Nat.max x y + 1)
    (fun x y z => Nat.max (Nat.max x y) z + 1) tree

theorem total_values : total values = 42 :=
  observe_values id Nat.add (fun x y z => x + y + z)

theorem weighted_values : weighted values = 1337 :=
  observe_values id (fun x y => 2 * x + 3 * y) (fun x y z => 2 * x + 3 * y + 5 * z)

theorem independent_child_depths :
    height firstChild = 1 ∧ height secondChild = 2 ∧ height thirdChild = 3 :=
  ⟨observe_first _ _ _, observe_second _ _ _, observe_third _ _ _⟩

theorem height_values : height values = 4 := observe_values _ _ _

def copy {i : Nat} (tree : Tree i) : Tree i :=
  ((recursiveInitial signature).fold (recursive signature)).map tree

theorem copy_eq {i : Nat} (tree : Tree i) : copy tree = tree :=
  (recursiveInitial signature).unique (recursive signature)
    ((recursiveInitial signature).fold (recursive signature))
    (Hom.id (recursive signature)) tree

theorem copied_payloads : total (copy values) = 42 :=
  (congrArg total (copy_eq values)).trans total_values

theorem copied_positions : weighted (copy values) = 1337 :=
  (congrArg weighted (copy_eq values)).trans weighted_values

/-- The displayed fibre depends on the tree's retained payload observation. -/
def counted : Displayed (recursive signature) where
  Fibre := fun tree => {value : Nat // value = total tree}
  step := fun shape xs ih =>
    ⟨(observationAlgebra id Nat.add (fun x y z => x + y + z)).roll shape
        (fun pos => (ih pos).val),
      (congrArg
        ((observationAlgebra id Nat.add (fun x y z => x + y + z)).roll shape)
        (funext (fun pos => (ih pos).property))).trans
          (((recursiveInitial signature).fold
            (observationAlgebra id Nat.add (fun x y z => x + y + z))).comm
            shape xs).symm⟩

def count {i : Nat} (tree : Tree i) : counted.Fibre tree :=
  elim (recursiveInitial signature) counted tree

theorem count_roll {i : Nat} (shape : signature.polynomial.Shape i)
    (xs : (pos : signature.polynomial.Position shape) →
      Tree (signature.polynomial.child shape pos)) :
    (count ((recursive signature).roll shape xs)).val =
      (observationAlgebra id Nat.add (fun x y z => x + y + z)).roll shape
        (fun pos => (count (xs pos)).val) :=
  congrArg Subtype.val (elim_beta (recursiveInitial signature) counted shape xs)

theorem count_leaf (i payload : Nat) : (count (leaf i payload)).val = payload :=
  count_roll (.leaf i payload) (fun pos => Fin.elim0 pos.down)

theorem count_binary (i : Nat) {j k : Nat} (left : Tree j) (right : Tree k) :
    (count (binary i left right)).val = (count left).val + (count right).val :=
  count_roll (.binary i j k)
    (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.binary i j k) p))
      left (fun (_pos) => right) pos.down)

theorem count_ternary (i : Nat) {j k l : Nat}
    (first : Tree j) (second : Tree k) (third : Tree l) :
    (count (ternary i first second third)).val =
      (count first).val + (count second).val + (count third).val :=
  count_roll (.ternary i j k l)
    (fun pos => Fin.cases
      (motive := fun p => Tree (signature.child (.ternary i j k l) p)) first
      (Fin.cases
        (motive := fun p => Tree (signature.child (.ternary i j k l) p.succ))
        second (fun (_pos) => third)) pos.down)

theorem count_binary_eq (i : Nat) {j k : Nat} (left : Tree j) (right : Tree k)
    {a b : Nat} (hl : (count left).val = a) (hr : (count right).val = b) :
    (count (binary i left right)).val = a + b :=
  (count_binary i left right).trans
    ((congrArg (fun x => x + (count right).val) hl).trans
      (congrArg (fun y => a + y) hr))

theorem count_ternary_eq (i : Nat) {j k l : Nat}
    (first : Tree j) (second : Tree k) (third : Tree l) {a b c : Nat}
    (hf : (count first).val = a) (hs : (count second).val = b)
    (ht : (count third).val = c) :
    (count (ternary i first second third)).val = a + b + c :=
  (count_ternary i first second third).trans
    ((congrArg (fun x => x + (count second).val + (count third).val) hf).trans
      ((congrArg (fun y => a + y + (count third).val) hs).trans
        (congrArg (fun z => a + b + z) ht)))

theorem count_first : (count firstChild).val = 2 := count_leaf 3 2

theorem count_second : (count secondChild).val = 8 :=
  count_binary_eq 8 _ _ (count_leaf 13 3) (count_leaf 34 5)

theorem count_deep : (count deepChild).val = 25 :=
  count_ternary_eq 55 _ _ _ (count_leaf 89 11) (count_leaf 144 6)
    (count_leaf 233 8)

theorem count_third : (count thirdChild).val = 32 :=
  count_binary_eq 21 _ _ (count_leaf 377 7) count_deep

/-- The count chain runs through `count_roll`, so it needs the computed fold. -/
theorem count_values : (count values).val = 42 :=
  count_ternary_eq 99 _ _ _ count_first count_second count_third

theorem count_copied : (count (copy values)).val = 42 :=
  (congrArg (fun tree => (count tree).val) (copy_eq values)).trans count_values

theorem leaf_payload_ne (i : Nat) {a b : Nat} (h : a ≠ b) :
    leaf i a ≠ leaf i b :=
  fun eq => h ((observe_leaf id Nat.add (fun x y z => x + y + z) i a).symm.trans
    ((congrArg total eq).trans
      (observe_leaf id Nat.add (fun x y z => x + y + z) i b)))

theorem ordered_binary_observation (i j : Nat) (a b : Nat) :
    weighted (binary i (leaf j a) (leaf j b)) = 2 * a + 3 * b :=
  observe_binary_eq id (fun x y => 2 * x + 3 * y)
    (fun x y z => 2 * x + 3 * y + 5 * z) i _ _
    (observe_leaf _ _ _ j a) (observe_leaf _ _ _ j b)

/-- A commutative sum alone would miss this ordering error. -/
theorem swapped_children_ne (i j : Nat) :
    binary i (leaf j 2) (leaf j 5) ≠ binary i (leaf j 5) (leaf j 2) :=
  fun eq => (show (19 : Nat) ≠ 16 from of_decide_eq_true rfl)
    ((ordered_binary_observation i j 2 5).symm.trans
      ((congrArg weighted eq).trans (ordered_binary_observation i j 5 2)))

abbrev omitted {i : Nat} (tree : Tree i) : Nat :=
  observe id Nat.add (fun x y (_third) => x + y) tree

theorem omitted_values : omitted values = 10 :=
  observe_values id Nat.add (fun x y (_third) => x + y)

/-- Dropping the third recursive position cannot be the payload-sum fold. -/
theorem omitting_child_not_hom :
    ¬ ∃ f : Hom (recursive signature)
        (observationAlgebra id Nat.add (fun x y z => x + y + z)),
      ∀ i (tree : Tree i), f.map tree = omitted tree :=
  fun ⟨f, agrees⟩ => (show (42 : Nat) ≠ 10 from of_decide_eq_true rfl)
    (total_values.symm.trans
      (((recursiveInitial signature).unique
        (observationAlgebra id Nat.add (fun x y z => x + y + z))
        ((recursiveInitial signature).fold
          (observationAlgebra id Nat.add (fun x y z => x + y + z))) f values).trans
        ((agrees 99 values).trans omitted_values)))

/-- A carrier collapse is rejected even when it keeps each result index. -/
theorem collapsing_payload_not_hom :
    ¬ ∃ f : Hom (recursive signature) (recursive signature),
      ∀ i (tree : Tree i), f.map tree = leaf i 0 :=
  fun ⟨f, agrees⟩ => leaf_payload_ne 99 (Nat.succ_ne_zero 41)
    (((recursiveInitial signature).unique (recursive signature)
      (Hom.id (recursive signature)) f (leaf 99 42)).trans
      (agrees 99 (leaf 99 42)))

#print axioms total_values
#print axioms weighted_values
#print axioms independent_child_depths
#print axioms copied_positions
#print axioms count_roll
#print axioms count_copied
#print axioms swapped_children_ne
#print axioms omitting_child_not_hom
#print axioms collapsing_payload_not_hom

end

end KanonMeta.FinitaryConstruction.Tests
