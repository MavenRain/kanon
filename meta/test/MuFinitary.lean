/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import test.GeneratedMuFinitary

namespace KanonMeta.MuFinitary.Tests

def spec : Spec := ⟨"Grove", [⟨"bud", []⟩, ⟨"shoot", ["_"]⟩,
  ⟨"join", ["_", "_"]⟩, ⟨"crown", ["_", "_", "_"]⟩]⟩

def checked : Validated Generated.declaration :=
  ⟨spec, of_decide_eq_true rfl, rfl⟩

theorem checked_declaration : Generated.declaration = spec.declaration := rfl

theorem generated_validation : validate Generated.declaration = .ok checked := rfl

theorem generated_supported : Supported Generated.declaration :=
  validate_sound Generated.declaration checked generated_validation

def bud : Value spec := .node ⟨0, of_decide_eq_true rfl⟩ Fin.elim0

def shoot (child : Value spec) : Value spec :=
  .node ⟨1, of_decide_eq_true rfl⟩ (fun (_pos) => child)

def join (left right : Value spec) : Value spec :=
  .node ⟨2, of_decide_eq_true rfl⟩ (Fin.cases left (fun (_pos) => right))

def crown (left middle right : Value spec) : Value spec :=
  .node ⟨3, of_decide_eq_true rfl⟩
    (Fin.cases left (Fin.cases middle (fun (_pos) => right)))

def sample : Value spec := crown bud (shoot bud) (join bud (shoot bud))

def checkedSample : CheckedValue Generated.declaration := ⟨checked, sample⟩

theorem generated_sample_encoder : Generated.sample = sample.encode := rfl

theorem generated_sample_metadata :
    Generated.sampleType = familyType "Grove" ∧ Generated.sampleRecArg = none ∧
      Generated.samplePartial = false ∧ Generated.sampleReducible = true :=
  ⟨rfl, rfl, rfl, rfl⟩

def weight : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor : Fin 4 => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 1)
    (Fin.cases (fun children => 1 + children (0 : Fin 1))
      (Fin.cases (fun children => 2 * children (0 : Fin 2) + 3 * children (1 : Fin 2))
        (Fin.cases (fun children => 2 * children (0 : Fin 3) + 3 * children (1 : Fin 3) +
          5 * children (2 : Fin 3))
          (fun index => Fin.elim0 index))))

theorem sample_structural_observation : sample.fold weight = 48 := rfl

noncomputable def observe : Carrier spec → Nat := semanticFold spec Nat weight

theorem generated_sample_observation : observe checkedSample.interpret = 48 :=
  fold_interpret Nat weight sample

def swapped : Value spec := crown (join bud (shoot bud)) (shoot bud) bud

theorem swapped_observation : observe swapped.interpret = 27 :=
  fold_interpret Nat weight swapped

theorem positions_remain_distinct : sample.interpret ≠ swapped.interpret :=
  fun equal => (show (48 : Nat) ≠ 27 from of_decide_eq_true rfl)
    (generated_sample_observation.symm.trans
      ((congrArg observe equal).trans swapped_observation))

theorem sample_roundtrip : reify spec sample.interpret = sample := reify_interpret sample

def validationResult (declaration : Declaration) : Except ValidationError Spec :=
  (validate declaration).map Validated.spec

theorem reject_params : validationResult
    {spec.declaration with params := [(.many, "A", .univ 0)]} =
      .error .parameters := rfl

theorem reject_indices : validationResult
    {spec.declaration with indices := [(.many, "n", .univ 0)]} =
      .error .indices := rfl

theorem reject_level_zero : validationResult
    {spec.declaration with level := 0} = .error (.universe 0) := rfl

theorem reject_level_two : validationResult
    {spec.declaration with level := 2} = .error (.universe 2) := rfl

theorem reject_positivity : validationResult
    {spec.declaration with positive := false} = .error .positivity := rfl

theorem reject_provisional : validationResult
    {spec.declaration with status := .provisional} = .error .incompleteStatus := rfl

theorem reject_builtin : validationResult
    {spec.declaration with status := .builtin} = .error .incompleteStatus := rfl

theorem reject_name_order : validationResult {spec.declaration with
    status := .complete ["shoot", "bud", "join", "crown"]} =
      .error .constructorNames := rfl

