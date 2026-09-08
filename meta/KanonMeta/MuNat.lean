/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.Syntax
import KanonMeta.NatConstruction

/-!
A bounded bridge for the checked declaration `mu N : Type 0` with the
constructors `zero : N` and `succ : N -> N`. The declaration witness covers
every exported field, and values encode as actual raw `SMu` introductions.
The decoder accepts closed constructor trees only. Variables, applications,
eliminators and general recursive definitions are outside its domain.

The semantic carrier and its initiality come from NatConstruction's proved
chain colimit construction. Lean naturals are only an observation algebra.
The fold and case laws describe explicit semantic operations. They do not
assert correctness of the OCaml checker or arbitrary compiled folds.
-/

namespace KanonMeta.MuNat

open Initiality

inductive CtorStatus where
  | provisional
  | builtin
  | complete (names : List String)

/-- The fields exported from one checked constructor declaration. -/
structure Constructor where
  name : String
  args : List (Quantity × String × Term)
  resultIndices : List Term
  fullArity : Nat
  selfRecursive : Bool

/-- The complete checked declaration data used by this bounded bridge. -/
structure Declaration where
  name : String
  params : List (Quantity × String × Term)
  indices : List (Quantity × String × Term)
  level : Nat
  status : CtorStatus
  constructors : List Constructor
  positive : Bool

def family : Shape := .SMu "N" []

def familyType : Term := .lan family (.sec (.SColl 0) [])

def expectedDeclaration : Declaration where
  name := "N"
  params := []
  indices := []
  level := 1
  status := .complete ["zero", "succ"]
  constructors := [
    { name := "zero", args := [], resultIndices := [],
      fullArity := 0, selfRecursive := false },
    { name := "succ", args := [(.many, "_", familyType)], resultIndices := [],
      fullArity := 1, selfRecursive := true }]
  positive := true

/-- Exact data equality, not a trusted positivity or checker premise. -/
def Declaration.Supported (declaration : Declaration) : Prop :=
  declaration = expectedDeclaration

/-- Intrinsically typed closed constructor values of this one declaration. -/
inductive Value where
  | zero
  | succ (child : Value)
  deriving DecidableEq, Repr

def Value.encode : Value → Term
  | .zero => .intro family (.actor "zero") []
  | .succ child => .intro family (.actor "succ") [child.encode]

inductive DecodeError where
  | wrongShape
  | wrongFamily (name : String)
  | indexedFamily (count : Nat)
  | nonConstructorAddress
  | wrongAddress (name : String)
  | wrongArity (name : String) (expected actual : Nat)
  | unsupportedTerm
  deriving DecidableEq, Repr

private def decodedSucc : Except DecodeError Value → Except DecodeError Value
  | .ok child => .ok (.succ child)
  | .error error => .error error

/-- Total validation of the raw closed constructor fragment. -/
def decode : Term → Except DecodeError Value
  | .intro (.SMu name indices) address args =>
    if name = "N" then
      match indices with
      | [] => match address with
        | .actor ctor =>
          if ctor = "zero" then
            match args with
            | [] => .ok .zero
            | _head :: (_tail) => .error (.wrongArity ctor 0 args.length)
          else if ctor = "succ" then
            match args with
            | [child] => decodedSucc (decode child)
            | [] => .error (.wrongArity ctor 1 0)
            | _first :: _second :: (_rest) => .error (.wrongArity ctor 1 args.length)
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
  | .zero => rfl
  | .succ child => congrArg decodedSucc (decode_encode child)

theorem encode_injective {left right : Value} (h : left.encode = right.encode) :
    left = right :=
  Except.ok.inj ((decode_encode left).symm.trans
    ((congrArg decode h).trans (decode_encode right)))

/-- A fragment value carries an exact witness for the exported declaration. -/
structure CheckedValue (declaration : Declaration) where
  supported : declaration.Supported
  value : Value

def checkedDecode (declaration : Declaration) (supported : declaration.Supported)
    (term : Term) : Except DecodeError (CheckedValue declaration) :=
  match decode term with
  | .ok value => .ok ⟨supported, value⟩
  | .error error => .error error

def Value.fold {X : Type} (zero : X) (succ : X → X) : Value → X
  | .zero => zero
  | .succ child => succ (child.fold zero succ)

theorem Value.fold_zero {X : Type} (zero : X) (succ : X → X) :
    Value.zero.fold zero succ = zero := rfl

theorem Value.fold_succ {X : Type} (zero : X) (succ : X → X) (child : Value) :
    child.succ.fold zero succ = succ (child.fold zero succ) := rfl

abbrev Carrier := NatConstruction.recursive.Carrier ()

def Value.interpret (value : Value) : Carrier :=
  value.fold NatConstruction.zero NatConstruction.succ

def CheckedValue.interpret {declaration : Declaration}
    (value : CheckedValue declaration) : Carrier := value.value.interpret

