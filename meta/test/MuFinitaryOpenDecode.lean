/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryOpenDecode
import test.MuFinitaryDecode

namespace KanonMeta.MuFinitary.Tests.OpenDecode

open OpenTerm

def reencoded (specification : Spec) (context : Nat) (term : Term) :
    Except OpenDecodeError Term :=
  (openDecode specification context term).map (fun decoded => decoded.value.encode)

def variables {specification : Spec} {context : Nat} : OpenTerm specification context → List Nat
  | .var index => [index.val]
  | .node _ctor children => (List.ofFn (fun pos => variables (children pos))).flatten

def decodedVariables (specification : Spec) (context : Nat) (term : Term) :
    Except OpenDecodeError (List Nat) :=
  (openDecode specification context term).map (fun decoded => variables decoded.value)

def nested : Term := .intro (family "Grove") (.actor "crown")
  [.var 1, .intro (family "Grove") (.actor "join") [.var 0, .var 1],
   .intro (family "Grove") (.actor "shoot") [.var 0]]

theorem nested_reencoding : reencoded spec 2 nested = .ok nested := rfl

theorem nested_repeated_variables :
    decodedVariables spec 2 nested = .ok [1, 0, 1, 0] := rfl

theorem first_variable : reencoded spec 3 (.var 0) = .ok (.var 0) := rfl

theorem last_variable : reencoded spec 3 (.var 2) = .ok (.var 2) := rfl

theorem variable_at_bound : reencoded spec 3 (.var 3) =
    .error (.outOfScopeVariable 3 3) := rfl

theorem variable_above_bound : reencoded spec 3 (.var 9) =
    .error (.outOfScopeVariable 9 3) := rfl

theorem empty_context_rejects_variable : reencoded spec 0 (.var 0) =
    .error (.outOfScopeVariable 0 0) := rfl

theorem variable_diagnostics_differ :
    openDecode spec 0 (.var 0) = .error (.outOfScopeVariable 0 0) ∧
      decode spec (.var 0) = .error .unsupportedTerm := ⟨rfl, rfl⟩

theorem empty_context_accepts_closed :
    reencoded spec 0 Generated.sample = .ok Generated.sample := rfl

theorem extended_context_accepts_closed :
    reencoded spec 7 Generated.sample = .ok Generated.sample := rfl

theorem nested_scope_failure : reencoded spec 1 nested =
    .error (.outOfScopeVariable 1 1) := rfl

theorem late_scope_failure : reencoded spec 2
    (.intro (family "Grove") (.actor "crown") [.var 0, .var 1, .var 2]) =
      .error (.outOfScopeVariable 2 2) := rfl

theorem every_open_term_roundtrips {context : Nat} (value : OpenTerm spec context) :
    openDecode spec context value.encode = .ok ⟨value, rfl⟩ :=
  openDecode_encode checked.valid value

theorem certificate_is_exact {context : Nat} {term : Term}
    (decoded : OpenDecoded spec context term)
    (accepted : openDecode spec context term = .ok decoded) :
    term = decoded.value.encode :=
  openDecode_sound spec context term decoded.value
    (congrArg (Except.map OpenDecoded.value) accepted)

theorem acceptance_retains_syntax {context : Nat} {term : Term}
    (value : OpenTerm spec context)
    (accepted : (openDecode spec context term).map OpenDecoded.value = .ok value) :
    term = value.encode := openDecode_sound spec context term value accepted

theorem zero_context_agrees_with_closed (term : Term) :
    (∃ decoded, openDecode spec 0 term = .ok decoded) ↔
      ∃ decoded, decode spec term = .ok decoded :=
  openDecode_zero_iff checked.valid term

theorem acceptance_is_exact (context : Nat) (term : Term) :
    (∃ decoded, openDecode spec context term = .ok decoded) ↔
      ∃ value : OpenTerm spec context, term = value.encode :=
  openDecode_accepts_iff checked.valid context term

def topConstructor (specification : Spec) (context : Nat) (term : Term) :
    Except OpenDecodeError (Option Nat) :=
  (openDecode specification context term).map (fun decoded =>
    match decoded.value with
    | .var (_index) => none
    | .node ctor (_children) => some ctor.val)

theorem original_constructor_position : topConstructor spec 2 nested = .ok (some 3) := rfl

theorem reordered_constructor_position :
    topConstructor Decode.reordered 2 nested = .ok (some 0) := rfl

theorem reordered_children :
    decodedVariables Decode.reordered 2 nested = .ok [1, 0, 1, 0] := rfl

def renamed : Term := .intro (family "Branch") (.actor "fork") [.var 1, .var 0]

theorem renamed_reencoding : reencoded Decode.named 2 renamed = .ok renamed := rfl

