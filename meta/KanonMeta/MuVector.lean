/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuNat
import KanonMeta.VectorConstruction

/-!
A bounded bridge for the checked length-indexed family V over the fixed
natural-number declaration N. Raw values retain both the family result index
and the erased predecessor argument of vs. Only closed canonical constructor
indices and Nat literal payloads are admitted by the total decoder.

Interpretation uses VectorConstruction's proved initial indexed algebra.
These results establish the semantics of this explicit fragment, not the
correctness of the general checker or arbitrary compiled recursive programs.
-/

namespace KanonMeta.MuVector

open Initiality

abbrev Declaration := MuNat.Declaration

def indexValue : Nat → MuNat.Value
  | 0 => .zero
  | n + 1 => .succ (indexValue n)

def indexTerm (n : Nat) : Term := (indexValue n).encode

def family (index : Term) : Shape := .SMu "V" [index]

def familyType (index : Term) : Term := .lan (family index) (.sec (.SColl 0) [])

def expectedDeclaration : Declaration where
  name := "V"
  params := []
  indices := [(.zero, "i", MuNat.familyType)]
  level := 1
  status := .complete ["vz", "vs"]
  constructors := [
    { name := "vz", args := [], resultIndices := [indexTerm 0],
      fullArity := 0, selfRecursive := false },
    { name := "vs", args := [(.zero, "i", MuNat.familyType),
        (.many, "_", .global "Nat"), (.many, "_", familyType (.var 1))],
      resultIndices := [.intro MuNat.family (.actor "succ") [.var 2]],
      fullArity := 3, selfRecursive := true }]
  positive := true

/-- Both exported declarations must match every field of the fixed signature. -/
def Supported (natural vector : Declaration) : Prop :=
  natural = MuNat.expectedDeclaration ∧ vector = expectedDeclaration

/-- The length index is intrinsic and payloads are natural numbers. -/
inductive Value : Nat → Type where
  | nil : Value 0
  | cons {n : Nat} (payload : Nat) (tail : Value n) : Value (n + 1)
  deriving DecidableEq, Repr

def Value.encode : {n : Nat} → Value n → Term
  | 0, .nil => .intro (family (indexTerm 0)) (.actor "vz") []
  | n + 1, .cons payload tail =>
      .intro (family (indexTerm (n + 1))) (.actor "vs")
        [indexTerm n, .lit payload, tail.encode]

inductive DecodeError where
  | wrongShape
  | wrongFamily (name : String)
  | indexArity (actual : Nat)
  | invalidIndex (error : MuNat.DecodeError)
  | indexMismatch (expected actual : Nat)
  | nonConstructorAddress
  | wrongAddress (name : String)
  | wrongArity (name : String) (expected actual : Nat)
  | constructorIndexMismatch (name : String) (index : Nat)
  | unsupportedPayload
  | unsupportedTerm
  deriving DecidableEq, Repr

private def decodedIndex : Except MuNat.DecodeError MuNat.Value → Except DecodeError Nat
  | .ok value => .ok value.toNat
  | .error error => .error (.invalidIndex error)

/-- Decode an index using exactly the closed N constructor fragment. -/
def decodeIndex (term : Term) : Except DecodeError Nat := decodedIndex (MuNat.decode term)

theorem indexValue_toNat : ∀ n, (indexValue n).toNat = n
  | 0 => rfl
  | n + 1 => congrArg Nat.succ (indexValue_toNat n)

theorem decodeIndex_indexTerm (n : Nat) : decodeIndex (indexTerm n) = .ok n :=
  (congrArg decodedIndex (MuNat.decode_encode (indexValue n))).trans
    (congrArg Except.ok (indexValue_toNat n))

private def checkedIndex (expected : Nat) : Except DecodeError Nat → Except DecodeError Unit
  | .ok actual => if actual = expected then .ok () else .error (.indexMismatch expected actual)
  | .error error => .error error

def checkIndex (expected : Nat) (term : Term) : Except DecodeError Unit :=
  checkedIndex expected (decodeIndex term)

theorem checkIndex_indexTerm (n : Nat) : checkIndex n (indexTerm n) = .ok () :=
  (congrArg (checkedIndex n) (decodeIndex_indexTerm n)).trans (if_pos rfl)

private def afterIndex {X : Type} : Except DecodeError Unit → Except DecodeError X →
    Except DecodeError X
  | .ok (), result => result
  | .error error, (_result) => .error error

private def decodedCons {n : Nat} (payload : Nat) : Except DecodeError (Value n) →
    Except DecodeError (Value (n + 1))
  | .ok tail => .ok (.cons payload tail)
  | .error error => .error error

