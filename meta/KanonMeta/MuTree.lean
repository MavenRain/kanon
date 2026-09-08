/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuNat
import KanonMeta.FinitaryConstruction

/-!
A bounded bridge for the checked declaration `mu Tree : Type 0` with
`leaf : Tree` and `fork : Tree -> Tree -> Tree`. Its declaration witness
retains every exported field and its decoder accepts closed constructor trees.

The semantic carrier is the quotient of finite initial stages constructed by
FinitaryConstruction. Both ordered recursive positions are retained. The
mirror operation has explicit structural semantics and a fixed raw template;
these results do not assert correctness of arbitrary compiled definitions.
-/

namespace KanonMeta.MuTree

open Initiality

abbrev CtorStatus := MuNat.CtorStatus
abbrev Constructor := MuNat.Constructor
abbrev Declaration := MuNat.Declaration

def family : Shape := .SMu "Tree" []

def familyType : Term := .lan family (.sec (.SColl 0) [])

/-- Exact checked declaration data for the binary Tree fragment. -/
def expectedDeclaration : Declaration where
  name := "Tree"
  params := []
  indices := []
  level := 1
  status := .complete ["leaf", "fork"]
  constructors := [
    { name := "leaf", args := [], resultIndices := [],
      fullArity := 0, selfRecursive := false },
    { name := "fork", args := [(.many, "_", familyType), (.many, "_", familyType)],
      resultIndices := [], fullArity := 2, selfRecursive := true }]
  positive := true

/-- Exact data equality with the exported declaration, not a trusted positivity or checker premise. -/
def Supported (declaration : Declaration) : Prop := declaration = expectedDeclaration

inductive Value where
  | leaf
  | fork (left right : Value)
  deriving DecidableEq, Repr

def Value.encode : Value → Term
  | .leaf => .intro family (.actor "leaf") []
  | .fork left right => .intro family (.actor "fork") [left.encode, right.encode]

inductive DecodeError where
  | wrongShape
  | wrongFamily (name : String)
  | indexedFamily (count : Nat)
  | nonConstructorAddress
  | wrongAddress (name : String)
  | wrongArity (name : String) (expected actual : Nat)
  | unsupportedTerm
  deriving DecidableEq, Repr

private def decodedFork : Except DecodeError Value → Except DecodeError Value →
    Except DecodeError Value
  | .error error, .error (_rightError) => .error error
  | .error error, .ok (_right) => .error error
  | .ok (_left), .error error => .error error
  | .ok left, .ok right => .ok (.fork left right)

/-- Total validation of closed Tree introductions, including both children. -/
def decode : Term → Except DecodeError Value
  | .intro (.SMu name indices) address args =>
    if name = "Tree" then
      match indices with
      | [] => match address with
        | .actor ctor =>
          if ctor = "leaf" then
            match args with
            | [] => .ok .leaf
            | _head :: (_tail) => .error (.wrongArity ctor 0 args.length)
          else if ctor = "fork" then
            match args with
            | [left, right] => decodedFork (decode left) (decode right)
            | [] => .error (.wrongArity ctor 2 0)
            | [_child] => .error (.wrongArity ctor 2 1)
            | _first :: _second :: _third :: (_rest) =>
                .error (.wrongArity ctor 2 args.length)
          else .error (.wrongAddress ctor)
        | .apt _ (_) => .error .nonConstructorAddress
        | .aleg (_) => .error .nonConstructorAddress
      | _head :: (_tail) => .error (.indexedFamily indices.length)
    else .error (.wrongFamily name)
  | .intro (.SPi _ _ _) _ (_) => .error .wrongShape
  | .intro (.SColl _) _ (_) => .error .wrongShape
  | .var (_) => .error .unsupportedTerm
  | .univ (_) => .error .unsupportedTerm
  | .lan _ (_) => .error .unsupportedTerm
  | .ran _ (_) => .error .unsupportedTerm
  | .elim _ _ _ _ (_) => .error .unsupportedTerm
  | .sec _ (_) => .error .unsupportedTerm
  | .out _ _ (_) => .error .unsupportedTerm
  | .letIn _ _ _ (_) => .error .unsupportedTerm
  | .ann _ (_) => .error .unsupportedTerm
  | .global (_) => .error .unsupportedTerm
  | .lit (_) => .error .unsupportedTerm
