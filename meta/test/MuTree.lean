/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import test.GeneratedMuTree

/-!
Certificates for the extracted binary family and its closed constructor
fragment. The asymmetric observation detects child order and omission.
Exact raw-body equality identifies the supported mirror template; it does
not establish a translation theorem for general recursive definitions.
-/

namespace KanonMeta.MuTree.Tests

noncomputable section

theorem checked_declaration : Generated.declaration = expectedDeclaration := rfl

def sample : Value := .fork .leaf (.fork .leaf .leaf)

def checkedSample : CheckedValue Generated.declaration := ⟨checked_declaration, sample⟩

theorem generated_sample_encoder : Generated.sample = sample.encode := rfl

theorem generated_sample_decoder : decode Generated.sample = .ok sample :=
  decode_encode sample

theorem generated_sample_checked_decoder :
    checkedDecode Generated.declaration checked_declaration Generated.sample =
      .ok checkedSample := rfl

theorem generated_sample_metadata :
    Generated.sampleType = familyType ∧ Generated.sampleRecArg = none ∧
      Generated.samplePartial = false ∧ Generated.sampleReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem generated_mirror_encoder : Generated.mirror = mirrorBody "mirror" := rfl

theorem generated_mirror_metadata :
    Generated.mirrorType = mirrorType ∧ Generated.mirrorRecArg = some 0 ∧
      Generated.mirrorPartial = false ∧ Generated.mirrorReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

def weighted : Carrier → Nat := semanticFold Nat 1 (fun left right => 2 * left + 3 * right)

theorem generated_sample_observation : weighted checkedSample.interpret = 17 :=
  fold_interpret Nat 1 (fun left right => 2 * left + 3 * right) sample

theorem generated_mirror_observation :
    weighted (semanticMirror checkedSample.interpret) = 13 :=
  (congrArg weighted (mirror_interpret sample)).trans
    (fold_interpret Nat 1 (fun left right => 2 * left + 3 * right) sample.mirror)

theorem mirror_changes_observation :
    semanticMirror checkedSample.interpret ≠ checkedSample.interpret :=
  fun equal => (show (13 : Nat) ≠ 17 from of_decide_eq_true rfl)
    (generated_mirror_observation.symm.trans
      ((congrArg weighted equal).trans generated_sample_observation))

theorem leaf_fork_separation :
    Value.leaf.interpret ≠ (Value.fork .leaf .leaf).interpret :=
  interpret_separates (fun equal => Value.noConfusion equal)

theorem reject_wrong_shape : decode (.intro (.SColl 0) (.actor "leaf") []) =
    .error .wrongShape := rfl

theorem reject_wrong_family : decode (.intro (.SMu "Other" []) (.actor "leaf") []) =
    .error (.wrongFamily "Other") := rfl

theorem reject_indices : decode (.intro (.SMu "Tree" [.lit 0]) (.actor "leaf") []) =
    .error (.indexedFamily 1) := rfl

theorem reject_point_address : decode (.intro family (.apt .many (.lit 0)) []) =
    .error .nonConstructorAddress := rfl

theorem reject_leg_address : decode (.intro family (.aleg 0) []) =
    .error .nonConstructorAddress := rfl

theorem reject_unknown_constructor : decode (.intro family (.actor "other") []) =
    .error (.wrongAddress "other") := rfl

theorem reject_leaf_argument :
    decode (.intro family (.actor "leaf") [Value.leaf.encode]) =
      .error (.wrongArity "leaf" 0 1) := rfl

theorem reject_missing_fork_arguments :
    decode (.intro family (.actor "fork") []) = .error (.wrongArity "fork" 2 0) := rfl

theorem reject_missing_second_child :
    decode (.intro family (.actor "fork") [Value.leaf.encode]) =
      .error (.wrongArity "fork" 2 1) := rfl

theorem reject_extra_fork_argument :
    decode (.intro family (.actor "fork")
      [Value.leaf.encode, Value.leaf.encode, Value.leaf.encode]) =
      .error (.wrongArity "fork" 2 3) := rfl

theorem reject_unsupported_left_child :
    decode (.intro family (.actor "fork") [.var 0, Value.leaf.encode]) =
      .error .unsupportedTerm := rfl

theorem reject_unsupported_right_child :
    decode (.intro family (.actor "fork") [Value.leaf.encode, .var 0]) =
      .error .unsupportedTerm := rfl

theorem reject_nested_wrong_family :
    decode (.intro family (.actor "fork")
      [Value.leaf.encode, .intro (.SMu "Other" []) (.actor "leaf") []]) =
      .error (.wrongFamily "Other") := rfl

theorem reject_general_definition : decode Generated.mirror = .error .unsupportedTerm := rfl

#print axioms checked_declaration
#print axioms generated_sample_decoder
#print axioms generated_sample_checked_decoder
#print axioms generated_sample_observation
#print axioms generated_mirror_encoder
#print axioms generated_mirror_observation
#print axioms mirror_changes_observation
#print axioms leaf_fork_separation

end

end KanonMeta.MuTree.Tests
