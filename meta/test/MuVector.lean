/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import test.GeneratedMuVector

/-!
Certificates for the extracted indexed vector family, its closed constructor
fragment, and its fixed dependent-copy template. The weighted observation
distinguishes retained payloads and their order at the same length.
-/

namespace KanonMeta.MuVector.Tests

noncomputable section

theorem checked_natural_declaration :
    Generated.naturalDeclaration = MuNat.expectedDeclaration := rfl

theorem checked_declaration : Generated.declaration = expectedDeclaration := rfl

def sample : Value 2 := .cons 17 (.cons 25 .nil)

def checkedSample : CheckedValue Generated.naturalDeclaration Generated.declaration 2 :=
  ⟨⟨checked_natural_declaration, checked_declaration⟩, sample⟩

theorem generated_sample_encoder : Generated.sample = sample.encode := rfl

theorem generated_sample_decoder : decode 2 Generated.sample = .ok sample :=
  decode_encode sample

theorem generated_sample_checked_decoder :
    checkedDecode Generated.naturalDeclaration Generated.declaration
      ⟨checked_natural_declaration, checked_declaration⟩ 2 Generated.sample =
      .ok checkedSample := rfl

theorem generated_sample_metadata :
    Generated.sampleType = .lan (family (indexTerm 2)) (.sec (.SColl 0) []) ∧
      Generated.sampleRecArg = none ∧ Generated.samplePartial = false ∧
      Generated.sampleReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem generated_copy_encoder : Generated.copy = copyBody "copy" := rfl

theorem generated_copy_metadata :
    Generated.copyType = copyType ∧ Generated.copyRecArg = some 1 ∧
      Generated.copyPartial = false ∧ Generated.copyReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

def weightedAlgebra : Initiality.Algebra (VectorConstruction.polynomial Nat) where
  Carrier := fun (_n) => Nat
  roll := fun shape => match shape with
    | .inl .nil => fun (_children) => 0
    | .inr (.cons (_n) payload) => fun children => payload + 2 * children PUnit.unit

def weighted {n : Nat} (value : (VectorConstruction.recursive Nat).Carrier n) : Nat :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).map value

theorem weighted_nil : weighted VectorConstruction.nil = 0 :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).comm
    (.inl .nil) (fun position => nomatch position)

theorem weighted_cons {n : Nat} (payload : Nat)
    (tail : (VectorConstruction.recursive Nat).Carrier n) :
    weighted (VectorConstruction.cons payload tail) = payload + 2 * weighted tail :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).comm
    (.inr (.cons n payload)) (fun (_position) => tail)

theorem generated_sample_observation : weighted sample.interpret = 67 :=
  (weighted_cons 17 (VectorConstruction.cons 25 VectorConstruction.nil)).trans
    (congrArg (fun value => 17 + 2 * value)
      ((weighted_cons 25 VectorConstruction.nil).trans
        (congrArg (fun value => 25 + 2 * value) weighted_nil)))

theorem generated_copy_observation :
    weighted (semanticCopy sample.interpret) = 67 :=
  (congrArg weighted (semanticCopy_eq sample.interpret)).trans
    generated_sample_observation

theorem generated_copy_interpretation :
    semanticCopy sample.interpret = sample.copy.interpret := copy_interpret sample

def reversed : Value 2 := .cons 25 (.cons 17 .nil)

theorem reversed_observation : weighted reversed.interpret = 59 :=
  (weighted_cons 25 (VectorConstruction.cons 17 VectorConstruction.nil)).trans
    (congrArg (fun value => 25 + 2 * value)
      ((weighted_cons 17 VectorConstruction.nil).trans
        (congrArg (fun value => 17 + 2 * value) weighted_nil)))

theorem payload_order_separation : sample.interpret ≠ reversed.interpret :=
  fun equal => (show (67 : Nat) ≠ 59 from of_decide_eq_true rfl)
    (generated_sample_observation.symm.trans
      ((congrArg weighted equal).trans reversed_observation))

def zeroed : Value 2 := .cons 0 (.cons 0 .nil)

theorem zeroed_observation : weighted zeroed.interpret = 0 :=
  (weighted_cons 0 (VectorConstruction.cons 0 VectorConstruction.nil)).trans
    (congrArg (fun value => 0 + 2 * value)
      ((weighted_cons 0 VectorConstruction.nil).trans
        (congrArg (fun value => 0 + 2 * value) weighted_nil)))

theorem payload_erasure_separation : sample.interpret ≠ zeroed.interpret :=
  fun equal => (show (67 : Nat) ≠ 0 from of_decide_eq_true rfl)
    (generated_sample_observation.symm.trans
      ((congrArg weighted equal).trans zeroed_observation))

