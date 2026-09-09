/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElimBaseChange
import test.MuFinitaryElimSubst

namespace KanonMeta.MuFinitary.Tests.ElimBaseChange

open Elim (spec sample swapped weight)
open ElimSubst (Witness step pattern reversed environment witnesses alternateWitnesses
  replacement targetEnvironment targetWitnesses collapse)

def target : Initiality.Algebra spec.signature.polynomial := algebra spec Nat weight

noncomputable def baseMap : Initiality.Hom (recursive spec) target :=
  (recursiveInitial spec).fold target

def Target (value : Nat) : Type := {n : Nat // n = value} × Nat

def targetDisplay : Initiality.Displayed target where
  Fibre := fun value => Target value
  step := fun ctor (_xs) ih =>
    (⟨weight ctor (fun i => (ih ⟨i⟩).1.val),
      congrArg (weight ctor) (funext (fun i => (ih ⟨i⟩).1.property))⟩,
      weight ctor (fun i => (ih ⟨i⟩).2))

theorem transport_payload {x y : Nat} (equal : x = y) (witness : Target x) :
    ((Eq.mp (congrArg Target equal) witness).1.val,
      (Eq.mp (congrArg Target equal) witness).2) = (witness.1.val, witness.2) :=
  @Eq.rec Nat x (fun (_y) equal =>
    ((Eq.mp (congrArg Target equal) witness).1.val,
      (Eq.mp (congrArg Target equal) witness).2) = (witness.1.val, witness.2)) rfl y equal

/-- The base becomes its numeric fold, while dependent and free data survive. -/
noncomputable def changeBase :
    Initiality.DisplayedHomOver baseMap (displayed spec Witness step) targetDisplay where
  map := fun (_value) witness => (⟨witness.1.val, witness.1.property⟩, witness.2)
  comm := fun ctor xs ih =>
    let stable := transport_payload (baseMap.comm ctor xs).symm
      (targetDisplay.step ctor (fun pos => baseMap.map (xs pos))
        (fun pos => (⟨(ih pos).1.val, (ih pos).1.property⟩, (ih pos).2)))
    Prod.ext (Subtype.ext (congrArg Prod.fst stable).symm) (congrArg Prod.snd stable).symm

def targetSection (n : Nat) : Target n := (⟨n, rfl⟩, n)

theorem targetSection_comm {i : Unit}
    (ctor : spec.signature.polynomial.Shape i) (xs) :
    targetSection (target.roll ctor xs) =
      targetDisplay.step ctor xs (fun pos => targetSection (xs pos)) := rfl

/-- Constructed elimination reaches a lawful section of a noninitial target. -/
theorem semantic_section :
    (semanticElim spec (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay) sample.interpret).2 = 51 :=
  (congrArg Prod.snd (semanticElim_pullback_section baseMap targetDisplay
    targetSection targetSection_comm sample.interpret)).trans
      (fold_interpret Nat weight sample)

/-- The identity base map is a map between initial algebras, so the target eliminator
route of `semanticElim_pullback` applies with the constructed algebra as its target. -/
theorem identity_target_eliminator (value : Carrier spec) :
    semanticElim spec
      (pullbackFibre (Initiality.Hom.id (recursive spec)) (displayed spec Witness step))
      (pullbackStep (Initiality.Hom.id (recursive spec)) (displayed spec Witness step)) value =
      semanticElim spec Witness step value :=
  semanticElim_pullback (recursiveInitial spec) (Initiality.Hom.id (recursive spec))
    (displayed spec Witness step) value

theorem identity_target_annotation :
    (semanticElim spec
      (pullbackFibre (Initiality.Hom.id (recursive spec)) (displayed spec Witness step))
      (pullbackStep (Initiality.Hom.id (recursive spec)) (displayed spec Witness step))
      sample.interpret).2 = 51 :=
  congrArg Prod.snd ((identity_target_eliminator sample.interpret).trans
    (Value.semanticElim_interpret Witness step sample))

theorem closed_annotation :
    (sample.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay)).2 = 51 :=
  (congrArg Prod.snd (Value.inductInterpret_fusion_over changeBase sample)).symm

theorem closed_order :
    (swapped.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay)).2 = 36 :=
  (congrArg Prod.snd (Value.inductInterpret_fusion_over changeBase swapped)).symm

theorem open_annotation :
    (pattern.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay) environment
      (fun i => changeBase.map (environment i) (witnesses i))).2 = 159 :=
  (congrArg Prod.snd
    (OpenTerm.inductInterpret_fusion_over changeBase environment witnesses pattern)).symm

theorem alternate_annotation :
    (pattern.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay) environment
      (fun i => changeBase.map (environment i) (alternateWitnesses i))).2 = 179 :=
  (congrArg Prod.snd
    (OpenTerm.inductInterpret_fusion_over changeBase environment alternateWitnesses pattern)).symm

theorem open_certificate :
    (pattern.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay) environment
      (fun i => changeBase.map (environment i) (witnesses i))).1.val = 17 :=
  (congrArg (fun witness => witness.1.val)
    (OpenTerm.inductInterpret_fusion_over changeBase environment witnesses pattern)).symm

theorem substitution_annotation :
    (changeBase.map (pattern.interpret (fun i => (replacement i).interpret targetEnvironment))
      (Eq.mp (congrArg Witness
        (OpenTerm.interpret_substitute replacement targetEnvironment pattern))
        ((pattern.substitute replacement).inductInterpret Witness step targetEnvironment
          targetWitnesses))).2 = 78 :=
  ElimSubst.transported_substitution_observation

theorem substitution_route :
    (pattern.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay)
      (fun i => (replacement i).interpret targetEnvironment)
      (fun i => (replacement i).inductInterpret (pullbackFibre baseMap targetDisplay)
        (pullbackStep baseMap targetDisplay) targetEnvironment
        (fun j => changeBase.map (targetEnvironment j) (targetWitnesses j)))).2 = 78 :=
  (congrArg Prod.snd (OpenTerm.inductInterpret_substitute_fusion_over changeBase
    replacement targetEnvironment targetWitnesses pattern)).symm.trans substitution_annotation

theorem renaming_route :
    (pattern.inductInterpret (pullbackFibre baseMap targetDisplay)
      (pullbackStep baseMap targetDisplay) (fun i => targetEnvironment (collapse i))
      (fun i => changeBase.map (targetEnvironment (collapse i)) (targetWitnesses (collapse i)))).2 = 68 :=
  (congrArg Prod.snd (OpenTerm.inductInterpret_rename_fusion_over changeBase
    collapse targetEnvironment targetWitnesses pattern)).symm.trans
      ElimSubst.transported_renaming_observation

#print axioms open_annotation
#print axioms substitution_route
#print axioms renaming_route

end KanonMeta.MuFinitary.Tests.ElimBaseChange
