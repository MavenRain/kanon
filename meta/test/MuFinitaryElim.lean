/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElim

namespace KanonMeta.MuFinitary.Tests.Elim

/-- Four ordered recursive positions distinguish every child contribution. -/
def spec : Spec := ⟨"Canopy", [⟨"tip", []⟩, ⟨"rise", ["child"]⟩,
  ⟨"spread", ["first", "second", "third", "fourth"]⟩]⟩

theorem valid_spec : spec.Valid := of_decide_eq_true rfl

def tip : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def rise (child : Value spec) : Value spec :=
  .node ⟨1, of_decide_eq_true rfl⟩ (fun (_position) => child)

def spread (first second third fourth : Value spec) : Value spec :=
  .node ⟨2, of_decide_eq_true rfl⟩
    (Fin.cases first (Fin.cases second (Fin.cases third (fun (_position) => fourth))))

def sample : Value spec := spread tip (rise tip) (rise (rise tip)) (rise (rise (rise tip)))

def swapped : Value spec := spread (rise (rise (rise tip))) (rise tip) (rise (rise tip)) tip

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor : Fin 3 => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 1)
    (Fin.cases (fun children => 1 + children (0 : Fin 1))
      (Fin.cases (fun children => 2 * children (0 : Fin 4) +
        3 * children (1 : Fin 4) + 5 * children (2 : Fin 4) + 7 * children (3 : Fin 4))
        (fun index => Fin.elim0 index)))

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight

theorem sample_observation : observe sample.interpret = 51 :=
  fold_interpret Nat weight sample

theorem swapped_observation : observe swapped.interpret = 36 :=
  fold_interpret Nat weight swapped

/-- The fibre retains data and a proof relating it to the semantic input. -/
def Counted (value : Carrier spec) : Type := {n : Nat // n = observe value}

def countStep (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (position : Fin (spec.arity ctor)) → Counted (children position)) :
    Counted (semanticNode spec ctor children) :=
  ⟨weight ctor (fun position => (ih position).val),
    (congrArg (weight ctor) (funext (fun position => (ih position).property))).trans
      (semanticFold_node spec Nat weight ctor children).symm⟩

noncomputable def count (value : Carrier spec) : Counted value :=
  semanticElim spec Counted countStep value

theorem count_node (ctor : spec.Constructor)
    (children : Fin (spec.arity ctor) → Carrier spec) :
    count (semanticNode spec ctor children) =
      countStep ctor children (fun position => count (children position)) :=
  semanticElim_node spec Counted countStep ctor children

theorem structural_sample : (sample.inductInterpret Counted countStep).val = 51 := rfl

theorem structural_swapped : (swapped.inductInterpret Counted countStep).val = 36 := rfl

theorem sample_count : (count sample.interpret).val = 51 :=
  (congrArg Subtype.val (Value.semanticElim_interpret Counted countStep sample)).trans
    structural_sample

theorem swapped_count : (count swapped.interpret).val = 36 :=
  (congrArg Subtype.val (Value.semanticElim_interpret Counted countStep swapped)).trans
    structural_swapped

/-- The dependent computation detects a permutation of the first and last child. -/
theorem positions_remain_distinct : sample.interpret ≠ swapped.interpret :=
  fun equal => (show (51 : Nat) ≠ 36 from of_decide_eq_true rfl)
    (sample_count.symm.trans
      ((congrArg (fun value => (count value).val) equal).trans swapped_count))

/-- A zero result cannot supply a witness in the sample's dependent fibre. -/
theorem zero_is_not_a_witness : ¬ ∃ witness : Counted sample.interpret, witness.val = 0 :=
  fun ⟨witness, zero⟩ => (show (51 : Nat) ≠ 0 from of_decide_eq_true rfl)
    (sample_observation.symm.trans (witness.property.symm.trans zero))

noncomputable def observed (value : Carrier spec) : Counted value := ⟨observe value, rfl⟩

theorem observed_node (ctor : spec.Constructor)
    (children : Fin (spec.arity ctor) → Carrier spec) :
    observed (semanticNode spec ctor children) =
      countStep ctor children (fun position => observed (children position)) :=
  Subtype.ext (semanticFold_node spec Nat weight ctor children)

/-- An independently defined section agrees by the public uniqueness law. -/
theorem independent_section (value : Carrier spec) : observed value = count value :=
  semanticElim_unique spec Counted countStep observed observed_node value

def openSample : OpenTerm spec 2 :=
  .node ⟨2, of_decide_eq_true rfl⟩
    (Fin.cases (.var 0) (Fin.cases (.var 1) (Fin.cases (.var 0) (fun (_position) => .var 1))))

noncomputable def environment : Fin 2 → Carrier spec :=
  Fin.cases tip.interpret (fun (_index) => (rise tip).interpret)

/-- Variable witnesses are supplied independently of the semantic eliminator. -/
def variableWitnesses : (index : Fin 2) → Counted (environment index) :=
  Fin.cases ⟨1, (fold_interpret Nat weight tip).symm⟩
    (fun index => Fin.cases ⟨2, (fold_interpret Nat weight (rise tip)).symm⟩
      (fun impossible => Fin.elim0 impossible) index)

theorem open_structural_observation :
    (openSample.inductInterpret Counted countStep environment variableWitnesses).val = 27 := rfl

theorem variable_witness_retained (index : Fin 2) :
    (OpenTerm.var index).inductInterpret Counted countStep environment variableWitnesses =
      variableWitnesses index := rfl

theorem open_semantic_agreement (env : Fin 2 → Carrier spec) :
    count (openSample.interpret env) =
      openSample.inductInterpret Counted countStep env (fun i => count (env i)) :=
  OpenTerm.semanticElim_interpret Counted countStep env openSample

theorem open_count : (count (openSample.interpret environment)).val = 27 :=
  (count (openSample.interpret environment)).property.trans
    ((openSample.inductInterpret Counted countStep environment variableWitnesses).property.symm.trans
      open_structural_observation)

theorem constructed_carrier_roundtrip (value : Carrier spec) :
    (reify spec value).interpret = value := interpret_reify value

theorem syntax_roundtrip (value : Value spec) : reify spec value.interpret = value :=
  reify_interpret value

/-- Reified constructor syntax separates the permuted samples. -/
theorem reified_samples_differ :
    reify spec sample.interpret ≠ reify spec swapped.interpret :=
  fun equal => positions_remain_distinct (reify_injective equal)

def emptySpec : Spec := ⟨"Void", []⟩

noncomputable def emptyElim (value : Carrier emptySpec) : Empty :=
  semanticElim emptySpec (fun (_value) => Empty) (fun ctor => Fin.elim0 ctor) value

theorem empty_carrier : ¬ Nonempty (Carrier emptySpec) :=
  fun ⟨value⟩ => Empty.elim (emptyElim value)

#print axioms sample_count
#print axioms swapped_count
#print axioms positions_remain_distinct
#print axioms zero_is_not_a_witness
#print axioms independent_section
#print axioms open_count
#print axioms open_semantic_agreement
#print axioms constructed_carrier_roundtrip
#print axioms empty_carrier

end KanonMeta.MuFinitary.Tests.Elim