theorem renamed_order : decodedVariables Decode.named 2 renamed = .ok [1, 0] := rfl

def five : Term := .intro (family "Five") (.actor "branch")
  [.var 4, .var 2, .var 0, .var 3, .var 1]

theorem arbitrary_arity_reencoding : reencoded Decode.fiveSpec 5 five = .ok five := rfl

theorem arbitrary_arity_order :
    decodedVariables Decode.fiveSpec 5 five = .ok [4, 2, 0, 3, 1] := rfl

theorem empty_signature_accepts_variable :
    reencoded emptySpec 1 (.var 0) = .ok (.var 0) := rfl

theorem reject_shape : reencoded spec 2
    (.intro (.SColl 0) (.actor "bud") []) = .error (.closed .wrongShape) := rfl

theorem reject_function_shape : reencoded spec 2
    (.intro (.SPi .many "x" (.univ 0)) (.actor "bud") []) =
      .error (.closed .wrongShape) := rfl

theorem reject_family : reencoded spec 2
    (.intro (family "Other") (.actor "bud") []) =
      .error (.closed (.wrongFamily "Other")) := rfl

theorem reject_indices : reencoded spec 2
    (.intro (.SMu "Grove" [.var 0]) (.actor "bud") []) =
      .error (.closed (.indexedFamily 1)) := rfl

theorem reject_leg_address : reencoded spec 2
    (.intro (family "Grove") (.aleg 0) []) =
      .error (.closed .nonConstructorAddress) := rfl

theorem reject_point_address : reencoded spec 2
    (.intro (family "Grove") (.apt .many (.var 0)) []) =
      .error (.closed .nonConstructorAddress) := rfl

theorem reject_unknown_constructor : reencoded spec 2
    (.intro (family "Grove") (.actor "absent") []) =
      .error (.closed (.wrongAddress "absent")) := rfl

theorem reject_empty_signature_constructor : reencoded emptySpec 2
    (.intro (family "Empty") (.actor "absent") []) =
      .error (.closed (.wrongAddress "absent")) := rfl

theorem reject_nullary_argument : reencoded spec 2
    (.intro (family "Grove") (.actor "bud") [.var 0]) =
      .error (.closed (.wrongArity "bud" 0 1)) := rfl

theorem reject_missing_argument : reencoded spec 2
    (.intro (family "Grove") (.actor "join") [.var 1]) =
      .error (.closed (.wrongArity "join" 2 1)) := rfl

theorem reject_extra_argument : reencoded spec 2
    (.intro (family "Grove") (.actor "join") [.var 0, .var 1, .var 0]) =
      .error (.closed (.wrongArity "join" 2 3)) := rfl

theorem reject_nested_family : reencoded spec 2
    (.intro (family "Grove") (.actor "shoot")
      [.intro (family "Other") (.actor "bud") []]) =
      .error (.closed (.wrongFamily "Other")) := rfl

theorem reject_late_unsupported_child : reencoded spec 2
    (.intro (family "Grove") (.actor "crown") [.var 0, .var 1, .global "alias"]) =
      .error (.closed .unsupportedTerm) := rfl

theorem child_error_precedes_arity : reencoded spec 2
    (.intro (family "Grove") (.actor "join") [.global "x"]) =
      .error (.closed .unsupportedTerm) := rfl

theorem reject_universe : reencoded spec 2 (.univ 0) =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_lan : reencoded spec 2 (familyType "Grove") =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_ran : reencoded spec 2 (.ran (family "Grove") (.sec (.SColl 0) [])) =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_elimination : reencoded spec 2
    (.elim (family "Grove") (.var 0) .many none []) =
      .error (.closed .unsupportedTerm) := rfl

theorem reject_section : reencoded spec 2 (.sec (family "Grove") []) =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_projection : reencoded spec 2
    (.out (family "Grove") (.actor "bud") (.var 0)) =
      .error (.closed .unsupportedTerm) := rfl

theorem reject_let : reencoded spec 2
    (.letIn "x" (familyType "Grove") (.var 0) (.var 0)) =
      .error (.closed .unsupportedTerm) := rfl

theorem reject_annotation : reencoded spec 2 (.ann (.var 0) (familyType "Grove")) =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_global : reencoded spec 2 (.global "sample") =
    .error (.closed .unsupportedTerm) := rfl

theorem reject_literal : reencoded spec 2 (.lit 0) =
    .error (.closed .unsupportedTerm) := rfl

#print axioms nested_reencoding
#print axioms nested_repeated_variables
#print axioms arbitrary_arity_order
#print axioms reordered_constructor_position
#print axioms late_scope_failure
#print axioms every_open_term_roundtrips
#print axioms acceptance_retains_syntax
#print axioms zero_context_agrees_with_closed

end KanonMeta.MuFinitary.Tests.OpenDecode
