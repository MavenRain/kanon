/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityFusion
import KanonMeta.MuFinitaryElimSubst

/-!
Dependent fusion for finite direct-recursion families, including open terms
with arbitrary variable witnesses. Witness transformations preserve the base
value and each constructor operation. Substitution and renaming laws compare
the actual transported witnesses in the target motive.
-/

namespace KanonMeta.MuFinitary

noncomputable section

variable {spec : Spec} {F G : Carrier spec → Type}
    {stepF : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children)}
    {stepG : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → G (children i)) → G (semanticNode spec ctor children)}

/-- Package a constructor-preserving transformation of finite-family witnesses. -/
def displayedHom (map : (value : Carrier spec) → F value → G value)
    (comm : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec)
      (witnesses : (i : Fin (spec.arity ctor)) → F (children i)),
      map (semanticNode spec ctor children) (stepF ctor children witnesses) =
        stepG ctor children (fun i => map (children i) (witnesses i))) :
    Initiality.DisplayedHom (displayed spec F stepF) (displayed spec G stepG) where
  map := fun {index} => match index with | () => map
  comm := fun {index} => match index with
    | () => fun ctor children witnesses =>
        comm ctor (fun i => children ⟨i⟩) (fun i => witnesses ⟨i⟩)

variable (hom : Initiality.DisplayedHom (displayed spec F stepF) (displayed spec G stepG))

/-- Transforming a constructed dependent section equals target elimination. -/
theorem semanticElim_fusion (value : Carrier spec) :
    hom.map value (semanticElim spec F stepF value) = semanticElim spec G stepG value :=
  Initiality.elim_fusion (recursiveInitial spec) hom value

/-- Fusion of structural induction on closed constructor syntax. -/
theorem Value.inductInterpret_fusion : ∀ value : Value spec,
    hom.map value.interpret (value.inductInterpret F stepF) = value.inductInterpret G stepG
  | .node ctor children =>
      (hom.comm ctor (fun i => (children i.down).interpret)
        (fun i => (children i.down).inductInterpret F stepF)).trans
      (congrArg (stepG ctor (fun i => (children i).interpret))
        (funext (fun i => inductInterpret_fusion (children i))))

/-- Fusion maps every supplied variable witness, including noncanonical data. -/
theorem OpenTerm.inductInterpret_fusion {n : Nat}
    (env : Fin n → Carrier spec) (witnesses : (i : Fin n) → F (env i)) :
    ∀ term : OpenTerm spec n,
    hom.map (term.interpret env) (term.inductInterpret F stepF env witnesses) =
      term.inductInterpret G stepG env (fun i => hom.map (env i) (witnesses i))
  | .var (_index) => rfl
  | .node ctor children =>
      (hom.comm ctor (fun i => (children i.down).interpret env)
        (fun i => (children i.down).inductInterpret F stepF env witnesses)).trans
      (congrArg (stepG ctor (fun i => (children i).interpret env))
        (funext (fun i => inductInterpret_fusion env witnesses (children i))))

/-- Fusion after substitution transport agrees with target induction on replacements. -/
theorem OpenTerm.inductInterpret_substitute_fusion {n m : Nat}
    (sigma : Fin n → OpenTerm spec m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) (term : OpenTerm spec n) :
    hom.map (term.interpret (fun i => (sigma i).interpret env))
      (Eq.mp (congrArg F (interpret_substitute sigma env term))
        ((term.substitute sigma).inductInterpret F stepF env witnesses)) =
      term.inductInterpret G stepG (fun i => (sigma i).interpret env)
        (fun i => (sigma i).inductInterpret G stepG env
          (fun j => hom.map (env j) (witnesses j))) :=
  (hom.map_transport (interpret_substitute sigma env term)
    ((term.substitute sigma).inductInterpret F stepF env witnesses)).trans
    ((congrArg (Eq.mp (congrArg G (interpret_substitute sigma env term)))
      ((term.substitute sigma).inductInterpret_fusion hom env witnesses)).trans
      (inductInterpret_substitute G stepG sigma env
        (fun i => hom.map (env i) (witnesses i)) term))

/-- Fusion after renaming transport retains each selected transformed witness. -/
theorem OpenTerm.inductInterpret_rename_fusion {n m : Nat}
    (rho : Fin n → Fin m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) (term : OpenTerm spec n) :
    hom.map (term.interpret (fun i => env (rho i)))
      (Eq.mp (congrArg F (interpret_rename rho env term))
        ((term.rename rho).inductInterpret F stepF env witnesses)) =
      term.inductInterpret G stepG (fun i => env (rho i))
        (fun i => hom.map (env (rho i)) (witnesses (rho i))) :=
  (hom.map_transport (interpret_rename rho env term)
    ((term.rename rho).inductInterpret F stepF env witnesses)).trans
    ((congrArg (Eq.mp (congrArg G (interpret_rename rho env term)))
      ((term.rename rho).inductInterpret_fusion hom env witnesses)).trans
      (inductInterpret_rename G stepG rho env
        (fun i => hom.map (env i) (witnesses i)) term))

end

end KanonMeta.MuFinitary