termination_by structural term => term

theorem decode_encode : ∀ value : Value, decode value.encode = .ok value
  | .leaf => rfl
  | .fork left right =>
    (congrArg (fun result => decodedFork result (decode right.encode))
      (decode_encode left)).trans
      (congrArg (decodedFork (.ok left)) (decode_encode right))

theorem encode_injective {left right : Value} (h : left.encode = right.encode) :
    left = right :=
  Except.ok.inj ((decode_encode left).symm.trans
    ((congrArg decode h).trans (decode_encode right)))

/-- A constructor value carries exact equality with the exported declaration. -/
structure CheckedValue (declaration : Declaration) where
  supported : Supported declaration
  value : Value

def checkedDecode (declaration : Declaration) (supported : Supported declaration)
    (term : Term) : Except DecodeError (CheckedValue declaration) :=
  match decode term with
  | .ok value => .ok ⟨supported, value⟩
  | .error error => .error error

def Value.fold {X : Type} (leaf : X) (fork : X → X → X) : Value → X
  | .leaf => leaf
  | .fork left right => fork (left.fold leaf fork) (right.fold leaf fork)

theorem Value.fold_leaf {X : Type} (leaf : X) (fork : X → X → X) :
    Value.leaf.fold leaf fork = leaf := rfl

theorem Value.fold_fork {X : Type} (leaf : X) (fork : X → X → X)
    (left right : Value) :
    (Value.fork left right).fold leaf fork =
      fork (left.fold leaf fork) (right.fold leaf fork) := rfl

theorem Value.fold_constructors : ∀ value : Value,
    value.fold Value.leaf Value.fork = value
  | .leaf => rfl
  | .fork left right =>
    (congrArg (fun child => Value.fork child (right.fold Value.leaf Value.fork))
      (Value.fold_constructors left)).trans
      (congrArg (Value.fork left) (Value.fold_constructors right))

inductive TreeShape where
  | leaf
  | fork

def treeSignature : FinitaryConstruction.Signature Unit where
  Shape := fun (_index) => TreeShape
  arity := fun shape => match shape with
    | .leaf => 0
    | .fork => 2
  child := fun (_shape) (_position) => ()

abbrev treePolynomial := treeSignature.polynomial

noncomputable def recursive : Algebra treePolynomial :=
  FinitaryConstruction.recursive treeSignature

noncomputable def recursiveInitial : Initial recursive :=
  FinitaryConstruction.recursiveInitial treeSignature

/-- The carrier is the constructed quotient, not the syntax Value type. -/
abbrev Carrier := recursive.Carrier ()

noncomputable section

def semanticLeaf : Carrier := recursive.roll .leaf (fun pos => Fin.elim0 pos.down)

def semanticFork (left right : Carrier) : Carrier :=
  recursive.roll .fork
    (fun pos => Fin.cases (motive := fun (_pos : Fin 2) => Carrier)
      left (fun (_pos) => right) pos.down)

def Value.interpret (value : Value) : Carrier :=
  value.fold semanticLeaf semanticFork

def CheckedValue.interpret {declaration : Declaration}
    (value : CheckedValue declaration) : Carrier := value.value.interpret

theorem interpret_leaf : Value.leaf.interpret = semanticLeaf := rfl

theorem interpret_fork (left right : Value) :
    (Value.fork left right).interpret = semanticFork left.interpret right.interpret := rfl

def algebra (X : Type) (leaf : X) (fork : X → X → X) : Algebra treePolynomial where
  Carrier := fun (_index) => X
  roll := fun shape xs => match shape with
    | .leaf => leaf
    | .fork => fork (xs ⟨(0 : Fin 2)⟩) (xs ⟨(1 : Fin 2)⟩)

/-- The chosen fold uses the initiality proved for the finite-stage quotient. -/
def semanticFold (X : Type) (leaf : X) (fork : X → X → X) (value : Carrier) : X :=
  (recursiveInitial.fold (algebra X leaf fork)).map value

