/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElim

/-!
Dependent structural induction commutes with substitution and renaming of
homogeneous finite-family constructor terms. Each equality explicitly transports
the resulting witness along the corresponding interpretation equality. Variable
witnesses are supplied freely, and motives inhabit `Type`.
-/

namespace KanonMeta.MuFinitary

noncomputable section

private theorem dependentStep_congr {X I : Type} (F : X → Type)
    (node : (I → X) → X)
    (step : (children : I → X) → ((i : I) → F (children i)) → F (node children))
    {left right : I → X} (equal : left = right)
    (leftWitnesses : (i : I) → F (left i))
    (rightWitnesses : (i : I) → F (right i))
    (witnessEqual : ∀ i : I,
      Eq.mp (congrArg F (congrFun equal i)) (leftWitnesses i) = rightWitnesses i) :
    Eq.mp (congrArg F (congrArg node equal)) (step left leftWitnesses) =
      step right rightWitnesses :=
  @Eq.rec (I → X) left (fun right equal =>
    ∀ (rightWitnesses : (i : I) → F (right i)),
      (∀ i : I, Eq.mp (congrArg F (congrFun equal i))
        (leftWitnesses i) = rightWitnesses i) →
      Eq.mp (congrArg F (congrArg node equal)) (step left leftWitnesses) =
        step right rightWitnesses)
    (fun (rightWitnesses : (i : I) → F (left i))
      (witnessEqual : ∀ i : I, leftWitnesses i = rightWitnesses i) =>
        congrArg (step left) (funext witnessEqual))
    right equal rightWitnesses witnessEqual

private theorem dependentCongr {X Y : Type} (F : Y → Type) (base : X → Y)
    (witness : (value : X) → F (base value)) {left right : X} (equal : left = right) :
    Eq.mp (congrArg F (congrArg base equal)) (witness left) = witness right :=
  @Eq.rec X left (fun right equal =>
    Eq.mp (congrArg F (congrArg base equal)) (witness left) = witness right)
    rfl right equal

open OpenTerm

/-- Substitute both semantic values and their supplied dependent witnesses. -/
theorem OpenTerm.inductInterpret_substitute {spec : Spec} {n m : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (sigma : Fin n → OpenTerm spec m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) : ∀ term : OpenTerm spec n,
    Eq.mp (congrArg F (interpret_substitute sigma env term))
      ((term.substitute sigma).inductInterpret F step env witnesses) =
      term.inductInterpret F step (fun i => (sigma i).interpret env)
        (fun i => (sigma i).inductInterpret F step env witnesses)
  | .var (_index) => rfl
  | .node ctor children => dependentStep_congr F (semanticNode spec ctor) (step ctor)
      (funext (fun i => interpret_substitute sigma env (children i)))
      (fun i => ((children i).substitute sigma).inductInterpret F step env witnesses)
      (fun i => (children i).inductInterpret F step (fun j => (sigma j).interpret env)
        (fun j => (sigma j).inductInterpret F step env witnesses))
      (fun i => inductInterpret_substitute F step sigma env witnesses (children i))

/-- Rename both semantic values and their supplied dependent witnesses. -/
theorem OpenTerm.inductInterpret_rename {spec : Spec} {n m : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (rho : Fin n → Fin m) (env : Fin m → Carrier spec)
    (witnesses : (i : Fin m) → F (env i)) : ∀ term : OpenTerm spec n,
    Eq.mp (congrArg F (interpret_rename rho env term))
      ((term.rename rho).inductInterpret F step env witnesses) =
      term.inductInterpret F step (fun i => env (rho i)) (fun i => witnesses (rho i))
  | .var (_index) => rfl
  | .node ctor children => dependentStep_congr F (semanticNode spec ctor) (step ctor)
      (funext (fun i => interpret_rename rho env (children i)))
      (fun i => ((children i).rename rho).inductInterpret F step env witnesses)
      (fun i => (children i).inductInterpret F step
        (fun j => env (rho j)) (fun j => witnesses (rho j)))
      (fun i => inductInterpret_rename F step rho env witnesses (children i))

/-- Identity substitution retains the original dependent witness after transport. -/
theorem OpenTerm.inductInterpret_substitute_id {spec : Spec} {n : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (env : Fin n → Carrier spec) (witnesses : (i : Fin n) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_substitute OpenTerm.var env term))
      ((term.substitute OpenTerm.var).inductInterpret F step env witnesses) =
      term.inductInterpret F step env witnesses :=
  inductInterpret_substitute F step OpenTerm.var env witnesses term

/-- Identity renaming retains the original dependent witness after transport. -/
theorem OpenTerm.inductInterpret_rename_id {spec : Spec} {n : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (env : Fin n → Carrier spec) (witnesses : (i : Fin n) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_rename (fun i => i) env term))
      ((term.rename (fun i => i)).inductInterpret F step env witnesses) =
      term.inductInterpret F step env witnesses :=
  inductInterpret_rename F step (fun i => i) env witnesses term

/-- Sequential and composed substitutions give the same transported witness. -/
theorem OpenTerm.inductInterpret_substitute_comp {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (sigma : Fin n → OpenTerm spec m) (tau : Fin m → OpenTerm spec k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (congrArg (fun body : OpenTerm spec k => body.interpret env)
      (substitute_comp sigma tau term)))
      (((term.substitute sigma).substitute tau).inductInterpret F step env witnesses) =
      (term.substitute (fun i => (sigma i).substitute tau)).inductInterpret
        F step env witnesses :=
  dependentCongr F (fun body : OpenTerm spec k => body.interpret env)
    (fun body => body.inductInterpret F step env witnesses) (substitute_comp sigma tau term)

/-- Sequential and composed renamings give the same transported witness. -/
theorem OpenTerm.inductInterpret_rename_comp {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (rho : Fin n → Fin m) (tau : Fin m → Fin k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (congrArg (fun body : OpenTerm spec k => body.interpret env)
      (rename_comp rho tau term)))
      (((term.rename rho).rename tau).inductInterpret F step env witnesses) =
      (term.rename (fun i => tau (rho i))).inductInterpret F step env witnesses :=
  dependentCongr F (fun body : OpenTerm spec k => body.interpret env)
    (fun body => body.inductInterpret F step env witnesses) (rename_comp rho tau term)

end

end KanonMeta.MuFinitary
