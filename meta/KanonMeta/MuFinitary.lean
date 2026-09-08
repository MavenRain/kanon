/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuNat
import KanonMeta.FinitaryConstruction

/-!
A declaration-driven bridge for a finite, single-family recursive fragment.
Every argument is a direct recursive occurrence with quantity `many`; the
family has no parameters or indices and lives at exported level one.
Validation reconstructs every declaration field and returns its equality
certificate. Constructor and argument order and binder names are retained.

The semantic carrier and initiality are constructed by FinitaryConstruction.
These results concern this explicitly bounded fragment, not the general
kernel checker or arbitrary compiled recursive definitions.
-/

namespace KanonMeta.MuFinitary

open Initiality

abbrev Declaration := MuNat.Declaration
abbrev Constructor := MuNat.Constructor

def family (name : String) : Shape := .SMu name []

def familyType (name : String) : Term := .lan (family name) (.sec (.SColl 0) [])

structure ConstructorSpec where
  name : String
  binders : List String
  deriving DecidableEq, Repr

def ConstructorSpec.arguments (ctor : ConstructorSpec) (name : String) :
    List (Quantity × String × Term) :=
  ctor.binders.map (fun binder => (.many, binder, familyType name))

def ConstructorSpec.export (ctor : ConstructorSpec) (name : String) : Constructor where
  name := ctor.name
  args := ctor.arguments name
  resultIndices := []
  fullArity := ctor.binders.length
  selfRecursive := ctor.binders.length != 0

structure Spec where
  familyName : String
  constructors : List ConstructorSpec
  deriving DecidableEq, Repr

def Spec.declaration (spec : Spec) : Declaration where
  name := spec.familyName
  params := []
  indices := []
  level := 1
  status := .complete (spec.constructors.map ConstructorSpec.name)
  constructors := spec.constructors.map (fun ctor => ctor.export spec.familyName)
  positive := true

/-- A deliberately bounded ASCII identifier syntax, including binder `_`. -/
def validName (name : String) : Bool :=
  match name.toList with
  | [] => false
  | first :: rest => (first.isAlpha || first == '_') &&
      rest.all (fun char => char.isAlphanum || char == '_' || char == '\'')

def Spec.Valid (spec : Spec) : Prop :=
  validName spec.familyName = true ∧
    spec.constructors.all (fun ctor => validName ctor.name && ctor.binders.all validName) = true ∧
    (spec.constructors.map ConstructorSpec.name).Nodup

instance (spec : Spec) : Decidable spec.Valid :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _))

/-- Support is an exact reconstruction with checked name constraints. -/
def Supported (declaration : Declaration) : Prop :=
  ∃ spec : Spec, spec.Valid ∧ declaration = spec.declaration

structure Validated (declaration : Declaration) where
  spec : Spec
  valid : spec.Valid
  agreement : declaration = spec.declaration

theorem Validated.supported {declaration : Declaration}
    (checked : Validated declaration) : Supported declaration :=
  ⟨checked.spec, checked.valid, checked.agreement⟩

inductive ValidationError where
  | parameters
  | indices
  | universe (actual : Nat)
  | incompleteStatus
  | constructorNames
  | resultIndices (constructor : String)
  | argumentQuantity
  | argumentType
  | fullArity (constructor : String) (expected actual : Nat)
  | recursiveFlag (constructor : String)
  | positivity
  | invalidNames
  deriving DecidableEq, Repr

