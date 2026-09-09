/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElimSubst

/-!
Coherence for dependent structural induction on open finite-family terms.
Pointwise changes to an environment must also preserve its supplied witnesses
after transport. This congruence identifies the direct and iterated semantic
substitution environments. The composition laws then compare the actual
transported induction results, including their arbitrary `Type`-valued data.
-/

namespace KanonMeta.MuFinitary

noncomputable section

private theorem environmentWitness_congr {X I : Type} (F : X → Type)
    (base : (I → X) → X)
    (induct : (env : I → X) → ((i : I) → F (env i)) → F (base env))
    {left right : I → X} (equal : left = right)
    (leftWitnesses : (i : I) → F (left i))
    (rightWitnesses : (i : I) → F (right i))
    (witnessEqual : ∀ i : I,
      Eq.mp (congrArg F (congrFun equal i)) (leftWitnesses i) = rightWitnesses i) :
    Eq.mp (congrArg F (congrArg base equal)) (induct left leftWitnesses) =
      induct right rightWitnesses :=
  @Eq.rec (I → X) left (fun right equal =>
    ∀ (rightWitnesses : (i : I) → F (right i)),
      (∀ i : I, Eq.mp (congrArg F (congrFun equal i))
        (leftWitnesses i) = rightWitnesses i) →
      Eq.mp (congrArg F (congrArg base equal)) (induct left leftWitnesses) =
        induct right rightWitnesses)
    (fun (rightWitnesses : (i : I) → F (left i))
      (witnessEqual : ∀ i : I, leftWitnesses i = rightWitnesses i) =>
        congrArg (induct left) (funext witnessEqual))
    right equal rightWitnesses witnessEqual

open OpenTerm

/-- Equal environments and transported supplied witnesses give equal induction data. -/
theorem OpenTerm.inductInterpret_congr {spec : Spec} {n : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    {left right : Fin n → Carrier spec} (equal : ∀ i : Fin n, left i = right i)
    (leftWitnesses : (i : Fin n) → F (left i))
    (rightWitnesses : (i : Fin n) → F (right i))
    (witnessEqual : ∀ i : Fin n,
      Eq.mp (congrArg F (equal i)) (leftWitnesses i) = rightWitnesses i)
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (congrArg (fun env => term.interpret env) (funext equal)))
      (term.inductInterpret F step left leftWitnesses) =
      term.inductInterpret F step right rightWitnesses :=
  environmentWitness_congr F (fun env => term.interpret env)
    (fun env witnesses => term.inductInterpret F step env witnesses)
    (funext equal) leftWitnesses rightWitnesses witnessEqual

