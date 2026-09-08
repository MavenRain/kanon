import KanonMeta

set_option autoImplicit false

namespace FinitaryClient

open KanonMeta KanonMeta.MuFinitary

def spec : Spec :=
  ⟨"ClientTerm", [⟨"point", []⟩, ⟨"splice", ["left", "middle", "right"]⟩]⟩

theorem valid_spec : spec.Valid := of_decide_eq_true rfl

def checked : Validated spec.declaration := ⟨spec, valid_spec, rfl⟩

theorem accepted : (match validate spec.declaration with
    | .ok (_checked) => true
    | .error (_error) => false) = true := rfl

theorem supported : Supported spec.declaration := checked.supported

theorem rejects_wrong_arity : (match validate
    { spec.declaration with constructors := [
      { name := "point", args := [], resultIndices := [],
        fullArity := 1, selfRecursive := false }] } with
    | .ok (_checked) => none
    | .error error => some error) = some (.fullArity "point" 0 1) := rfl

def point : Value spec := .node (0 : Fin 2) (fun pos => Fin.elim0 pos)

def splice (left middle right : Value spec) : Value spec :=
  .node (1 : Fin 2) (fun pos => Fin.cases left (Fin.cases middle (fun (_pos) => right)) pos)

def sample : Value spec := splice point point (splice point point point)

def count (ctor : spec.Constructor) (children : Fin (spec.arity ctor) → Nat) : Nat :=
  1 + (List.ofFn children).foldl Nat.add 0

noncomputable section

theorem observation : semanticFold spec Nat count sample.interpret = 7 :=
  fold_interpret Nat count sample

theorem reconstruction : reify spec sample.interpret = sample := reify_interpret sample

theorem interpretation_injective (left right : Value spec)
    (equal : left.interpret = right.interpret) : left = right := interpret_injective equal

end

end FinitaryClient