private def validateType (name : String) (term : Term) :
    Except ValidationError {_witness : Unit // term = familyType name} :=
  match term with
  | .lan (.SMu actual []) (.sec (.SColl 0) []) =>
      if h : actual = name then .ok ⟨(), congrArg familyType h⟩
      else .error .argumentType
  | .var (_) => .error .argumentType
  | .univ (_) => .error .argumentType
  | .lan _ (_) => .error .argumentType
  | .ran _ (_) => .error .argumentType
  | .intro _ _ (_) => .error .argumentType
  | .elim _ _ _ _ (_) => .error .argumentType
  | .sec _ (_) => .error .argumentType
  | .out _ _ (_) => .error .argumentType
  | .letIn _ _ _ (_) => .error .argumentType
  | .ann _ (_) => .error .argumentType
  | .global (_) => .error .argumentType
  | .lit (_) => .error .argumentType

private def validateArguments (name : String) :
    (args : List (Quantity × String × Term)) →
    Except ValidationError {binders : List String //
      args = binders.map (fun binder => (.many, binder, familyType name))}
  | [] => .ok ⟨[], rfl⟩
  | (.zero, _binder, _term) :: (_rest) => .error .argumentQuantity
  | (.one, _binder, _term) :: (_rest) => .error .argumentQuantity
  | (.many, binder, term) :: rest =>
      match validateType name term with
      | .error error => .error error
      | .ok ⟨(), typeEqual⟩ =>
          match validateArguments name rest with
          | .error error => .error error
          | .ok ⟨binders, restEqual⟩ => .ok ⟨binder :: binders,
              (congrArg (fun ty => (.many, binder, ty) :: rest) typeEqual).trans
                (congrArg (List.cons (.many, binder, familyType name)) restEqual)⟩

private def validateConstructor (name : String) (ctor : Constructor) :
    Except ValidationError {spec : ConstructorSpec // ctor = spec.export name} :=
  match ctor with
  | ⟨ctorName, args, resultIndices, arity, recursive⟩ =>
      match resultIndices with
      | _head :: (_tail) => .error (.resultIndices ctorName)
      | [] => match validateArguments name args with
        | .error error => .error error
        | .ok ⟨binders, argsEqual⟩ =>
            if arityEqual : arity = binders.length then
              if recursiveEqual : recursive = (binders.length != 0) then
                .ok ⟨⟨ctorName, binders⟩,
                  (congrArg (fun xs => MuNat.Constructor.mk ctorName xs [] arity recursive)
                    argsEqual).trans
                    ((congrArg (fun n => MuNat.Constructor.mk ctorName
                      (binders.map (fun binder => (.many, binder, familyType name))) [] n recursive)
                      arityEqual).trans
                      (congrArg (fun flag => MuNat.Constructor.mk ctorName
                        (binders.map (fun binder => (.many, binder, familyType name))) []
                        binders.length flag) recursiveEqual))⟩
              else .error (.recursiveFlag ctorName)
            else .error (.fullArity ctorName binders.length arity)

private def validateConstructors (name : String) : (ctors : List Constructor) →
    Except ValidationError {specs : List ConstructorSpec //
      ctors = specs.map (fun spec => spec.export name)}
  | [] => .ok ⟨[], rfl⟩
  | ctor :: rest => match validateConstructor name ctor with
    | .error error => .error error
    | .ok ⟨spec, equal⟩ => match validateConstructors name rest with
      | .error error => .error error
      | .ok ⟨specs, restEqual⟩ => .ok ⟨spec :: specs,
          (congrArg (fun first => first :: rest) equal).trans
            (congrArg (List.cons (spec.export name)) restEqual)⟩

/-- Total validation returns proof of agreement for every exported field.
The complete status must enumerate exactly the constructor names in order. -/
def validate (declaration : Declaration) : Except ValidationError (Validated declaration) :=
  match declaration with
  | ⟨name, params, indices, level, status, constructors, positive⟩ =>
    match params with
    | _head :: (_tail) => .error .parameters
    | [] => match indices with
      | _head :: (_tail) => .error .indices
      | [] => if levelEqual : level = 1 then
          if positiveEqual : positive = true then
            match status with
            | .builtin => .error .incompleteStatus
            | .provisional => .error .incompleteStatus
            | .complete names => match validateConstructors name constructors with
              | .error error => .error error
              | .ok ⟨specs, constructorsEqual⟩ =>
                if namesEqual : names = specs.map ConstructorSpec.name then
                  let spec : Spec := ⟨name, specs⟩
                  if valid : spec.Valid then
                    .ok ⟨spec, valid,
                      (congrArg (fun flag => MuNat.Declaration.mk name [] [] level
                        (.complete names) constructors flag) positiveEqual).trans
                      ((congrArg (fun n => MuNat.Declaration.mk name [] [] n
                        (.complete names) constructors true) levelEqual).trans
                        ((congrArg (fun ns => MuNat.Declaration.mk name [] [] 1
                          (.complete ns) constructors true) namesEqual).trans
                          (congrArg (fun cs => MuNat.Declaration.mk name [] [] 1
                            (.complete (specs.map ConstructorSpec.name)) cs true)
                            constructorsEqual)))⟩
                  else .error .invalidNames
                else .error .constructorNames
          else .error .positivity
        else .error (.universe level)

/-- Support rides on the `Validated` record that the validator supplies.
The acceptance hypothesis is decoration. The test theorem `generated_validation`
pins `validate` on the generated declaration. -/
theorem validate_sound (declaration : Declaration) (checked : Validated declaration)
    (_accepted : validate declaration = .ok checked) : Supported declaration :=
  checked.supported

abbrev Spec.Constructor (spec : Spec) := Fin spec.constructors.length

def Spec.arity (spec : Spec) (ctor : spec.Constructor) : Nat :=
  (spec.constructors.get ctor).binders.length

def Spec.constructorName (spec : Spec) (ctor : spec.Constructor) : String :=
  (spec.constructors.get ctor).name

def Spec.signature (spec : Spec) : FinitaryConstruction.Signature Unit where
  Shape := fun (_index) => spec.Constructor
  arity := spec.arity
  child := fun (_ctor) (_position) => ()

/-- Each node has exactly its declared, ordered number of recursive children. -/
inductive Value (spec : Spec) where
  | node (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Value spec)

def Value.fold {spec : Spec} {X : Type}
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) : Value spec → X
  | .node ctor children => step ctor (fun pos => (children pos).fold step)

def Value.encode {spec : Spec} : Value spec → Term :=
  Value.fold (fun ctor children => .intro (family spec.familyName)
    (.actor (spec.constructorName ctor)) (List.ofFn children))

theorem Value.fold_node {spec : Spec} {X : Type}
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X)
    (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Value spec) :
    (Value.node ctor children).fold step =
      step ctor (fun pos => (children pos).fold step) := rfl

