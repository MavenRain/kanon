/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta

namespace FusionClient

open KanonMeta KanonMeta.MuFinitary

def spec : Spec := ⟨"Fork", [⟨"leaf", []⟩, ⟨"fork", ["left", "right"]⟩]⟩
theorem valid_spec : spec.Valid := of_decide_eq_true rfl
def leaf : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def fork {n : Nat} (left right : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨1, of_decide_eq_true rfl⟩ (Fin.cases left (fun (_i) => right))

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 2)
    (Fin.cases (fun children => 3 * children (0 : Fin 2) + 5 * children (1 : Fin 2))
      (fun impossible => Fin.elim0 impossible))

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight
def Certificate (value : Carrier spec) : Type := {n : Nat // n = observe value}

def certify (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Certificate (children i)) :
    Certificate (semanticNode spec ctor children) :=
  ⟨weight ctor (fun i => (ih i).val),
    (congrArg (weight ctor) (funext (fun i => (ih i).property))).trans
      (semanticFold_node spec Nat weight ctor children).symm⟩

def Source (value : Carrier spec) : Type := Certificate value × Nat
def Target (value : Carrier spec) : Type := Certificate value × (Nat × Nat)

def sourceStep (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Source (children i)) :
    Source (semanticNode spec ctor children) :=
  (certify ctor children (fun i => (ih i).1), weight ctor (fun i => (ih i).2))

def targetStep (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Target (children i)) :
    Target (semanticNode spec ctor children) :=
  (certify ctor children (fun i => (ih i).1),
    (weight ctor (fun i => (ih i).2.1), weight ctor (fun i => (ih i).2.2)))

noncomputable def duplicate : Initiality.DisplayedHom
    (displayed spec Source sourceStep) (displayed spec Target targetStep) :=
  displayedHom (fun _value witness => (witness.1, (witness.2, witness.2)))
    (fun _ctor _children (_witnesses) => rfl)

theorem constructed_fusion (value : Carrier spec) :
    duplicate.map value (semanticElim spec Source sourceStep value) =
      semanticElim spec Target targetStep value := semanticElim_fusion duplicate value

def pattern : OpenTerm spec 2 := fork (.var 0) (.var 1)
noncomputable def env : Fin 2 → Carrier spec := fun (_i) => leaf.interpret
def annotation (n : Nat) : Source leaf.interpret :=
  (⟨2, (fold_interpret Nat weight leaf).symm⟩, n)
def witnesses : (i : Fin 2) → Source (env i) :=
  Fin.cases (annotation 4) (fun (_i) => annotation 9)
def alternate : (i : Fin 2) → Source (env i) :=
  Fin.cases (annotation 6) (fun (_i) => annotation 9)

theorem duplicate_annotations :
    (pattern.inductInterpret Target targetStep env
      (fun i => duplicate.map (env i) (witnesses i))).2 = (57, 57) :=
  (congrArg Prod.snd (OpenTerm.inductInterpret_fusion duplicate env witnesses pattern)).symm

theorem duplicate_alternate :
    (pattern.inductInterpret Target targetStep env
      (fun i => duplicate.map (env i) (alternate i))).2 = (63, 63) :=
  (congrArg Prod.snd (OpenTerm.inductInterpret_fusion duplicate env alternate pattern)).symm

theorem dependent_certificate :
    (pattern.inductInterpret Target targetStep env
      (fun i => duplicate.map (env i) (witnesses i))).1.val = 16 :=
  (congrArg (fun witness => witness.1.val)
    (OpenTerm.inductInterpret_fusion duplicate env witnesses pattern)).symm

def replace : Fin 2 → OpenTerm spec 1 :=
  Fin.cases (.var 0) (fun (_i) => fork (.var 0) (.var 0))
noncomputable def targetEnv : Fin 1 → Carrier spec := fun (_i) => leaf.interpret
def targetWitnesses : (i : Fin 1) → Source (targetEnv i) := fun (_i) => annotation 4

theorem substitution_observation :
    (duplicate.map (pattern.interpret (fun i => (replace i).interpret targetEnv))
      (Eq.mp (congrArg Source (OpenTerm.interpret_substitute replace targetEnv pattern))
        ((pattern.substitute replace).inductInterpret Source sourceStep targetEnv
          targetWitnesses))).2 = (172, 172) :=
  congrArg Prod.snd (OpenTerm.inductInterpret_substitute_fusion duplicate replace targetEnv
    targetWitnesses pattern)

theorem renaming_observation :
    (duplicate.map (pattern.interpret (fun (_i) => targetEnv 0))
      (Eq.mp (congrArg Source (OpenTerm.interpret_rename (fun (_i) => 0) targetEnv pattern))
        ((pattern.rename (fun (_i) => 0)).inductInterpret Source sourceStep targetEnv
          targetWitnesses))).2 = (32, 32) :=
  congrArg Prod.snd (OpenTerm.inductInterpret_rename_fusion duplicate (fun (_i) => 0) targetEnv
    targetWitnesses pattern)

theorem substitution_certificate :
    (duplicate.map (pattern.interpret (fun i => (replace i).interpret targetEnv))
      (Eq.mp (congrArg Source (OpenTerm.interpret_substitute replace targetEnv pattern))
        ((pattern.substitute replace).inductInterpret Source sourceStep targetEnv
          targetWitnesses))).1.val = 86 :=
  congrArg (fun witness => witness.1.val)
    (OpenTerm.inductInterpret_substitute_fusion duplicate replace targetEnv targetWitnesses pattern)

#print axioms constructed_fusion
#print axioms duplicate_annotations
#print axioms dependent_certificate
#print axioms substitution_observation
#print axioms renaming_observation
#print axioms substitution_certificate

end FusionClient
