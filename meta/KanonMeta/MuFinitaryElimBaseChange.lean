/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityBaseChange
import KanonMeta.MuFinitaryElimFusion

/-!
Dependent witnesses for the finite constructor fragment may live over the
image in another algebra. Pullback uses the actual base-map constructor law.
Fusion retains arbitrary variable witnesses, including during substitution
and renaming. The target need not be initial when a lawful section is supplied.
-/

namespace KanonMeta.MuFinitary

noncomputable section

variable {spec : Spec} {B : Initiality.Algebra spec.signature.polynomial}

/-- A target motive evaluated at the image of a constructed base value. -/
def pullbackFibre (f : Initiality.Hom (recursive spec) B) (E : Initiality.Displayed B)
    (value : Carrier spec) : Type := E.Fibre (f.map value)

/-- The target constructor operation transported back along the base map law. -/
def pullbackStep (f : Initiality.Hom (recursive spec) B) (E : Initiality.Displayed B)
    (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
    (witnesses : (i : Fin (spec.arity ctor)) → pullbackFibre f E (children i)) :
    pullbackFibre f E (semanticNode spec ctor children) :=
  (E.pullback f).step ctor (fun pos => children pos.down) (fun pos => witnesses pos.down)

/-- Connect the finite-family display wrapper to the indexed pullback. -/
def pullbackDisplayedHom (f : Initiality.Hom (recursive spec) B)
    (E : Initiality.Displayed B) :
    Initiality.DisplayedHom (displayed spec (pullbackFibre f E) (pullbackStep f E))
      (E.pullback f) where
  map := fun {i} => match i with | () => fun _value witness => witness
  comm := fun {i} => match i with | () => fun _ctor _xs _witnesses => rfl

/-- Any lawful target section agrees with constructed pullback elimination. -/
theorem semanticElim_pullback_section (f : Initiality.Hom (recursive spec) B)
    (E : Initiality.Displayed B)
    (choose : {i : Unit} → (x : B.Carrier i) → E.Fibre x)
    (comm : ∀ {i : Unit} (ctor : spec.signature.polynomial.Shape i) (xs),
      choose (B.roll ctor xs) = E.step ctor xs (fun pos => choose (xs pos)))
    (value : Carrier spec) :
    semanticElim spec (pullbackFibre f E) (pullbackStep f E) value = choose (f.map value) :=
  (Initiality.elim_fusion (recursiveInitial spec) (pullbackDisplayedHom f E) value).trans
    (Initiality.elim_pullback_section (recursiveInitial spec) f E choose comm value)

/-- Changing between initial base algebras commutes with constructed elimination. -/
theorem semanticElim_pullback (hB : Initiality.Initial B)
    (f : Initiality.Hom (recursive spec) B) (E : Initiality.Displayed B)
    (value : Carrier spec) :
    semanticElim spec (pullbackFibre f E) (pullbackStep f E) value =
      Initiality.elim hB E (f.map value) :=
  semanticElim_pullback_section f E (Initiality.elim hB E) (Initiality.elim_beta hB E) value

variable {F : Carrier spec → Type}
    {stepF : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children)}
    {f : Initiality.Hom (recursive spec) B} {E : Initiality.Displayed B}

/-- A map over another base induces the displayed map used by structural fusion. -/
def pullbackFusionHom (hom : Initiality.DisplayedHomOver f (displayed spec F stepF) E) :
    Initiality.DisplayedHom (displayed spec F stepF)
      (displayed spec (pullbackFibre f E) (pullbackStep f E)) :=
  displayedHom (fun value witness => hom.map value witness)
    (fun ctor children witnesses =>
      hom.comm ctor (fun pos => children pos.down) (fun pos => witnesses pos.down))

variable (hom : Initiality.DisplayedHomOver f (displayed spec F stepF) E)

/-- Closed structural induction preserves witnesses over the mapped base. -/
theorem Value.inductInterpret_fusion_over (value : Value spec) :
    hom.map value.interpret (value.inductInterpret F stepF) =
      value.inductInterpret (pullbackFibre f E) (pullbackStep f E) :=
  value.inductInterpret_fusion (pullbackFusionHom hom)

/-- Open fusion transforms the supplied witnesses, not only the semantic values. -/
theorem OpenTerm.inductInterpret_fusion_over {n : Nat}
    (env : Fin n → Carrier spec) (witnesses : (i : Fin n) → F (env i))
    (term : OpenTerm spec n) :
    hom.map (term.interpret env) (term.inductInterpret F stepF env witnesses) =
      term.inductInterpret (pullbackFibre f E) (pullbackStep f E) env
        (fun i => hom.map (env i) (witnesses i)) :=
  term.inductInterpret_fusion (pullbackFusionHom hom) env witnesses

/-- Substitution transports the witness before the change of base. -/
theorem OpenTerm.inductInterpret_substitute_fusion_over {n m : Nat}
    (sigma : Fin n → OpenTerm spec m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) (term : OpenTerm spec n) :
    hom.map (term.interpret (fun i => (sigma i).interpret env))
      (Eq.mp (congrArg F (interpret_substitute sigma env term))
        ((term.substitute sigma).inductInterpret F stepF env witnesses)) =
      term.inductInterpret (pullbackFibre f E) (pullbackStep f E)
        (fun i => (sigma i).interpret env)
        (fun i => (sigma i).inductInterpret (pullbackFibre f E) (pullbackStep f E) env
          (fun j => hom.map (env j) (witnesses j))) :=
  term.inductInterpret_substitute_fusion (pullbackFusionHom hom) sigma env witnesses

/-- Noninjective renaming retains every selected transformed witness. -/
theorem OpenTerm.inductInterpret_rename_fusion_over {n m : Nat}
    (rho : Fin n → Fin m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) (term : OpenTerm spec n) :
    hom.map (term.interpret (fun i => env (rho i)))
      (Eq.mp (congrArg F (interpret_rename rho env term))
        ((term.rename rho).inductInterpret F stepF env witnesses)) =
      term.inductInterpret (pullbackFibre f E) (pullbackStep f E) (fun i => env (rho i))
        (fun i => hom.map (env (rho i)) (witnesses (rho i))) :=
  term.inductInterpret_rename_fusion (pullbackFusionHom hom) rho env witnesses

end

end KanonMeta.MuFinitary
