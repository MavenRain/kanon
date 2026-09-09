/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElimFusion
import test.MuFinitaryElimSubst

namespace KanonMeta.MuFinitary.Tests.ElimFusion

open Elim (spec sample swapped weight Counted countStep)
open ElimSubst (Witness step pattern reversed environment witnesses alternateWitnesses
  replacement targetEnvironment targetWitnesses collapse closedSample emptyWitnesses)

/-- Reorder the dependent certificate and its freely supplied annotation. -/
def Target (value : Carrier spec) : Type := Nat × Counted value

def targetStep (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (ih : (i : Fin (spec.arity ctor)) → Target (children i)) :
    Target (semanticNode spec ctor children) :=
  (weight ctor (fun i => (ih i).1), countStep ctor children (fun i => (ih i).2))

noncomputable def swapHom :
    Initiality.DisplayedHom (displayed spec Witness step) (displayed spec Target targetStep) :=
  displayedHom (fun _value witness => (witness.2, witness.1)) (fun _ctor _xs _ih => rfl)

noncomputable def forgetHom :
    Initiality.DisplayedHom (displayed spec Target targetStep)
      (displayed spec (fun _value => Nat) (fun ctor _xs ih => weight ctor ih)) :=
  displayedHom (fun _value witness => witness.1) (fun _ctor _xs _ih => rfl)

theorem constructed_fusion (value : Carrier spec) :
    (semanticElim spec Witness step value).2 =
      (semanticElim spec Target targetStep value).1 :=
  congrArg Prod.fst (semanticElim_fusion swapHom value)

theorem closed_fusion_observation :
    (sample.inductInterpret Target targetStep).1 = 51 :=
  (congrArg Prod.fst (Value.inductInterpret_fusion swapHom sample)).symm

theorem closed_order_observation :
    (swapped.inductInterpret Target targetStep).1 = 36 :=
  (congrArg Prod.fst (Value.inductInterpret_fusion swapHom swapped)).symm

theorem supplied_annotation_retained :
    (pattern.inductInterpret Target targetStep environment
      (fun i => swapHom.map (environment i) (witnesses i))).1 = 159 :=
  (congrArg Prod.fst
    (OpenTerm.inductInterpret_fusion swapHom environment witnesses pattern)).symm

theorem alternate_annotation_retained :
    (pattern.inductInterpret Target targetStep environment
      (fun i => swapHom.map (environment i) (alternateWitnesses i))).1 = 179 :=
  (congrArg Prod.fst
    (OpenTerm.inductInterpret_fusion swapHom environment alternateWitnesses pattern)).symm

theorem supplied_certificate_retained :
    (pattern.inductInterpret Target targetStep environment
      (fun i => swapHom.map (environment i) (witnesses i))).2.val = 17 :=
  (congrArg (fun witness => witness.2.val)
    (OpenTerm.inductInterpret_fusion swapHom environment witnesses pattern)).symm

theorem ordered_annotation_retained :
    (reversed.inductInterpret Target targetStep environment
      (fun i => swapHom.map (environment i) (witnesses i))).1 = 147 :=
  (congrArg Prod.fst
    (OpenTerm.inductInterpret_fusion swapHom environment witnesses reversed)).symm

theorem composed_fusion_observation :
    pattern.inductInterpret (fun _value => Nat) (fun ctor _xs ih => weight ctor ih) environment
      (fun i => (forgetHom.comp swapHom).map (environment i) (witnesses i)) = 159 :=
  (OpenTerm.inductInterpret_fusion (forgetHom.comp swapHom) environment witnesses pattern).symm

theorem transported_substitution_observation :
    (swapHom.map (pattern.interpret (fun i => (replacement i).interpret targetEnvironment))
      (Eq.mp (congrArg Witness
        (OpenTerm.interpret_substitute replacement targetEnvironment pattern))
        ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
          targetWitnesses))).1 = 78 :=
  congrArg Prod.fst (OpenTerm.inductInterpret_substitute_fusion swapHom replacement
    targetEnvironment targetWitnesses pattern)

theorem transported_renaming_observation :
    (swapHom.map (pattern.interpret (fun i => targetEnvironment (collapse i)))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse targetEnvironment pattern))
        ((pattern.rename collapse).inductInterpret Witness step targetEnvironment
          targetWitnesses))).1 = 68 :=
  congrArg Prod.fst (OpenTerm.inductInterpret_rename_fusion swapHom collapse
    targetEnvironment targetWitnesses pattern)

theorem transported_substitution_certificate :
    (swapHom.map (pattern.interpret (fun i => (replacement i).interpret targetEnvironment))
      (Eq.mp (congrArg Witness
        (OpenTerm.interpret_substitute replacement targetEnvironment pattern))
        ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
          targetWitnesses))).2.val = 27 :=
  congrArg (fun witness => witness.2.val)
    (OpenTerm.inductInterpret_substitute_fusion swapHom replacement
      targetEnvironment targetWitnesses pattern)

theorem transported_renaming_certificate :
    (swapHom.map (pattern.interpret (fun i => targetEnvironment (collapse i)))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse targetEnvironment pattern))
        ((pattern.rename collapse).inductInterpret Witness step targetEnvironment
          targetWitnesses))).2.val = 17 :=
  congrArg (fun witness => witness.2.val)
    (OpenTerm.inductInterpret_rename_fusion swapHom collapse
      targetEnvironment targetWitnesses pattern)

theorem empty_context_fusion_observation :
    (closedSample.inductInterpret Target targetStep Fin.elim0
      (fun i => swapHom.map (Fin.elim0 i) (emptyWitnesses i))).1 = 51 :=
  (congrArg Prod.fst
    (OpenTerm.inductInterpret_fusion swapHom Fin.elim0 emptyWitnesses closedSample)).symm

/-- Resetting arbitrary annotations fails to preserve the nullary constructor. -/
theorem resetting_annotation_is_not_lawful :
    ¬ (∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
      (ih : (i : Fin (spec.arity ctor)) → Witness (children i)),
      (0, (step ctor children ih).1) =
        targetStep ctor children (fun i => (0, (ih i).1))) :=
  fun lawful => (show (0 : Nat) ≠ 1 from of_decide_eq_true rfl)
    (congrArg Prod.fst (lawful ⟨0, of_decide_eq_true rfl⟩ Fin.elim0 (fun i => Fin.elim0 i)))

#print axioms constructed_fusion
#print axioms supplied_annotation_retained
#print axioms supplied_certificate_retained
#print axioms transported_substitution_observation
#print axioms transported_renaming_observation
#print axioms transported_substitution_certificate
#print axioms transported_renaming_certificate
#print axioms resetting_annotation_is_not_lawful

end KanonMeta.MuFinitary.Tests.ElimFusion
