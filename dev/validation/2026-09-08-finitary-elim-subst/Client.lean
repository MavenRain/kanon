import KanonMeta

namespace Client

open KanonMeta.MuFinitary

def spec : Spec := ⟨"Trident", [⟨"point", []⟩, ⟨"join", ["left", "middle", "right"]⟩]⟩

def point : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def join {n : Nat} (left middle right : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨1, of_decide_eq_true rfl⟩
    (Fin.cases left (Fin.cases middle (fun (_i) => right)))

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 2)
    (Fin.cases (fun children => children (0 : Fin 3) + 10 * children (1 : Fin 3) +
      100 * children (2 : Fin 3)) (fun index => Fin.elim0 index))

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight

/-- The proof constrains the measurement while annotations remain arbitrary. -/
def Witness (value : Carrier spec) : Type := {n : Nat // n = observe value} × Nat

def step (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Witness (children i)) :
    Witness (semanticNode spec ctor children) :=
  (⟨weight ctor (fun i => (ih i).1.val),
    (congrArg (weight ctor) (funext (fun i => (ih i).1.property))).trans
      (semanticFold_node spec Nat weight ctor children).symm⟩,
    weight ctor (fun i => (ih i).2))

def atPoint (annotation : Nat) : Witness point.interpret :=
  (⟨2, (fold_interpret Nat weight point).symm⟩, annotation)

def pattern : OpenTerm spec 2 := join (.var 0) (.var 1) (.var 0)

def replacement : Fin 2 → OpenTerm spec 1 :=
  Fin.cases (.var 0) (fun (_i) => join (.var 0) (.var 0) (.var 0))

noncomputable def environment : Fin 1 → Carrier spec := fun (_i) => point.interpret

def witnesses : (i : Fin 1) → Witness (environment i) := fun (_i) => atPoint 4

def alternateWitnesses : (i : Fin 1) → Witness (environment i) := fun (_i) => atPoint 5

theorem independent_measurement :
    ((pattern.substitute replacement).inductInterpret Witness step environment witnesses).1.val =
      2422 := rfl

theorem substitution_naturality :
    Eq.mp (congrArg Witness (OpenTerm.interpret_substitute replacement environment pattern))
      ((pattern.substitute replacement).inductInterpret Witness step environment witnesses) =
      pattern.inductInterpret Witness step (fun i => (replacement i).interpret environment)
        (fun i => (replacement i).inductInterpret Witness step environment witnesses) :=
  OpenTerm.inductInterpret_substitute Witness step replacement environment witnesses pattern

theorem transported_annotation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute replacement environment pattern))
      ((pattern.substitute replacement).inductInterpret Witness step environment witnesses)).2 =
      4844 :=
  congrArg Prod.snd substitution_naturality

theorem supplied_annotations_matter :
    (pattern.substitute replacement).inductInterpret Witness step environment witnesses ≠
      (pattern.substitute replacement).inductInterpret Witness step environment alternateWitnesses :=
  fun equal => (show (4844 : Nat) ≠ 6055 from of_decide_eq_true rfl)
    (congrArg Prod.snd equal)

def collapse : Fin 2 → Fin 1 := fun (_i) => 0

theorem renaming_naturality :
    Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse environment pattern))
      ((pattern.rename collapse).inductInterpret Witness step environment witnesses) =
      pattern.inductInterpret Witness step (fun i => environment (collapse i))
        (fun i => witnesses (collapse i)) :=
  OpenTerm.inductInterpret_rename Witness step collapse environment witnesses pattern

theorem renamed_annotation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse environment pattern))
      ((pattern.rename collapse).inductInterpret Witness step environment witnesses)).2 = 444 :=
  congrArg Prod.snd renaming_naturality

#print axioms substitution_naturality
#print axioms transported_annotation
#print axioms supplied_annotations_matter
#print axioms renaming_naturality
#print axioms renamed_annotation

end Client
