/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElimSubst
import test.MuFinitaryElim

namespace KanonMeta.MuFinitary.Tests.ElimSubst

open Elim (spec tip rise sample weight Counted countStep)

/-- The first component depends on the semantic input; the second remains free. -/
def Witness (value : Carrier spec) : Type := Counted value × Nat

def step (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Witness (children i)) :
    Witness (semanticNode spec ctor children) :=
  (countStep ctor children (fun i => (ih i).1), weight ctor (fun i => (ih i).2))

def spread {n : Nat} (first second third fourth : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨2, of_decide_eq_true rfl⟩
    (Fin.cases first (Fin.cases second (Fin.cases third (fun (_i) => fourth))))

def riseOpen {n : Nat} (child : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨1, of_decide_eq_true rfl⟩ (fun (_i) => child)

/-- Both variables occur twice, at distinct ordered positions. -/
def pattern : OpenTerm spec 2 := spread (.var 0) (.var 1) (.var 0) (.var 1)

def reversed : OpenTerm spec 2 := spread (.var 1) (.var 0) (.var 1) (.var 0)

/-- Equal semantic values do not force the supplied witnesses to agree. -/
noncomputable def environment : Fin 2 → Carrier spec := fun (_i) => tip.interpret

def atTip (annotation : Nat) : Witness tip.interpret :=
  (⟨1, (fold_interpret Nat weight tip).symm⟩, annotation)

def witnesses : (i : Fin 2) → Witness (environment i) :=
  Fin.cases (atTip 7) (fun (_i) => atTip 11)

def alternateWitnesses : (i : Fin 2) → Witness (environment i) :=
  Fin.cases (atTip 7) (fun (_i) => atTip 13)

theorem same_semantic_input : environment 0 = environment 1 := rfl

theorem distinct_witnesses : witnesses 0 ≠ witnesses 1 :=
  fun equal => (show (7 : Nat) ≠ 11 from of_decide_eq_true rfl) (congrArg Prod.snd equal)

theorem dependent_component :
    (pattern.inductInterpret Witness step environment witnesses).1.val = 17 := rfl

theorem supplied_data_observation :
    (pattern.inductInterpret Witness step environment witnesses).2 = 159 := rfl

theorem alternate_data_observation :
    (pattern.inductInterpret Witness step environment alternateWitnesses).2 = 179 := rfl

/-- A section chosen from the semantic input alone cannot pass this control. -/
theorem changing_supplied_witness_changes_result :
    pattern.inductInterpret Witness step environment witnesses ≠
      pattern.inductInterpret Witness step environment alternateWitnesses :=
  fun equal => (show (159 : Nat) ≠ 179 from of_decide_eq_true rfl)
    (congrArg Prod.snd equal)

theorem ordered_positions_observation :
    (reversed.inductInterpret Witness step environment witnesses).2 = 147 := rfl

noncomputable def targetEnvironment : Fin 1 → Carrier spec := fun (_i) => tip.interpret

def targetWitnesses : (i : Fin 1) → Witness (targetEnvironment i) := fun (_i) => atTip 4

def replacement : Fin 2 → OpenTerm spec 1 :=
  Fin.cases (.var 0) (fun (_i) => riseOpen (.var 0))

theorem substitution_naturality :
    Eq.mp (congrArg Witness (OpenTerm.interpret_substitute replacement targetEnvironment pattern))
      ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
        targetWitnesses) =
      pattern.inductInterpret Witness step (fun i => (replacement i).interpret targetEnvironment)
        (fun i => (replacement i).inductInterpret Witness step targetEnvironment targetWitnesses) :=
  OpenTerm.inductInterpret_substitute Witness step replacement targetEnvironment targetWitnesses
    pattern

/-- Observe data after the actual equality transport, not only before it. -/
theorem transported_substitution_observation :
    (Eq.mp (congrArg Witness
      (OpenTerm.interpret_substitute replacement targetEnvironment pattern))
      ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
        targetWitnesses)).2 = 78 :=
  congrArg Prod.snd substitution_naturality

theorem substituted_dependent_component :
    ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
      targetWitnesses).1.val = 27 := rfl

def collapse : Fin 2 → Fin 1 := fun (_i) => 0

theorem renaming_is_noninjective : collapse 0 = collapse 1 := rfl

theorem renaming_naturality :
    Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse targetEnvironment pattern))
      ((pattern.rename collapse).inductInterpret Witness step targetEnvironment targetWitnesses) =
      pattern.inductInterpret Witness step (fun i => targetEnvironment (collapse i))
        (fun i => targetWitnesses (collapse i)) :=
  OpenTerm.inductInterpret_rename Witness step collapse targetEnvironment targetWitnesses pattern

