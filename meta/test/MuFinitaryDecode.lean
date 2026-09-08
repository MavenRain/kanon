/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryDecode
import test.MuFinitary

namespace KanonMeta.MuFinitary.Tests.Decode

def observation (term : Term) : Except DecodeError Nat :=
  (decode spec term).map (fun decoded => decoded.value.fold weight)

def reencoded (specification : Spec) (term : Term) : Except DecodeError Term :=
  (decode specification term).map (fun decoded => decoded.value.encode)

theorem generated_observation : observation Generated.sample = .ok 48 := rfl

theorem generated_reencoding : reencoded spec Generated.sample = .ok Generated.sample := rfl

theorem generated_checked_observation :
    (checkedDecode checked Generated.sample).map
      (fun decoded => decoded.value.fold weight) = .ok 48 := rfl

theorem certificate_preserved (decoded : Decoded spec Generated.sample) :
    (decoded.checkedValue checked).checked = checked := rfl

theorem decoded_semantic_observation (decoded : Decoded spec Generated.sample) :
    semanticFold spec Nat weight decoded.interpret = decoded.value.fold weight :=
  decoded_fold_interpret decoded Nat weight

theorem every_value_roundtrips (value : Value spec) :
    decode spec value.encode = .ok ⟨value, rfl⟩ := decode_encode checked.valid value

theorem encoding_preserves_values (left right : Value spec)
    (equal : left.encode = right.encode) : left = right :=
  encode_injective checked.valid equal

theorem decode_nullary : observation bud.encode = .ok 1 := rfl

theorem decode_unary : observation (shoot bud).encode = .ok 2 := rfl

theorem decode_binary : observation (join bud (shoot bud)).encode = .ok 8 := rfl

theorem decode_ternary : observation sample.encode = .ok 48 := rfl

theorem decode_swapped : observation swapped.encode = .ok 27 := rfl

theorem reject_shape : observation
    (.intro (.SColl 0) (.actor "bud") []) = .error .wrongShape := rfl

theorem reject_function_shape : observation
    (.intro (.SPi .many "x" (.univ 0)) (.actor "bud") []) = .error .wrongShape := rfl

theorem reject_foreign_family : observation
    (.intro (.SMu "Other" []) (.actor "bud") []) = .error (.wrongFamily "Other") := rfl

theorem reject_nonempty_indices : observation
    (.intro (.SMu "Grove" [.lit 0]) (.actor "bud") []) =
      .error (.indexedFamily 1) := rfl

theorem reject_leg_address : observation
    (.intro (family "Grove") (.aleg 0) []) = .error .nonConstructorAddress := rfl

theorem reject_point_address : observation
    (.intro (family "Grove") (.apt .many bud.encode) []) =
      .error .nonConstructorAddress := rfl

theorem reject_unknown_constructor : observation
    (.intro (family "Grove") (.actor "absent") []) =
      .error (.wrongAddress "absent") := rfl

theorem reject_nullary_argument : observation
    (.intro (family "Grove") (.actor "bud") [bud.encode]) =
      .error (.wrongArity "bud" 0 1) := rfl

theorem reject_missing_argument : observation
    (.intro (family "Grove") (.actor "shoot") []) =
      .error (.wrongArity "shoot" 1 0) := rfl

theorem reject_extra_argument : observation
    (.intro (family "Grove") (.actor "join") [bud.encode, bud.encode, bud.encode]) =
      .error (.wrongArity "join" 2 3) := rfl

theorem reject_late_child : observation
    (.intro (family "Grove") (.actor "crown") [bud.encode, bud.encode, .var 0]) =
      .error .unsupportedTerm := rfl

theorem reject_nested_family : observation
    (.intro (family "Grove") (.actor "shoot")
      [.intro (family "Other") (.actor "bud") []]) =
      .error (.wrongFamily "Other") := rfl

theorem reject_variable : observation (.var 0) = .error .unsupportedTerm := rfl

theorem reject_universe : observation (.univ 0) = .error .unsupportedTerm := rfl

theorem reject_lan : observation (familyType "Grove") = .error .unsupportedTerm := rfl

theorem reject_ran : observation
    (.ran (family "Grove") (.sec (.SColl 0) [])) = .error .unsupportedTerm := rfl

theorem reject_elimination : observation
    (.elim (family "Grove") bud.encode .many none []) = .error .unsupportedTerm := rfl

theorem reject_section : observation
    (.sec (family "Grove") []) = .error .unsupportedTerm := rfl

theorem reject_projection : observation
    (.out (family "Grove") (.actor "bud") bud.encode) = .error .unsupportedTerm := rfl

theorem reject_let : observation
    (.letIn "x" (familyType "Grove") bud.encode (.var 0)) = .error .unsupportedTerm := rfl

theorem reject_annotation : observation
    (.ann bud.encode (familyType "Grove")) = .error .unsupportedTerm := rfl

theorem reject_global_alias : observation (.global "sample") = .error .unsupportedTerm := rfl

theorem reject_literal : observation (.lit 0) = .error .unsupportedTerm := rfl

theorem reject_empty_signature : reencoded emptySpec
    (.intro (family "Empty") (.actor "absent") []) =
      .error (.wrongAddress "absent") := rfl

def rightChoice : Term := .intro (family "Choice") (.actor "right") []

theorem second_nullary_constructor : reencoded nullarySpec rightChoice = .ok rightChoice := rfl

def reordered : Spec := ⟨"Grove", [⟨"crown", ["a", "b", "c"]⟩,
  ⟨"bud", []⟩, ⟨"join", ["left", "right"]⟩, ⟨"shoot", ["child"]⟩]⟩

theorem reordered_reencoding :
    reencoded reordered Generated.sample = .ok Generated.sample := rfl

def topConstructor (specification : Spec) (term : Term) : Except DecodeError Nat :=
  (decode specification term).map (fun decoded =>
    match decoded.value with
    | .node ctor (_children) => ctor.val)

theorem original_constructor_position : topConstructor spec Generated.sample = .ok 3 := rfl

theorem reordered_constructor_position :
    topConstructor reordered Generated.sample = .ok 0 := rfl

def named : Spec := ⟨"Branch", [⟨"tip", []⟩, ⟨"fork", ["left", "right"]⟩]⟩

def namedTerm : Term := .intro (family "Branch") (.actor "fork")
  [.intro (family "Branch") (.actor "tip") [],
   .intro (family "Branch") (.actor "tip") []]

theorem renamed_reencoding : reencoded named namedTerm = .ok namedTerm := rfl

def fiveSpec : Spec := ⟨"Five", [⟨"leaf", []⟩, ⟨"branch", ["a", "b", "c", "d", "e"]⟩]⟩

def fiveLeaf : Term := .intro (family "Five") (.actor "leaf") []

def fiveTerm : Term := .intro (family "Five") (.actor "branch")
  [fiveLeaf, fiveLeaf, fiveLeaf, fiveLeaf, fiveLeaf]

theorem arbitrary_arity : reencoded fiveSpec fiveTerm = .ok fiveTerm := rfl

#print axioms generated_observation
#print axioms generated_reencoding
#print axioms reordered_constructor_position
#print axioms reject_late_child
#print axioms arbitrary_arity
#print axioms every_value_roundtrips
#print axioms encoding_preserves_values

end KanonMeta.MuFinitary.Tests.Decode