/-- Validate the result index, erased predecessor, literal payload and tail index. -/
def decode (n : Nat) : Term → Except DecodeError (Value n)
  | .intro (.SMu name indices) address args =>
    if name = "V" then
      match indices with
      | [index] => afterIndex (checkIndex n index)
          (match address with
          | .actor ctor =>
            match n with
            | 0 =>
              if ctor = "vz" then
                match args with
                | [] => .ok .nil
                | _head :: (_tail) => .error (.wrongArity ctor 0 args.length)
              else if ctor = "vs" then .error (.constructorIndexMismatch ctor 0)
              else .error (.wrongAddress ctor)
            | predecessor + 1 =>
              if ctor = "vs" then
                match args with
                | [length, payload, tail] =>
                  afterIndex (checkIndex predecessor length)
                    (match payload with
                    | .lit value => decodedCons value (decode predecessor tail)
                    | .var (_) => .error .unsupportedPayload
                    | .univ (_) => .error .unsupportedPayload
                    | .lan _ (_) => .error .unsupportedPayload
                    | .ran _ (_) => .error .unsupportedPayload
                    | .intro _ _ (_) => .error .unsupportedPayload
                    | .elim _ _ _ _ (_) => .error .unsupportedPayload
                    | .sec _ (_) => .error .unsupportedPayload
                    | .out _ _ (_) => .error .unsupportedPayload
                    | .letIn _ _ _ (_) => .error .unsupportedPayload
                    | .ann _ (_) => .error .unsupportedPayload
                    | .global (_) => .error .unsupportedPayload)
                | [] => .error (.wrongArity ctor 3 0)
                | [_first] => .error (.wrongArity ctor 3 1)
                | [_first, _second] => .error (.wrongArity ctor 3 2)
                | _first :: _second :: _third :: _fourth :: (_rest) =>
                    .error (.wrongArity ctor 3 args.length)
              else if ctor = "vz" then
                .error (.constructorIndexMismatch ctor (predecessor + 1))
              else .error (.wrongAddress ctor)
          | .apt _ (_) => .error .nonConstructorAddress
          | .aleg (_) => .error .nonConstructorAddress)
      | [] => .error (.indexArity 0)
      | _first :: _second :: (_rest) => .error (.indexArity indices.length)
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
termination_by structural n

theorem decode_encode : ∀ {n : Nat} (value : Value n), decode n value.encode = .ok value
  | 0, .nil => congrArg (fun result => afterIndex result (.ok Value.nil))
      (checkIndex_indexTerm 0)
  | n + 1, .cons payload tail =>
      (congrArg (fun result => afterIndex result
        (afterIndex (checkIndex n (indexTerm n)) (decodedCons payload (decode n tail.encode))))
        (checkIndex_indexTerm (n + 1))).trans
      ((congrArg (fun result => afterIndex result (decodedCons payload (decode n tail.encode)))
        (checkIndex_indexTerm n)).trans
        (congrArg (decodedCons payload) (decode_encode tail)))

theorem encode_injective {n : Nat} {left right : Value n}
    (h : left.encode = right.encode) : left = right :=
  Except.ok.inj ((decode_encode left).symm.trans
    ((congrArg (decode n) h).trans (decode_encode right)))

structure CheckedValue (natural vector : Declaration) (n : Nat) where
  supported : Supported natural vector
  value : Value n

def checkedDecode (natural vector : Declaration) (supported : Supported natural vector)
    (n : Nat) (term : Term) : Except DecodeError (CheckedValue natural vector n) :=
  match decode n term with
  | .ok value => .ok ⟨supported, value⟩
  | .error error => .error error

def Value.fold {X : Nat → Type} (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) : {n : Nat} → Value n → X n
  | 0, .nil => nil
  | _n + 1, .cons payload tail => cons payload (tail.fold nil cons)

theorem Value.fold_nil {X : Nat → Type} (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) :
    Value.nil.fold nil cons = nil := rfl

theorem Value.fold_cons {X : Nat → Type} (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) {n : Nat}
    (payload : Nat) (tail : Value n) :
    (Value.cons payload tail).fold nil cons = cons payload (tail.fold nil cons) := rfl

theorem Value.fold_constructors : ∀ {n : Nat} (value : Value n),
    value.fold Value.nil Value.cons = value
  | 0, .nil => rfl
  | _n + 1, .cons payload tail => congrArg (Value.cons payload) (Value.fold_constructors tail)

abbrev Carrier (n : Nat) := (VectorConstruction.recursive Nat).Carrier n

def Value.interpret {n : Nat} (value : Value n) : Carrier n :=
  value.fold VectorConstruction.nil VectorConstruction.cons

def CheckedValue.interpret {natural vector : Declaration} {n : Nat}
    (value : CheckedValue natural vector n) : Carrier n := value.value.interpret

theorem interpret_nil : Value.nil.interpret = VectorConstruction.nil := rfl