theorem reject_wrong_shape :
    decode 0 (.intro (.SColl 0) (.actor "vz") []) = .error .wrongShape := rfl

theorem reject_wrong_family :
    decode 0 (.intro (.SMu "Other" [indexTerm 0]) (.actor "vz") []) =
      .error (.wrongFamily "Other") := rfl

theorem reject_missing_index :
    decode 0 (.intro (.SMu "V" []) (.actor "vz") []) = .error (.indexArity 0) := rfl

theorem reject_extra_index :
    decode 0 (.intro (.SMu "V" [indexTerm 0, indexTerm 0]) (.actor "vz") []) =
      .error (.indexArity 2) := rfl

theorem reject_open_result_index :
    decode 0 (.intro (family (.var 0)) (.actor "vz") []) =
      .error (.invalidIndex .unsupportedTerm) := rfl

theorem reject_literal_result_index :
    decode 0 (.intro (family (.lit 0)) (.actor "vz") []) =
      .error (.invalidIndex .unsupportedTerm) := rfl

theorem reject_wrong_result_index :
    decode 2 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 1, .lit 17, (.cons 25 .nil : Value 1).encode]) =
      .error (.indexMismatch 2 1) := rfl

theorem reject_wrong_erased_predecessor :
    decode 2 (.intro (family (indexTerm 2)) (.actor "vs")
      [indexTerm 0, .lit 17, (.cons 25 .nil : Value 1).encode]) =
      .error (.indexMismatch 1 0) := rfl

theorem reject_open_erased_predecessor :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [.var 0, .lit 17, (Value.nil).encode]) =
      .error (.invalidIndex .unsupportedTerm) := rfl

theorem reject_wrong_child_length :
    decode 2 (.intro (family (indexTerm 2)) (.actor "vs")
      [indexTerm 1, .lit 17, (Value.nil).encode]) =
      .error (.indexMismatch 1 0) := rfl

theorem reject_nil_at_successor :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vz") []) =
      .error (.constructorIndexMismatch "vz" 1) := rfl

theorem reject_cons_at_zero :
    decode 0 (.intro (family (indexTerm 0)) (.actor "vs")
      [indexTerm 0, .lit 17, (Value.nil).encode]) =
      .error (.constructorIndexMismatch "vs" 0) := rfl

theorem reject_point_address :
    decode 0 (.intro (family (indexTerm 0)) (.apt .many (.lit 0)) []) =
      .error .nonConstructorAddress := rfl

theorem reject_leg_address :
    decode 0 (.intro (family (indexTerm 0)) (.aleg 0) []) =
      .error .nonConstructorAddress := rfl

theorem reject_unknown_constructor :
    decode 0 (.intro (family (indexTerm 0)) (.actor "other") []) =
      .error (.wrongAddress "other") := rfl

theorem reject_nil_argument :
    decode 0 (.intro (family (indexTerm 0)) (.actor "vz") [.lit 0]) =
      .error (.wrongArity "vz" 0 1) := rfl

theorem reject_missing_cons_arguments :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs") []) =
      .error (.wrongArity "vs" 3 0) := rfl

theorem reject_missing_child :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs") [indexTerm 0, .lit 17]) =
      .error (.wrongArity "vs" 3 2) := rfl

theorem reject_extra_cons_argument :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 0, .lit 17, (Value.nil).encode, .lit 0]) =
      .error (.wrongArity "vs" 3 4) := rfl

theorem reject_open_payload :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 0, .var 0, (Value.nil).encode]) = .error .unsupportedPayload := rfl

theorem reject_constructor_payload :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 0, indexTerm 17, (Value.nil).encode]) = .error .unsupportedPayload := rfl

theorem reject_unsupported_child :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 0, .lit 17, .var 0]) = .error .unsupportedTerm := rfl

theorem reject_nested_wrong_family :
    decode 1 (.intro (family (indexTerm 1)) (.actor "vs")
      [indexTerm 0, .lit 17, .intro (.SMu "Other" [indexTerm 0]) (.actor "vz") []]) =
      .error (.wrongFamily "Other") := rfl

theorem reject_open_value : decode 0 (.var 0) = .error .unsupportedTerm := rfl

theorem reject_general_definition : decode 2 Generated.copy = .error .unsupportedTerm := rfl

#print axioms checked_natural_declaration
#print axioms checked_declaration
#print axioms generated_sample_decoder
#print axioms generated_sample_checked_decoder
#print axioms generated_copy_encoder
#print axioms generated_copy_interpretation
#print axioms generated_sample_observation
#print axioms generated_copy_observation
#print axioms payload_order_separation
#print axioms payload_erasure_separation

end

end KanonMeta.MuVector.Tests
