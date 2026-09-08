/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import test.GeneratedMuNat

/-!
The generated data comes from checking test/meta/mu-nat-bridge.kan. These
certificates identify its complete declaration, closed value and restricted
fold body with the reusable fragment. Semantic observations then use proved
initiality. This is neither a proof of the OCaml checker nor a correctness
theorem for its general recursive-definition translation or runtime.
-/

namespace KanonMeta.MuNat.Tests

theorem checked_declaration : Generated.declaration.Supported := rfl

def three : Value := .succ (.succ (.succ .zero))

def checkedThree : CheckedValue Generated.declaration := ⟨checked_declaration, three⟩

theorem generated_three_encoder : Generated.three = three.encode := rfl

theorem generated_three_decoder : decode Generated.three = .ok three :=
  decode_encode three

theorem generated_three_checked_decoder :
    checkedDecode Generated.declaration checked_declaration Generated.three =
      .ok checkedThree := rfl

theorem generated_three_metadata :
    Generated.threeType = familyType ∧ Generated.threeRecArg = none ∧
      Generated.threePartial = false ∧ Generated.threeReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem generated_three_observation : observe checkedThree.interpret = 3 :=
  observe_interpret three

/-- The exported body is identified as the restricted fold program before
its structural semantics is used. -/
theorem generated_double_encoder :
    Generated.double = doubleProgram.encode "double" := rfl

theorem generated_double_metadata :
    Generated.doubleType = FoldProgram.type ∧ Generated.doubleRecArg = some 0 ∧
      Generated.doublePartial = false ∧ Generated.doubleReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem generated_double_three_observation :
    observe (doubleProgram.interpret checkedThree.interpret) = 6 :=
  (congrArg observe (doubleProgram.run_interpret three)).trans
    (observe_interpret (doubleProgram.run three))

theorem generated_double_three_syntax :
    decode (doubleProgram.run three).encode = .ok (.succ (.succ (.succ (.succ (.succ (.succ .zero)))))) :=
  decode_encode (doubleProgram.run three)

theorem generated_case_predecessor :
    semanticCase Nat 0 observe checkedThree.interpret = 2 :=
  (semanticCase_succ Nat 0 observe (Value.succ (.succ .zero)).interpret).trans
    (observe_interpret (.succ (.succ .zero)))

theorem zero_successor_separation :
    Value.zero.interpret ≠ (Value.succ .zero).interpret :=
  interpret_separates (fun h => Value.noConfusion h)

theorem reject_wrong_shape : decode (.intro (.SColl 0) (.actor "zero") []) =
    .error .wrongShape := rfl

theorem reject_wrong_family : decode (.intro (.SMu "Other" []) (.actor "zero") []) =
    .error (.wrongFamily "Other") := rfl

theorem reject_indices : decode (.intro (.SMu "N" [.lit 0]) (.actor "zero") []) =
    .error (.indexedFamily 1) := rfl

theorem reject_point_address : decode (.intro family (.apt .many (.lit 0)) []) =
    .error .nonConstructorAddress := rfl

theorem reject_leg_address : decode (.intro family (.aleg 0) []) =
    .error .nonConstructorAddress := rfl

theorem reject_unknown_constructor : decode (.intro family (.actor "other") []) =
    .error (.wrongAddress "other") := rfl

theorem reject_zero_argument :
    decode (.intro family (.actor "zero") [Value.zero.encode]) =
      .error (.wrongArity "zero" 0 1) := rfl

theorem reject_missing_successor_argument :
    decode (.intro family (.actor "succ") []) = .error (.wrongArity "succ" 1 0) := rfl

theorem reject_extra_successor_argument :
    decode (.intro family (.actor "succ") [Value.zero.encode, Value.zero.encode]) =
      .error (.wrongArity "succ" 1 2) := rfl

theorem reject_unsupported_child :
    decode (.intro family (.actor "succ") [.var 0]) = .error .unsupportedTerm := rfl

theorem reject_nested_wrong_family :
    decode (.intro family (.actor "succ") [.intro (.SMu "Other" []) (.actor "zero") []]) =
      .error (.wrongFamily "Other") := rfl

theorem reject_general_definition : decode Generated.double = .error .unsupportedTerm := rfl

#print axioms checked_declaration
#print axioms generated_three_decoder
#print axioms generated_three_checked_decoder
#print axioms generated_three_observation
#print axioms generated_double_encoder
#print axioms generated_double_three_observation
#print axioms generated_case_predecessor
#print axioms zero_successor_separation

end KanonMeta.MuNat.Tests