theorem interpret_cons {n : Nat} (payload : Nat) (tail : Value n) :
    (Value.cons payload tail).interpret = VectorConstruction.cons payload tail.interpret := rfl

def algebra (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) :
    Algebra (VectorConstruction.polynomial Nat) where
  Carrier := X
  roll := fun shape xs => match shape with
    | .inl .nil => nil
    | .inr (.cons _n payload) => cons payload (xs PUnit.unit)

/-- The fold is supplied by constructed initiality of the indexed carrier. -/
def semanticFold (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) {n : Nat} (value : Carrier n) : X n :=
  ((VectorConstruction.recursiveInitial Nat).fold (algebra X nil cons)).map value

theorem semanticFold_nil (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) :
    semanticFold X nil cons VectorConstruction.nil = nil :=
  ((VectorConstruction.recursiveInitial Nat).fold (algebra X nil cons)).comm
    (.inl .nil) (fun pos => nomatch pos)

theorem semanticFold_cons (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) {n : Nat}
    (payload : Nat) (tail : Carrier n) :
    semanticFold X nil cons (VectorConstruction.cons payload tail) =
      cons payload (semanticFold X nil cons tail) :=
  ((VectorConstruction.recursiveInitial Nat).fold (algebra X nil cons)).comm
    (.inr (.cons n payload)) (fun (_pos) => tail)

theorem fold_interpret (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1)) : ∀ {n : Nat} (value : Value n),
    semanticFold X nil cons value.interpret = value.fold nil cons
  | 0, .nil => semanticFold_nil X nil cons
  | _n + 1, .cons payload tail =>
      (semanticFold_cons X nil cons payload tail.interpret).trans
        (congrArg (cons payload) (fold_interpret X nil cons tail))

theorem semanticFold_unique (X : Nat → Type) (nil : X 0)
    (cons : {n : Nat} → Nat → X n → X (n + 1))
    (other : Hom (VectorConstruction.recursive Nat) (algebra X nil cons))
    {n : Nat} (value : Carrier n) : other.map value = semanticFold X nil cons value :=
  (VectorConstruction.recursiveInitial Nat).unique (algebra X nil cons) other
    ((VectorConstruction.recursiveInitial Nat).fold (algebra X nil cons)) value

def reify {n : Nat} : Carrier n → Value n := semanticFold Value .nil .cons

theorem reify_interpret {n : Nat} (value : Value n) : reify value.interpret = value :=
  (fold_interpret Value .nil .cons value).trans (Value.fold_constructors value)

theorem interpret_injective {n : Nat} {left right : Value n}
    (h : left.interpret = right.interpret) : left = right :=
  (reify_interpret left).symm.trans
    ((congrArg reify h).trans (reify_interpret right))

theorem interpret_separates {n : Nat} {left right : Value n} (h : left ≠ right) :
    left.interpret ≠ right.interpret := fun equal => h (interpret_injective equal)

def Value.copy {n : Nat} (value : Value n) : Value n := value.fold .nil .cons

theorem Value.copy_eq {n : Nat} (value : Value n) : value.copy = value :=
  value.fold_constructors

def semanticCopy {n : Nat} (value : Carrier n) : Carrier n := VectorConstruction.copy value

theorem semanticCopy_eq {n : Nat} (value : Carrier n) : semanticCopy value = value :=
  VectorConstruction.copy_eq value

theorem copy_interpret {n : Nat} (value : Value n) :
    semanticCopy value.interpret = value.copy.interpret :=
  (VectorConstruction.copy_eq value.interpret).trans
    (congrArg Value.interpret value.copy_eq.symm)

/-- Fixed raw copy template retains the erased length application and motive. -/
def copyBody (name : String) : Term :=
  .sec (.SPi .zero "i" MuNat.familyType)
    [.mk [(.zero, "i")]
      (.sec (.SPi .many "v" (familyType (.var 0)))
        [.mk [(.many, "v")]
          (.elim (family (.var 1)) (.var 0) .one
            (some (.mk (some "V") ["j"] "x" (familyType (.var 1))))
            [(.actor "vz", .mk [] Value.nil.encode),
             (.actor "vs", .mk [(.zero, "j"), (.many, "a"), (.many, "w")]
               (.intro (family (.intro MuNat.family (.actor "succ") [.var 2]))
                 (.actor "vs") [.var 2, .var 1,
                   .out (.SPi .many "_" (familyType (.var 2))) (.apt .many (.var 0))
                     (.out (.SPi .zero "i" MuNat.familyType) (.apt .zero (.var 2))
                       (.global name))]))])])]

def copyType : Term :=
  .ran (.SPi .zero "i" MuNat.familyType)
    (.ran (.SPi .many "_" (familyType (.var 0))) (familyType (.var 1)))

end KanonMeta.MuVector