theorem interpret_zero : Value.zero.interpret = NatConstruction.zero := rfl

theorem interpret_succ (child : Value) :
    child.succ.interpret = NatConstruction.succ child.interpret := rfl

def algebra (X : Type) (zero : X) (succ : X → X) :
    Algebra NatConstruction.natPolynomial where
  Carrier := fun (_i) => X
  roll := fun shape xs => match shape with
    | .zero => zero
    | .succ => succ (xs ())

/-- Its chosen morphism uses proved initiality, with no initiality parameter. -/
def semanticFold (X : Type) (zero : X) (succ : X → X) (value : Carrier) : X :=
  (NatConstruction.recursiveInitial.fold (algebra X zero succ)).map value

theorem semanticFold_zero (X : Type) (zero : X) (succ : X → X) :
    semanticFold X zero succ NatConstruction.zero = zero :=
  (NatConstruction.recursiveInitial.fold (algebra X zero succ)).comm
    .zero (fun pos => nomatch pos)

theorem semanticFold_succ (X : Type) (zero : X) (succ : X → X) (child : Carrier) :
    semanticFold X zero succ (NatConstruction.succ child) =
      succ (semanticFold X zero succ child) :=
  (NatConstruction.recursiveInitial.fold (algebra X zero succ)).comm
    .succ (fun (_pos) => child)

/-- Structural folding of decoded constructor syntax agrees with the unique
algebra morphism out of the constructed semantic carrier. -/
theorem fold_interpret (X : Type) (zero : X) (succ : X → X) :
    ∀ value : Value,
      semanticFold X zero succ value.interpret = value.fold zero succ
  | .zero => semanticFold_zero X zero succ
  | .succ child => (semanticFold_succ X zero succ child.interpret).trans
    (congrArg succ (fold_interpret X zero succ child))

theorem semanticFold_unique (X : Type) (zero : X) (succ : X → X)
    (other : Hom NatConstruction.recursive (algebra X zero succ)) (value : Carrier) :
    other.map value = semanticFold X zero succ value :=
  NatConstruction.recursiveInitial.unique (algebra X zero succ) other
    (NatConstruction.recursiveInitial.fold (algebra X zero succ)) value

def caseDisplayed (X : Type) (zero : X) (succ : Carrier → X) :
    Displayed NatConstruction.recursive where
  Fibre := fun (_value) => X
  step := fun shape xs (_ih) => match shape with
    | .zero => zero
    | .succ => succ (xs ())

/-- One-level case analysis is derived from the proved dependent eliminator. -/
def semanticCase (X : Type) (zero : X) (succ : Carrier → X) (value : Carrier) : X :=
  elim NatConstruction.recursiveInitial (caseDisplayed X zero succ) value

theorem semanticCase_zero (X : Type) (zero : X) (succ : Carrier → X) :
    semanticCase X zero succ NatConstruction.zero = zero :=
  elim_beta NatConstruction.recursiveInitial (caseDisplayed X zero succ)
    .zero (fun pos => nomatch pos)

theorem semanticCase_succ (X : Type) (zero : X) (succ : Carrier → X)
    (child : Carrier) :
    semanticCase X zero succ (NatConstruction.succ child) = succ child :=
  elim_beta NatConstruction.recursiveInitial (caseDisplayed X zero succ)
    .succ (fun (_pos) => child)

def Value.toNat (value : Value) : Nat := value.fold 0 Nat.succ

def observe : Carrier → Nat := semanticFold Nat 0 Nat.succ

theorem observe_zero : observe NatConstruction.zero = 0 :=
  semanticFold_zero Nat 0 Nat.succ

theorem observe_succ (child : Carrier) :
    observe (NatConstruction.succ child) = Nat.succ (observe child) :=
  semanticFold_succ Nat 0 Nat.succ child

theorem observe_interpret (value : Value) : observe value.interpret = value.toNat :=
  fold_interpret Nat 0 Nat.succ value

theorem Value.toNat_injective : ∀ left right : Value,
    left.toNat = right.toNat → left = right
  | .zero, .zero, (_) => rfl
  | .zero, .succ _, h => Nat.noConfusion h
  | .succ _, .zero, h => Nat.noConfusion h
  | .succ left, .succ right, h =>
    congrArg Value.succ (Value.toNat_injective left right (Nat.succ.inj h))

/-- Distinct finite raw constructor values remain distinct in the quotient
carrier; its quotient does not collapse the checked syntax fragment. -/
theorem interpret_injective {left right : Value}
    (h : left.interpret = right.interpret) : left = right :=
  Value.toNat_injective left right ((observe_interpret left).symm.trans
    ((congrArg observe h).trans (observe_interpret right)))

theorem interpret_separates {left right : Value} (h : left ≠ right) :
    left.interpret ≠ right.interpret := fun equal => h (interpret_injective equal)