theorem reject_missing_name : validationResult {spec.declaration with
    status := .complete ["bud", "shoot", "join"]} = .error .constructorNames := rfl

theorem reject_extra_name : validationResult {spec.declaration with
    status := .complete ["bud", "shoot", "join", "crown", "other"]} =
      .error .constructorNames := rfl

def oneConstructor (ctor : Constructor) : Declaration :=
  { spec.declaration with status := .complete [ctor.name], constructors := [ctor] }

def recursiveCtor : Constructor := (ConstructorSpec.mk "next" ["child"]).export "Grove"

theorem reject_result_index : validationResult
    (oneConstructor {recursiveCtor with resultIndices := [.lit 0]}) =
      .error (.resultIndices "next") := rfl

theorem reject_full_arity : validationResult
    (oneConstructor {recursiveCtor with fullArity := 0}) =
      .error (.fullArity "next" 1 0) := rfl

theorem reject_recursive_flag : validationResult
    (oneConstructor {recursiveCtor with selfRecursive := false}) =
      .error (.recursiveFlag "next") := rfl

theorem reject_nullary_recursive_flag : validationResult
    (oneConstructor { (ConstructorSpec.mk "stop" []).export "Grove" with
      selfRecursive := true }) = .error (.recursiveFlag "stop") := rfl

theorem reject_linear_field : validationResult
    (oneConstructor {recursiveCtor with args := [(.one, "child", familyType "Grove")]}) =
      .error .argumentQuantity := rfl

theorem reject_zero_field : validationResult
    (oneConstructor {recursiveCtor with args := [(.zero, "child", familyType "Grove")]}) =
      .error .argumentQuantity := rfl

theorem reject_foreign_family : validationResult
    (oneConstructor {recursiveCtor with args := [(.many, "child", familyType "Other")]}) =
      .error .argumentType := rfl

theorem reject_payload : validationResult
    (oneConstructor {recursiveCtor with args := [(.many, "child", .univ 0)]}) =
      .error .argumentType := rfl

theorem reject_indexed_self : validationResult
    (oneConstructor {recursiveCtor with args := [(.many, "child",
      .lan (.SMu "Grove" [.lit 0]) (.sec (.SColl 0) []))]}) =
      .error .argumentType := rfl

theorem reject_noncanonical_section : validationResult
    (oneConstructor {recursiveCtor with args := [(.many, "child",
      .lan (.SMu "Grove" []) (.sec (.SColl 1) []))]}) =
      .error .argumentType := rfl

theorem reject_duplicate_names : validationResult
    (Spec.declaration ⟨"Grove", [⟨"same", []⟩, ⟨"same", ["child"]⟩]⟩) =
      .error .invalidNames := rfl

theorem reject_empty_family_name : validationResult
    (Spec.declaration ⟨"", []⟩) = .error .invalidNames := rfl

theorem reject_unicode_name : validationResult
    (Spec.declaration ⟨"Grøve", []⟩) = .error .invalidNames := rfl

theorem reject_empty_constructor_name : validationResult
    (Spec.declaration ⟨"Grove", [⟨"", []⟩]⟩) = .error .invalidNames := rfl

theorem reject_invalid_binder : validationResult
    (Spec.declaration ⟨"Grove", [⟨"next", ["bad name"]⟩]⟩) = .error .invalidNames := rfl

def namedBinders : Spec := ⟨"Branch", [⟨"tip", []⟩, ⟨"branch", ["left", "right"]⟩]⟩

theorem retain_binder_names : validationResult namedBinders.declaration =
    .ok namedBinders := rfl

def emptySpec : Spec := ⟨"Empty", []⟩

theorem accept_empty_signature : validationResult emptySpec.declaration = .ok emptySpec := rfl

theorem emptyValueElim (value : Value emptySpec) : False :=
  match value with
  | .node ctor (_children) => Fin.elim0 ctor

def nullarySpec : Spec := ⟨"Choice", [⟨"left", []⟩, ⟨"right", []⟩]⟩

theorem accept_distinct_nullary_constructors :
    validationResult nullarySpec.declaration = .ok nullarySpec := rfl

#print axioms generated_validation
#print axioms generated_supported
#print axioms generated_sample_encoder
#print axioms generated_sample_observation
#print axioms positions_remain_distinct
#print axioms sample_roundtrip
#print axioms reject_duplicate_names

end KanonMeta.MuFinitary.Tests
