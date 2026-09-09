/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryDecode
import KanonMeta.Subst

/-!
Open constructor terms for one finite recursive family. The context contains
only values of this family, and its size bounds every de Bruijn variable.
These operations and laws concern this homogeneous fragment, not the general
kernel typing judgment or dependent substitution.
-/

namespace KanonMeta.MuFinitary

/-- Constructor trees with variables bounded by the homogeneous context. -/
inductive OpenTerm (spec : Spec) (n : Nat) where
  | var (index : Fin n)
  | node (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → OpenTerm spec n)

namespace OpenTerm

/-- Encode an open term as raw syntax, with variables as raw indices. -/
def encode {spec : Spec} {n : Nat} : OpenTerm spec n → Term
  | .var index => .var index.val
  | .node ctor children => .intro (family spec.familyName)
      (.actor (spec.constructorName ctor)) (List.ofFn (fun i => (children i).encode))

/-- Rename every variable of an open term along a map of contexts. -/
def rename {spec : Spec} {n m : Nat} :
    OpenTerm spec n → (Fin n → Fin m) → OpenTerm spec m
  | .var index, rho => .var (rho index)
  | .node ctor children, rho => .node ctor (fun i => (children i).rename rho)

/-- Replace every variable of an open term by a term of the target context. -/
def substitute {spec : Spec} {n m : Nat} :
    OpenTerm spec n → (Fin n → OpenTerm spec m) → OpenTerm spec m
  | .var index, sigma => sigma index
  | .node ctor children, sigma => .node ctor (fun i => (children i).substitute sigma)

/-- Fold an open term with an environment and a constructor algebra. -/
def evaluate {spec : Spec} {n : Nat} {X : Type} : OpenTerm spec n →
    (Fin n → X) → ((ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) → X
  | .var index, env, (_step) => env index
  | .node ctor children, env, step => step ctor (fun i => (children i).evaluate env step)

/-- Interpret an open term in the carrier of the declared family. -/
noncomputable def interpret {spec : Spec} {n : Nat}
    (term : OpenTerm spec n) (env : Fin n → Carrier spec) : Carrier spec :=
  term.evaluate env (semanticNode spec)

/-- The identity renaming keeps the term. -/
theorem rename_id {spec : Spec} {n : Nat} :
    ∀ term : OpenTerm spec n, term.rename (fun i => i) = term
  | .var (_index) => rfl
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => rename_id (children i)))

/-- Two renamings compose into one renaming. -/
theorem rename_comp {spec : Spec} {n m k : Nat}
    (rho : Fin n → Fin m) (tau : Fin m → Fin k) :
    ∀ term : OpenTerm spec n,
      (term.rename rho).rename tau = term.rename (fun i => tau (rho i))
  | .var (_index) => rfl
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => rename_comp rho tau (children i)))

/-- The variable substitution keeps the term. -/
theorem substitute_id {spec : Spec} {n : Nat} :
    ∀ term : OpenTerm spec n, term.substitute OpenTerm.var = term
  | .var (_index) => rfl
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => substitute_id (children i)))

/-- Two substitutions compose into one substitution. -/
theorem substitute_comp {spec : Spec} {n m k : Nat}
    (sigma : Fin n → OpenTerm spec m) (tau : Fin m → OpenTerm spec k) :
    ∀ term : OpenTerm spec n,
      (term.substitute sigma).substitute tau =
        term.substitute (fun i => (sigma i).substitute tau)
  | .var (_index) => rfl
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => substitute_comp sigma tau (children i)))

/-- A renaming is the substitution that sends variables to variables. -/
theorem rename_eq_substitute {spec : Spec} {n m : Nat} (rho : Fin n → Fin m) :
    ∀ term : OpenTerm spec n,
      term.rename rho = term.substitute (fun i => .var (rho i))
  | .var (_index) => rfl
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => rename_eq_substitute rho (children i)))

private theorem substArgs_ofFn (raw : Subst) : ∀ (n : Nat) (args : Fin n → Term),
    substArgs raw (List.ofFn args) = List.ofFn (fun i => subst raw (args i))
  | 0, (_args) => rfl
  | n + 1, args => (congrArg (substArgs raw) (List.ofFn_succ (f := args))).trans
      ((congrArg (List.cons (subst raw (args 0)))
        (substArgs_ofFn raw n (fun i => args i.succ))).trans
          (List.ofFn_succ (f := fun i => subst raw (args i))).symm)

