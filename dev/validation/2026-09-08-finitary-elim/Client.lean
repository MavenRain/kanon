import KanonMeta

namespace Client

open KanonMeta.MuFinitary

def spec : Spec := ⟨"Ribbon", [⟨"end", []⟩, ⟨"attach", ["tail"]⟩]⟩

def finish : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def attach (tail : Value spec) : Value spec :=
  .node ⟨1, of_decide_eq_true rfl⟩ (fun (_position) => tail)

def sample : Value spec := attach (attach finish)

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 3)
    (Fin.cases (fun children => 5 + children (0 : Fin 1)) (fun index => Fin.elim0 index))

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight

def Witness (value : Carrier spec) : Type := {n : Nat // n = observe value}

def step (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Witness (children i)) :
    Witness (semanticNode spec ctor children) :=
  ⟨weight ctor (fun i => (ih i).val),
    (congrArg (weight ctor) (funext (fun i => (ih i).property))).trans
      (semanticFold_node spec Nat weight ctor children).symm⟩

noncomputable def count (value : Carrier spec) : Witness value :=
  semanticElim spec Witness step value

theorem constructor_beta (ctor : spec.Constructor)
    (children : Fin (spec.arity ctor) → Carrier spec) :
    count (semanticNode spec ctor children) = step ctor children (fun i => count (children i)) :=
  semanticElim_node spec Witness step ctor children

theorem dependent_result : (count sample.interpret).val = 13 :=
  congrArg Subtype.val (Value.semanticElim_interpret Witness step sample)

theorem result_evidence : (count sample.interpret).val = observe sample.interpret :=
  (count sample.interpret).property

theorem nonconstant : (count sample.interpret).val ≠ 0 :=
  fun equal => (show (13 : Nat) ≠ 0 from of_decide_eq_true rfl)
    (dependent_result.symm.trans equal)

theorem carrier_roundtrip (value : Carrier spec) : (reify spec value).interpret = value :=
  interpret_reify value

#print axioms dependent_result
#print axioms carrier_roundtrip

end Client