theorem transported_renaming_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse targetEnvironment pattern))
      ((pattern.rename collapse).inductInterpret Witness step targetEnvironment targetWitnesses)).2 =
      68 :=
  congrArg Prod.snd renaming_naturality

theorem identity_substitution_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute OpenTerm.var environment pattern))
      ((pattern.substitute OpenTerm.var).inductInterpret Witness step environment witnesses)).2 =
      159 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_id Witness step environment witnesses pattern)

theorem identity_renaming_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename (fun i => i) environment pattern))
      ((pattern.rename (fun i => i)).inductInterpret Witness step environment witnesses)).2 = 159 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_id Witness step environment witnesses pattern)

def nestedReplacement : Fin 1 → OpenTerm spec 2 :=
  fun (_i) => spread (.var 0) (.var 1) (.var 1) (.var 0)

def composedReplacement : Fin 2 → OpenTerm spec 2 :=
  fun i => (replacement i).substitute nestedReplacement

theorem nested_substitution_naturality :
    Eq.mp (congrArg Witness (OpenTerm.interpret_substitute nestedReplacement environment
      (pattern.substitute replacement)))
      (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret Witness
        step environment witnesses) =
      (pattern.substitute replacement).inductInterpret Witness step
        (fun i => (nestedReplacement i).interpret environment)
        (fun i => (nestedReplacement i).inductInterpret Witness step environment witnesses) :=
  OpenTerm.inductInterpret_substitute Witness step nestedReplacement environment witnesses
    (pattern.substitute replacement)

theorem nested_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute nestedReplacement environment
      (pattern.substitute replacement)))
      (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret Witness
        step environment witnesses)).2 = 2577 :=
  congrArg Prod.snd nested_substitution_naturality

theorem composed_transport_observation :
    (Eq.mp (congrArg Witness
      (OpenTerm.interpret_substitute composedReplacement environment pattern))
      ((pattern.substitute composedReplacement).inductInterpret Witness step environment
        witnesses)).2 = 2577 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute Witness step composedReplacement environment witnesses
      pattern)

theorem nested_and_composed_syntax_agree :
    (pattern.substitute replacement).substitute nestedReplacement =
      pattern.substitute composedReplacement :=
  OpenTerm.substitute_comp replacement nestedReplacement pattern

theorem substitution_composition_witness_observation :
    (Eq.mp (congrArg Witness (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
      (OpenTerm.substitute_comp replacement nestedReplacement pattern)))
      (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret Witness
        step environment witnesses)).2 = 2577 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_comp Witness step replacement nestedReplacement
      environment witnesses pattern)

def embedSecond : Fin 1 → Fin 2 := fun (_i) => 1

theorem renaming_composition_witness_observation :
    (Eq.mp (congrArg Witness (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
      (OpenTerm.rename_comp collapse embedSecond pattern)))
      (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step environment
        witnesses)).2 = 187 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_comp Witness step collapse embedSecond environment witnesses
      pattern)

def closedReplacement : Fin 2 → OpenTerm spec 0 :=
  Fin.cases (OpenTerm.ofValue tip) (fun (_i) => OpenTerm.ofValue (rise tip))

def emptyWitnesses : (i : Fin 0) → Witness (Fin.elim0 i) := fun i => Fin.elim0 i

theorem closed_substitution_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute closedReplacement Fin.elim0 pattern))
      ((pattern.substitute closedReplacement).inductInterpret Witness step Fin.elim0
        emptyWitnesses)).2 = 27 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute Witness step closedReplacement Fin.elim0 emptyWitnesses
      pattern)

def closedSample : OpenTerm spec 0 := OpenTerm.ofValue sample

theorem empty_context_substitution_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
      (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0 closedSample))
      ((closedSample.substitute Fin.elim0).inductInterpret Witness step Fin.elim0 emptyWitnesses)).2 =
      51 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute Witness step
      (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0 emptyWitnesses closedSample)

theorem empty_context_renaming_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename
      (Fin.elim0 : Fin 0 → Fin 0) Fin.elim0 closedSample))
      ((closedSample.rename Fin.elim0).inductInterpret Witness step Fin.elim0 emptyWitnesses)).2 = 51 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename Witness step
      (Fin.elim0 : Fin 0 → Fin 0) Fin.elim0 emptyWitnesses closedSample)

#print axioms changing_supplied_witness_changes_result
#print axioms substitution_naturality
#print axioms renaming_naturality
#print axioms nested_transport_observation
#print axioms composed_transport_observation
#print axioms identity_substitution_observation
#print axioms identity_renaming_observation
#print axioms substitution_composition_witness_observation
#print axioms renaming_composition_witness_observation
#print axioms closed_substitution_transport_observation
#print axioms empty_context_substitution_observation
#print axioms empty_context_renaming_observation

end KanonMeta.MuFinitary.Tests.ElimSubst