theorem Value.fold_constructors {spec : Spec} :
    ∀ value : Value spec, value.fold Value.node = value
  | .node ctor children => congrArg (Value.node ctor)
      (funext (fun pos => (children pos).fold_constructors))

noncomputable def recursive (spec : Spec) : Algebra spec.signature.polynomial :=
  FinitaryConstruction.recursive spec.signature

noncomputable def recursiveInitial (spec : Spec) : Initial (recursive spec) :=
  FinitaryConstruction.recursiveInitial spec.signature

abbrev Carrier (spec : Spec) := (recursive spec).Carrier ()

noncomputable section

def semanticNode (spec : Spec) (ctor : spec.Constructor)
    (children : Fin (spec.arity ctor) → Carrier spec) : Carrier spec :=
  (recursive spec).roll ctor (fun pos => children pos.down)

def Value.interpret {spec : Spec} (value : Value spec) : Carrier spec :=
  value.fold (semanticNode spec)

structure CheckedValue (declaration : Declaration) where
  checked : Validated declaration
  value : Value checked.spec

def CheckedValue.interpret {declaration : Declaration}
    (value : CheckedValue declaration) : Carrier value.checked.spec :=
  value.value.interpret

def algebra (spec : Spec) (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    Algebra spec.signature.polynomial where
  Carrier := fun (_index) => X
  roll := fun ctor children => step ctor (fun pos => children ⟨pos⟩)

def semanticFold (spec : Spec) (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X)
    (value : Carrier spec) : X :=
  ((recursiveInitial spec).fold (algebra spec X step)).map value

theorem semanticFold_node (spec : Spec) (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X)
    (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Carrier spec) :
    semanticFold spec X step (semanticNode spec ctor children) =
      step ctor (fun pos => semanticFold spec X step (children pos)) :=
  ((recursiveInitial spec).fold (algebra spec X step)).comm ctor (fun pos => children pos.down)

theorem fold_interpret {spec : Spec} (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    ∀ value : Value spec,
      semanticFold spec X step value.interpret = value.fold step
  | .node ctor children => (semanticFold_node spec X step ctor
      (fun pos => (children pos).interpret)).trans
      (congrArg (step ctor) (funext (fun pos => fold_interpret X step (children pos))))

theorem semanticFold_unique (spec : Spec) (X : Type)
    (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X)
    (other : Hom (recursive spec) (algebra spec X step)) (value : Carrier spec) :
    other.map value = semanticFold spec X step value :=
  (recursiveInitial spec).unique (algebra spec X step) other
    ((recursiveInitial spec).fold (algebra spec X step)) value

def reify (spec : Spec) : Carrier spec → Value spec :=
  semanticFold spec (Value spec) Value.node

theorem reify_interpret {spec : Spec} (value : Value spec) :
    reify spec value.interpret = value :=
  (fold_interpret (Value spec) Value.node value).trans value.fold_constructors

theorem interpret_injective {spec : Spec} {left right : Value spec}
    (equal : left.interpret = right.interpret) : left = right :=
  (reify_interpret left).symm.trans
    ((congrArg (reify spec) equal).trans (reify_interpret right))

end

end KanonMeta.MuFinitary