theorem semanticFold_leaf (X : Type) (leaf : X) (fork : X → X → X) :
    semanticFold X leaf fork semanticLeaf = leaf :=
  (recursiveInitial.fold (algebra X leaf fork)).comm
    .leaf (fun pos => Fin.elim0 pos.down)

theorem semanticFold_fork (X : Type) (leaf : X) (fork : X → X → X)
    (left right : Carrier) :
    semanticFold X leaf fork (semanticFork left right) =
      fork (semanticFold X leaf fork left) (semanticFold X leaf fork right) :=
  (recursiveInitial.fold (algebra X leaf fork)).comm
    .fork (fun pos => Fin.cases (motive := fun (_pos : Fin 2) => Carrier)
      left (fun (_pos) => right) pos.down)

theorem fold_interpret (X : Type) (leaf : X) (fork : X → X → X) :
    ∀ value : Value,
      semanticFold X leaf fork value.interpret = value.fold leaf fork
  | .leaf => semanticFold_leaf X leaf fork
  | .fork left right => (semanticFold_fork X leaf fork left.interpret right.interpret).trans
    ((congrArg (fun child => fork child (semanticFold X leaf fork right.interpret))
      (fold_interpret X leaf fork left)).trans
      (congrArg (fork (left.fold leaf fork)) (fold_interpret X leaf fork right)))

theorem semanticFold_unique (X : Type) (leaf : X) (fork : X → X → X)
    (other : Hom recursive (algebra X leaf fork)) (value : Carrier) :
    other.map value = semanticFold X leaf fork value :=
  recursiveInitial.unique (algebra X leaf fork) other
    (recursiveInitial.fold (algebra X leaf fork)) value

/-- Observing with constructor syntax recovers each finite interpreted value. -/
def reify : Carrier → Value := semanticFold Value .leaf .fork

theorem reify_interpret (value : Value) : reify value.interpret = value :=
  (fold_interpret Value .leaf .fork value).trans (Value.fold_constructors value)

theorem interpret_injective {left right : Value}
    (h : left.interpret = right.interpret) : left = right :=
  (reify_interpret left).symm.trans
    ((congrArg reify h).trans (reify_interpret right))

theorem interpret_separates {left right : Value} (h : left ≠ right) :
    left.interpret ≠ right.interpret := fun equal => h (interpret_injective equal)

def Value.mirror : Value → Value
  | .leaf => .leaf
  | .fork left right => .fork right.mirror left.mirror

def semanticMirror : Carrier → Carrier :=
  semanticFold Carrier semanticLeaf (fun left right => semanticFork right left)

theorem semanticMirror_leaf : semanticMirror semanticLeaf = semanticLeaf :=
  semanticFold_leaf Carrier semanticLeaf (fun left right => semanticFork right left)

theorem semanticMirror_fork (left right : Carrier) :
    semanticMirror (semanticFork left right) =
      semanticFork (semanticMirror right) (semanticMirror left) :=
  semanticFold_fork Carrier semanticLeaf (fun left right => semanticFork right left) left right

theorem mirror_interpret : ∀ value : Value,
    semanticMirror value.interpret = value.mirror.interpret
  | .leaf => semanticMirror_leaf
  | .fork left right => (semanticMirror_fork left.interpret right.interpret).trans
    ((congrArg (fun child => semanticFork child (semanticMirror left.interpret))
      (mirror_interpret right)).trans
      (congrArg (semanticFork right.mirror.interpret) (mirror_interpret left)))

end

/-- Fixed raw recursive mirror template with the checked binder names and order. -/
def mirrorBody (name : String) : Term :=
  .sec (.SPi .many "t" familyType)
    [.mk [(.many, "t")]
      (.elim family (.var 0) .one
        (some (.mk (some "Tree") [] "x" familyType))
        [(.actor "leaf", .mk [] Value.leaf.encode),
         (.actor "fork", .mk [(.many, "l"), (.many, "r")]
           (.intro family (.actor "fork")
             [.out (.SPi .many "_" familyType) (.apt .many (.var 0)) (.global name),
              .out (.SPi .many "_" familyType) (.apt .many (.var 1)) (.global name)]))])]

def mirrorType : Term := .ran (.SPi .many "_" familyType) familyType

end KanonMeta.MuTree