def Value.double : Value → Value
  | .zero => .zero
  | .succ child => .succ (.succ child.double)

def semanticDouble : Carrier → Carrier :=
  semanticFold Carrier NatConstruction.zero
    (fun child => NatConstruction.succ (NatConstruction.succ child))

theorem semanticDouble_zero : semanticDouble NatConstruction.zero = NatConstruction.zero :=
  semanticFold_zero Carrier NatConstruction.zero
    (fun child => NatConstruction.succ (NatConstruction.succ child))

theorem semanticDouble_succ (child : Carrier) :
    semanticDouble (NatConstruction.succ child) =
      NatConstruction.succ (NatConstruction.succ (semanticDouble child)) :=
  semanticFold_succ Carrier NatConstruction.zero
    (fun child => NatConstruction.succ (NatConstruction.succ child)) child

theorem double_interpret : ∀ value : Value,
    semanticDouble value.interpret = value.double.interpret
  | .zero => semanticDouble_zero
  | .succ child => (semanticDouble_succ child.interpret).trans
    (congrArg (fun value => NatConstruction.succ (NatConstruction.succ value))
      (double_interpret child))

/-- A restricted, intrinsically typed structural fold from N to N. Its base
branch is closed and its successor branch wraps the recursive result in a
fixed number of successors. The raw encoder names the recursive definition
explicitly; interpretation gives this fragment's structural fold semantics. -/
structure FoldProgram where
  base : Value
  successors : Nat

def wrapValue : Nat → Value → Value
  | 0, value => value
  | n + 1, value => .succ (wrapValue n value)

def wrapSemantic : Nat → Carrier → Carrier
  | 0, value => value
  | n + 1, value => NatConstruction.succ (wrapSemantic n value)

def wrapRaw : Nat → Term → Term
  | 0, term => term
  | n + 1, term => .intro family (.actor "succ") [wrapRaw n term]

theorem wrap_encode : ∀ n (value : Value),
    (wrapValue n value).encode = wrapRaw n value.encode
  | 0, _value => rfl
  | n + 1, value =>
    congrArg (fun term => Term.intro family (.actor "succ") [term])
      (wrap_encode n value)

theorem wrap_interpret : ∀ n (value : Value),
    wrapSemantic n value.interpret = (wrapValue n value).interpret
  | 0, _value => rfl
  | n + 1, value => congrArg NatConstruction.succ (wrap_interpret n value)

def FoldProgram.run (program : FoldProgram) (value : Value) : Value :=
  value.fold program.base (wrapValue program.successors)

def FoldProgram.interpret (program : FoldProgram) : Carrier → Carrier :=
  semanticFold Carrier program.base.interpret (wrapSemantic program.successors)

def FoldProgram.encode (program : FoldProgram) (name : String) : Term :=
  .sec (.SPi .many "n" familyType)
    [.mk [(.many, "n")]
      (.elim family (.var 0) .one
        (some (.mk (some "N") [] "x" familyType))
        [(.actor "zero", .mk [] program.base.encode),
         (.actor "succ", .mk [(.many, "m")]
           (wrapRaw program.successors
             (.out (.SPi .many "_" familyType) (.apt .many (.var 0)) (.global name))))])]

def FoldProgram.type : Term := .ran (.SPi .many "_" familyType) familyType

theorem FoldProgram.run_zero (program : FoldProgram) : program.run .zero = program.base := rfl

theorem FoldProgram.run_succ (program : FoldProgram) (child : Value) :
    program.run child.succ = wrapValue program.successors (program.run child) := rfl

theorem FoldProgram.interpret_zero (program : FoldProgram) :
    program.interpret NatConstruction.zero = program.base.interpret :=
  semanticFold_zero Carrier program.base.interpret (wrapSemantic program.successors)

theorem FoldProgram.interpret_succ (program : FoldProgram) (child : Carrier) :
    program.interpret (NatConstruction.succ child) =
      wrapSemantic program.successors (program.interpret child) :=
  semanticFold_succ Carrier program.base.interpret (wrapSemantic program.successors) child

/-- The restricted syntax fragment's structural evaluation agrees with the
fold obtained from constructed initiality. Exact raw-export equality is
checked separately; this theorem does not translate general definitions. -/
theorem FoldProgram.run_interpret (program : FoldProgram) : ∀ value : Value,
    program.interpret value.interpret = (program.run value).interpret
  | .zero => program.interpret_zero
  | .succ child => (program.interpret_succ child.interpret).trans
    ((congrArg (wrapSemantic program.successors) (program.run_interpret child)).trans
      (wrap_interpret program.successors (program.run child)))

def doubleProgram : FoldProgram := ⟨.zero, 2⟩

theorem doubleProgram_semantics : doubleProgram.interpret = semanticDouble := rfl

end KanonMeta.MuNat
