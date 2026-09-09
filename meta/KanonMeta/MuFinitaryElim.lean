/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryOpen

/-!
Dependent elimination for the constructed carrier of a finite direct-recursion
family. Initiality supplies the eliminator, its propositional constructor law
and uniqueness. Structural induction on interpreted constructor terms agrees
with that eliminator. Motives inhabit `Type`; this does not interpret the
compiler's dependent typing judgment or its recursive-call checker.
-/

namespace KanonMeta.MuFinitary

open Initiality

noncomputable section

/-- Package a dependent constructor operation over the constructed carrier. -/
def displayed (spec : Spec) (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children)) :
    Displayed (recursive spec) where
  Fibre := fun {index} => match index with | () => F
  step := fun {index} => match index with
    | () => fun ctor children witnesses =>
        step ctor (fun i => children ⟨i⟩) (fun i => witnesses ⟨i⟩)

/-- Initiality constructs a dependent section for every displayed operation. -/
def semanticElim (spec : Spec) (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (value : Carrier spec) : F value :=
  Initiality.elim (recursiveInitial spec) (displayed spec F step) value

/-- The constructed dependent section preserves every ordered constructor. -/
theorem semanticElim_node (spec : Spec) (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec) :
    semanticElim spec F step (semanticNode spec ctor children) =
      step ctor children (fun i => semanticElim spec F step (children i)) :=
  Initiality.elim_beta (recursiveInitial spec) (displayed spec F step) ctor
    (fun i => children i.down)

/-- Any section satisfying the dependent constructor equation is the chosen one. -/
theorem semanticElim_unique (spec : Spec) (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (other : (value : Carrier spec) → F value)
    (comm : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      other (semanticNode spec ctor children) = step ctor children (fun i => other (children i)))
    (value : Carrier spec) : other value = semanticElim spec F step value :=
  Initiality.elim_unique (recursiveInitial spec) (displayed spec F step)
    (fun {index} => match index with | () => other)
    (fun {index} => match index with
      | () => fun ctor children => comm ctor (fun i => children ⟨i⟩)) value

/-- Structural induction supplies a witness over the interpretation of a value. -/
def Value.inductInterpret {spec : Spec} (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children)) :
    (value : Value spec) → F value.interpret
  | .node ctor children => step ctor (fun i => (children i).interpret)
      (fun i => (children i).inductInterpret F step)

/-- Constructed elimination agrees with structural induction on closed syntax. -/
theorem Value.semanticElim_interpret {spec : Spec} (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children)) :
    ∀ value : Value spec,
      semanticElim spec F step value.interpret = value.inductInterpret F step
  | .node ctor children =>
      (semanticElim_node spec F step ctor (fun i => (children i).interpret)).trans
        (congrArg (step ctor (fun i => (children i).interpret))
          (funext (fun i => (children i).semanticElim_interpret F step)))

/-- Open structural induction retains a dependent witness for each variable. -/
def OpenTerm.inductInterpret {spec : Spec} {n : Nat} (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (env : Fin n → Carrier spec) (witnesses : (i : Fin n) → F (env i)) :
    (term : OpenTerm spec n) → F (term.interpret env)
  | .var index => witnesses index
  | .node ctor children => step ctor (fun i => (children i).interpret env)
      (fun i => (children i).inductInterpret F step env witnesses)

/-- Open agreement uses the chosen dependent section at every environment entry. -/
theorem OpenTerm.semanticElim_interpret {spec : Spec} {n : Nat} (F : Carrier spec → Type)
    (step : ∀ (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec),
      ((i : Fin (spec.arity ctor)) → F (children i)) → F (semanticNode spec ctor children))
    (env : Fin n → Carrier spec) : ∀ term : OpenTerm spec n,
    semanticElim spec F step (term.interpret env) =
      term.inductInterpret F step env (fun i => semanticElim spec F step (env i))
  | .var (_index) => rfl
  | .node ctor children =>
      (semanticElim_node spec F step ctor (fun i => (children i).interpret env)).trans
        (congrArg (step ctor (fun i => (children i).interpret env))
          (funext (fun i => (children i).semanticElim_interpret F step env)))

private def interpretationHom (spec : Spec) :
    Hom (algebra spec (Value spec) Value.node) (recursive spec) where
  map := fun {index} => match index with | () => Value.interpret
  comm := fun {index} => match index with | () => fun (_ctor) (_children) => rfl

/-- Reifying and interpreting is the identity on every constructed inhabitant. -/
theorem interpret_reify {spec : Spec} (value : Carrier spec) :
    (reify spec value).interpret = value :=
  (recursiveInitial spec).unique (recursive spec)
    ((interpretationHom spec).comp
      ((recursiveInitial spec).fold (algebra spec (Value spec) Value.node)))
    (Hom.id (recursive spec)) value

/-- Constructor syntax distinguishes all inhabitants of the constructed carrier. -/
theorem reify_injective {spec : Spec} {left right : Carrier spec}
    (equal : reify spec left = reify spec right) : left = right :=
  (interpret_reify left).symm.trans
    ((congrArg Value.interpret equal).trans (interpret_reify right))

end

end KanonMeta.MuFinitary