private theorem renArgs_ofFn (raw : Ren) : ∀ (n : Nat) (args : Fin n → Term),
    renArgs raw (List.ofFn args) = List.ofFn (fun i => ren raw (args i))
  | 0, (_args) => rfl
  | n + 1, args => (congrArg (renArgs raw) (List.ofFn_succ (f := args))).trans
      ((congrArg (List.cons (ren raw (args 0)))
        (renArgs_ofFn raw n (fun i => args i.succ))).trans
          (List.ofFn_succ (f := fun i => ren raw (args i))).symm)

/-- Raw substitution may do anything outside the finite context. -/
theorem encode_substitute {spec : Spec} {n m : Nat}
    (sigma : Fin n → OpenTerm spec m) (raw : Subst)
    (agreement : ∀ i : Fin n, raw i.val = (sigma i).encode) :
    ∀ term : OpenTerm spec n,
      (term.substitute sigma).encode = subst raw term.encode
  | .var index => (agreement index).symm
  | .node ctor children => congrArg
      (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
      ((congrArg List.ofFn (funext (fun i => encode_substitute sigma raw agreement
        (children i)))).trans (substArgs_ofFn raw (spec.arity ctor)
          (fun i => (children i).encode)).symm)

/-- Raw renaming may do anything outside the finite context. -/
theorem encode_rename {spec : Spec} {n m : Nat}
    (rho : Fin n → Fin m) (raw : Ren)
    (agreement : ∀ i : Fin n, raw i.val = (rho i).val) :
    ∀ term : OpenTerm spec n, (term.rename rho).encode = ren raw term.encode
  | .var index => congrArg Term.var (agreement index).symm
  | .node ctor children => congrArg
      (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
      ((congrArg List.ofFn (funext (fun i => encode_rename rho raw agreement
        (children i)))).trans (renArgs_ofFn raw (spec.arity ctor)
          (fun i => (children i).encode)).symm)

/-- Evaluation of a substituted term evaluates the substitution first. -/
theorem evaluate_substitute {spec : Spec} {n m : Nat} {X : Type}
    (sigma : Fin n → OpenTerm spec m) (env : Fin m → X)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    ∀ term : OpenTerm spec n,
      (term.substitute sigma).evaluate env step =
        term.evaluate (fun i => (sigma i).evaluate env step) step
  | .var (_index) => rfl
  | .node ctor children => congrArg (step ctor)
      (funext (fun i => evaluate_substitute sigma env step (children i)))

/-- Interpretation commutes with substitution in a homogeneous environment. -/
theorem interpret_substitute {spec : Spec} {n m : Nat}
    (sigma : Fin n → OpenTerm spec m) (env : Fin m → Carrier spec)
    (term : OpenTerm spec n) :
    (term.substitute sigma).interpret env =
      term.interpret (fun i => (sigma i).interpret env) :=
  evaluate_substitute sigma env (semanticNode spec) term

/-- Evaluation of a renamed term evaluates in the renamed environment. -/
theorem evaluate_rename {spec : Spec} {n m : Nat} {X : Type}
    (rho : Fin n → Fin m) (env : Fin m → X)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    ∀ term : OpenTerm spec n,
      (term.rename rho).evaluate env step = term.evaluate (fun i => env (rho i)) step
  | .var (_index) => rfl
  | .node ctor children => congrArg (step ctor)
      (funext (fun i => evaluate_rename rho env step (children i)))

/-- Interpretation of a renamed term interprets in the renamed environment. -/
theorem interpret_rename {spec : Spec} {n m : Nat}
    (rho : Fin n → Fin m) (env : Fin m → Carrier spec) (term : OpenTerm spec n) :
    (term.rename rho).interpret env = term.interpret (fun i => env (rho i)) :=
  evaluate_rename rho env (semanticNode spec) term

private theorem ofFn_position {α : Type} {n : Nat} (values : Fin n → α) (i : Fin n) :
    (List.ofFn values)[i.val]? = some (values i) :=
  List.getElem?_ofFn.trans (dif_pos i.isLt)

private theorem ofFn_injective {α : Type} {n : Nat} {left right : Fin n → α}
    (equal : List.ofFn left = List.ofFn right) (i : Fin n) : left i = right i :=
  Option.some.inj ((ofFn_position left i).symm.trans
    ((congrArg (fun values => values[i.val]?) equal).trans (ofFn_position right i)))

/-- Valid constructor names retain positions, variables and ordered children. -/
theorem encode_injective {spec : Spec} {n : Nat} (valid : spec.Valid) :
    ∀ {left right : OpenTerm spec n}, left.encode = right.encode → left = right
  | .var (_left), .var (_right), equal => congrArg OpenTerm.var (Fin.ext (Term.var.inj equal))
  | .var (_index), .node (_ctor) (_children), equal => nomatch equal
  | .node (_ctor) (_children), .var (_index), equal => nomatch equal
  | .node leftCtor leftChildren, .node (_rightCtor) rightChildren, equal =>
      let ctorEqual :=
        constructorName_injective valid (Addr.actor.inj (Term.intro.inj equal).2.1)
      Eq.rec (motive := fun ctor (_equal) =>
        ∀ children : Fin (spec.arity ctor) → OpenTerm spec n,
          (OpenTerm.node leftCtor leftChildren).encode =
            (OpenTerm.node ctor children).encode →
          OpenTerm.node leftCtor leftChildren = OpenTerm.node ctor children)
        (fun _children equalChildren => congrArg (OpenTerm.node leftCtor) (funext (fun i =>
          encode_injective valid (ofFn_injective (Term.intro.inj equalChildren).2.2 i))))
        ctorEqual rightChildren equal

/-- Embed a closed value into any homogeneous context. -/
def ofValue {spec : Spec} {n : Nat} : Value spec → OpenTerm spec n
  | .node ctor children => .node ctor (fun i => ofValue (children i))

/-- Empty contexts have no variable case. -/
def close {spec : Spec} : OpenTerm spec 0 → Value spec
  | .var index => Fin.elim0 index
  | .node ctor children => .node ctor (fun i => (children i).close)

/-- An embedded closed value keeps the raw encoding of that value. -/
theorem encode_ofValue {spec : Spec} {n : Nat} :
    ∀ value : Value spec, (ofValue value : OpenTerm spec n).encode = value.encode
  | .node ctor children => congrArg
      (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
      (congrArg List.ofFn (funext (fun i => encode_ofValue (children i))))

/-- Closing a term of the empty context keeps its raw encoding. -/
theorem encode_close {spec : Spec} :
    ∀ term : OpenTerm spec 0, term.close.encode = term.encode
  | .var index => Fin.elim0 index
  | .node ctor children => congrArg
      (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
      (congrArg List.ofFn (funext (fun i => encode_close (children i))))

/-- Closing an embedded value returns that value. -/
theorem close_ofValue {spec : Spec} : ∀ value : Value spec, (ofValue value).close = value
  | .node ctor children => congrArg (Value.node ctor)
      (funext (fun i => close_ofValue (children i)))

/-- Embedding a closed term returns that term. -/
theorem ofValue_close {spec : Spec} : ∀ term : OpenTerm spec 0, ofValue term.close = term
  | .var index => Fin.elim0 index
  | .node ctor children => congrArg (OpenTerm.node ctor)
      (funext (fun i => ofValue_close (children i)))

/-- An embedded value evaluates as the closed value folds. -/
theorem evaluate_ofValue {spec : Spec} {n : Nat} {X : Type} (env : Fin n → X)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    ∀ value : Value spec, (ofValue value).evaluate env step = value.fold step
  | .node ctor children => congrArg (step ctor)
      (funext (fun i => evaluate_ofValue env step (children i)))

/-- A closed term folds as the term evaluates in the empty environment. -/
theorem evaluate_close {spec : Spec} {X : Type}
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    ∀ term : OpenTerm spec 0, term.close.fold step = term.evaluate Fin.elim0 step
  | .var index => Fin.elim0 index
  | .node ctor children => congrArg (step ctor)
      (funext (fun i => evaluate_close step (children i)))

/-- An embedded value interprets as the closed value interprets. -/
theorem interpret_ofValue {spec : Spec} {n : Nat} (env : Fin n → Carrier spec)
    (value : Value spec) : (ofValue value).interpret env = value.interpret :=
  evaluate_ofValue env (semanticNode spec) value

/-- A closed term interprets as the term interprets in the empty environment. -/
theorem interpret_close {spec : Spec} (term : OpenTerm spec 0) :
    term.close.interpret = term.interpret Fin.elim0 :=
  evaluate_close (semanticNode spec) term

/-- A semantic fold of an interpretation folds the environment first. -/
theorem fold_interpret {spec : Spec} {n : Nat} (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X)
    (env : Fin n → Carrier spec) : ∀ term : OpenTerm spec n,
    semanticFold spec X step (term.interpret env) =
      term.evaluate (fun i => semanticFold spec X step (env i)) step
  | .var (_index) => rfl
  | .node ctor children => (semanticFold_node spec X step ctor
      (fun i => (children i).interpret env)).trans
      (congrArg (step ctor) (funext (fun i => fold_interpret X step env (children i))))

end OpenTerm

end KanonMeta.MuFinitary
