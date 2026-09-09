import KanonMeta

namespace KanonCoherenceClient

open KanonMeta.MuFinitary

def spec : Spec := ⟨"CoherenceFork", [⟨"leaf", []⟩, ⟨"branch", ["left", "right"]⟩]⟩

def leaf : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def branch {n : Nat} (left right : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨1, of_decide_eq_true rfl⟩ (Fin.cases left (fun (_i) => right))

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor : Fin 2 => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 2)
    (Fin.cases (fun children => 3 * children (0 : Fin 2) + 5 * children (1 : Fin 2))
      (fun index => Fin.elim0 index))

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight

def Certified (value : Carrier spec) : Type := {n : Nat // n = observe value}

def Witness (value : Carrier spec) : Type := Certified value × Nat

def step (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Witness (children i)) :
    Witness (semanticNode spec ctor children) :=
  (⟨weight ctor (fun i => (ih i).1.val),
    (congrArg (weight ctor) (funext (fun i => (ih i).1.property))).trans
      (semanticFold_node spec Nat weight ctor children).symm⟩,
    weight ctor (fun i => (ih i).2))

def atLeaf (annotation : Nat) : Witness leaf.interpret :=
  (⟨2, (fold_interpret Nat weight leaf).symm⟩, annotation)

noncomputable def environment : Fin 2 → Carrier spec := fun (_i) => leaf.interpret

def witnesses : (i : Fin 2) → Witness (environment i) :=
  Fin.cases (atLeaf 7) (fun (_i) => atLeaf 11)

def alternateWitnesses : (i : Fin 2) → Witness (environment i) :=
  Fin.cases (atLeaf 7) (fun (_i) => atLeaf 13)

def pattern : OpenTerm spec 2 := branch (.var 0) (branch (.var 1) (.var 0))

def reversed : OpenTerm spec 2 := branch (.var 1) (branch (.var 0) (.var 1))

def replacement : Fin 2 → OpenTerm spec 1 :=
  Fin.cases (.var 0) (fun (_i) => branch (.var 0) (.var 0))

def nestedReplacement : Fin 1 → OpenTerm spec 2 :=
  fun (_i) => branch (.var 1) (.var 0)

def collapse : Fin 2 → Fin 1 := fun (_i) => 0

def embedSecond : Fin 1 → Fin 2 := fun (_i) => 1

def closedPattern : OpenTerm spec 0 :=
  branch (OpenTerm.ofValue leaf) (OpenTerm.ofValue leaf)

def emptyWitnesses : (i : Fin 0) → Witness (Fin.elim0 i) := fun i => Fin.elim0 i

end KanonCoherenceClient