/-- Direct replacement witnesses agree with their successive semantic substitutions. -/
theorem OpenTerm.inductInterpret_substitute_comp_coherent {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (sigma : Fin n → OpenTerm spec m) (tau : Fin m → OpenTerm spec k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (congrArg (fun values => term.interpret values)
      (funext (fun i => interpret_substitute tau env (sigma i)))))
      (term.inductInterpret F step (fun i => ((sigma i).substitute tau).interpret env)
        (fun i => ((sigma i).substitute tau).inductInterpret F step env witnesses)) =
      term.inductInterpret F step
        (fun i => (sigma i).interpret (fun j => (tau j).interpret env))
        (fun i => (sigma i).inductInterpret F step (fun j => (tau j).interpret env)
          (fun j => (tau j).inductInterpret F step env witnesses)) :=
  inductInterpret_congr F step (fun i => interpret_substitute tau env (sigma i))
    (fun i => ((sigma i).substitute tau).inductInterpret F step env witnesses)
    (fun i => (sigma i).inductInterpret F step (fun j => (tau j).interpret env)
      (fun j => (tau j).inductInterpret F step env witnesses))
    (fun i => inductInterpret_substitute F step tau env witnesses (sigma i)) term

/-- Applying substitution naturality twice retains the iterated supplied witnesses. -/
theorem OpenTerm.inductInterpret_substitute_seq {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (sigma : Fin n → OpenTerm spec m) (tau : Fin m → OpenTerm spec k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_substitute sigma (fun j => (tau j).interpret env) term))
      (Eq.mp (congrArg F (interpret_substitute tau env (term.substitute sigma)))
        (((term.substitute sigma).substitute tau).inductInterpret F step env witnesses)) =
      term.inductInterpret F step
        (fun i => (sigma i).interpret (fun j => (tau j).interpret env))
        (fun i => (sigma i).inductInterpret F step (fun j => (tau j).interpret env)
          (fun j => (tau j).inductInterpret F step env witnesses)) :=
  (congrArg
    (Eq.mp (congrArg F (interpret_substitute sigma (fun j => (tau j).interpret env) term)))
    (inductInterpret_substitute F step tau env witnesses (term.substitute sigma))).trans
      (inductInterpret_substitute F step sigma (fun j => (tau j).interpret env)
        (fun j => (tau j).inductInterpret F step env witnesses) term)

/-- Sequential naturality agrees with syntax composition followed by semantic coherence. -/
theorem OpenTerm.inductInterpret_substitute_comp_routes {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (sigma : Fin n → OpenTerm spec m) (tau : Fin m → OpenTerm spec k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_substitute sigma (fun j => (tau j).interpret env) term))
      (Eq.mp (congrArg F (interpret_substitute tau env (term.substitute sigma)))
        (((term.substitute sigma).substitute tau).inductInterpret F step env witnesses)) =
    Eq.mp (congrArg F (congrArg (fun values => term.interpret values)
      (funext (fun i => interpret_substitute tau env (sigma i)))))
      (Eq.mp (congrArg F (interpret_substitute (fun i => (sigma i).substitute tau) env term))
        (Eq.mp (congrArg F (congrArg (fun body : OpenTerm spec k => body.interpret env)
          (substitute_comp sigma tau term)))
          (((term.substitute sigma).substitute tau).inductInterpret F step env witnesses))) :=
  let environmentTransport := Eq.mp (congrArg F
    (congrArg (fun values => term.interpret values)
      (funext (fun i => interpret_substitute tau env (sigma i)))))
  let substitutionTransport := Eq.mp
    (congrArg F (interpret_substitute (fun i => (sigma i).substitute tau) env term))
  (inductInterpret_substitute_seq F step sigma tau env witnesses term).trans
    ((congrArg (fun value => environmentTransport (substitutionTransport value))
      (inductInterpret_substitute_comp F step sigma tau env witnesses term)).trans
      ((congrArg environmentTransport
        (inductInterpret_substitute F step (fun i => (sigma i).substitute tau)
          env witnesses term)).trans
        (inductInterpret_substitute_comp_coherent F step sigma tau env witnesses term))).symm

/-- Applying renaming naturality twice retains each selected supplied witness. -/
theorem OpenTerm.inductInterpret_rename_seq {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (rho : Fin n → Fin m) (tau : Fin m → Fin k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_rename rho (fun j => env (tau j)) term))
      (Eq.mp (congrArg F (interpret_rename tau env (term.rename rho)))
        (((term.rename rho).rename tau).inductInterpret F step env witnesses)) =
      term.inductInterpret F step (fun i => env (tau (rho i)))
        (fun i => witnesses (tau (rho i))) :=
  (congrArg (Eq.mp (congrArg F (interpret_rename rho (fun j => env (tau j)) term)))
    (inductInterpret_rename F step tau env witnesses (term.rename rho))).trans
      (inductInterpret_rename F step rho (fun j => env (tau j))
        (fun j => witnesses (tau j)) term)

/-- Sequential renaming naturality agrees with the composed renaming route. -/
theorem OpenTerm.inductInterpret_rename_comp_routes {spec : Spec} {n m k : Nat}
    (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (rho : Fin n → Fin m) (tau : Fin m → Fin k)
    (env : Fin k → Carrier spec) (witnesses : (i : Fin k) → F (env i))
    (term : OpenTerm spec n) :
    Eq.mp (congrArg F (interpret_rename rho (fun j => env (tau j)) term))
      (Eq.mp (congrArg F (interpret_rename tau env (term.rename rho)))
        (((term.rename rho).rename tau).inductInterpret F step env witnesses)) =
    Eq.mp (congrArg F (interpret_rename (fun i => tau (rho i)) env term))
      (Eq.mp (congrArg F (congrArg (fun body : OpenTerm spec k => body.interpret env)
        (rename_comp rho tau term)))
        (((term.rename rho).rename tau).inductInterpret F step env witnesses)) :=
  (inductInterpret_rename_seq F step rho tau env witnesses term).trans
    ((congrArg (Eq.mp (congrArg F (interpret_rename (fun i => tau (rho i)) env term)))
      (inductInterpret_rename_comp F step rho tau env witnesses term)).trans
        (inductInterpret_rename F step (fun i => tau (rho i)) env witnesses term)).symm

end

end KanonMeta.MuFinitary
