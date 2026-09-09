/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryOpen

/-!
Certified decoding for finite-family constructor terms in a finite context.
Variables carry a checked bound. Every successful result certifies exact raw
syntax, including family names, constructor names, arities and child order.
This decoder and the closed decoder keep distinct diagnostics for an unbound
raw variable.
-/

namespace KanonMeta.MuFinitary.OpenTerm

/-- Open decoding reports a closed decoder error or an out-of-scope variable. -/
inductive OpenDecodeError where
  | closed (reason : DecodeError)
  | outOfScopeVariable (index contextSize : Nat)
  deriving DecidableEq, Repr

/-- An open decoding result retains its context bound and exact raw syntax. -/
structure OpenDecoded (spec : Spec) (context : Nat) (term : Term) where
  value : OpenTerm spec context
  agreement : term = value.encode

private def searchConstructor (name : String) : (ctors : List ConstructorSpec) →
    Except (PLift (∀ i : Fin ctors.length, (ctors.get i).name ≠ name))
      {i : Fin ctors.length // (ctors.get i).name = name}
  | [] => .error ⟨fun i => Fin.elim0 i⟩
  | ctor :: rest =>
      if equal : ctor.name = name then .ok ⟨0, equal⟩
      else match searchConstructor name rest with
        | .ok ⟨i, found⟩ => .ok ⟨i.succ, found⟩
        | .error absent => .error ⟨fun i => Fin.cases
            (motive := fun i => ((ctor :: rest).get i).name ≠ name) equal absent.down i⟩

private structure DecodedChildren (spec : Spec) (context : Nat) (args : List Term) (n : Nat) where
  values : Fin n → OpenTerm spec context
  agreement : args = List.ofFn (fun i => (values i).encode)

private def decodedNil (spec : Spec) (context : Nat) : DecodedChildren spec context [] 0 :=
  ⟨Fin.elim0, rfl⟩

private def decodedCons {spec : Spec} {context : Nat} {arg : Term} {args : List Term} {n : Nat}
    (head : OpenDecoded spec context arg) (tail : DecodedChildren spec context args n) :
    DecodedChildren spec context (arg :: args) (n + 1) :=
  ⟨Fin.cases head.value tail.values,
    (congrArg (fun term => term :: args) head.agreement).trans
      ((congrArg (List.cons head.value.encode) tail.agreement).trans
        (List.ofFn_succ (f := fun i =>
          (Fin.cases (motive := fun (_i : Fin (n + 1)) => OpenTerm spec context)
            head.value tail.values i).encode)).symm)⟩

private def decodedNode {spec : Spec} {context : Nat} {name ctorName : String} {args : List Term}
    (nameEqual : name = spec.familyName) (ctor : spec.Constructor)
    (ctorEqual : spec.constructorName ctor = ctorName)
    (children : DecodedChildren spec context args (spec.arity ctor)) :
    OpenDecoded spec context (.intro (.SMu name []) (.actor ctorName) args) :=
  ⟨.node ctor children.values,
    (congrArg (fun familyName => Term.intro (.SMu familyName []) (.actor ctorName) args)
      nameEqual).trans
      ((congrArg (fun constructorName => Term.intro (family spec.familyName)
        (.actor constructorName) args) ctorEqual.symm).trans
        (congrArg (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
          children.agreement))⟩

private def nodeResult {spec : Spec} {context : Nat} {name ctorName : String} {args : List Term}
    (nameEqual : name = spec.familyName) (ctor : spec.Constructor)
    (ctorEqual : spec.constructorName ctor = ctorName) :
    Except OpenDecodeError (DecodedChildren spec context args (spec.arity ctor)) →
    Except OpenDecodeError (OpenDecoded spec context (.intro (.SMu name []) (.actor ctorName) args))
  | .error error => .error error
  | .ok children => .ok (decodedNode nameEqual ctor ctorEqual children)

private def constructorResult (spec : Spec) (context : Nat) (name ctorName : String) (args : List Term)
    (nameEqual : name = spec.familyName)
    (children : (ctor : spec.Constructor) →
      Except OpenDecodeError (DecodedChildren spec context args (spec.arity ctor))) :
    Except (PLift (∀ i : spec.Constructor, spec.constructorName i ≠ ctorName))
      {i : spec.Constructor // spec.constructorName i = ctorName} →
    Except OpenDecodeError (OpenDecoded spec context (.intro (.SMu name []) (.actor ctorName) args))
  | .error (_absent) => .error (.closed (.wrongAddress ctorName))
  | .ok ⟨ctor, ctorEqual⟩ => nodeResult nameEqual ctor ctorEqual (children ctor)

mutual

/-- Decode canonical introductions and variables strictly within the supplied context. -/
def openDecode (spec : Spec) (context : Nat) :
    (term : Term) → Except OpenDecodeError (OpenDecoded spec context term)
  | .var index => if within : index < context then .ok ⟨.var ⟨index, within⟩, rfl⟩
      else .error (.outOfScopeVariable index context)
  | .intro (.SMu name indices) address args =>
      if nameEqual : name = spec.familyName then
        match indices with
        | [] => match address with
          | .actor ctorName => constructorResult spec context name ctorName args nameEqual
              (fun ctor => decodeChildren spec context ctorName (spec.arity ctor) args.length
                args (spec.arity ctor))
              (searchConstructor ctorName spec.constructors)
          | .apt _ (_) => .error (.closed .nonConstructorAddress)
          | .aleg (_) => .error (.closed .nonConstructorAddress)
        | (_head :: _tail) => .error (.closed (.indexedFamily indices.length))
      else .error (.closed (.wrongFamily name))
  | .intro (.SPi _ _ _) _ (_) => .error (.closed .wrongShape)
  | .intro (.SColl _) _ (_) => .error (.closed .wrongShape)
  | .univ (_) => .error (.closed .unsupportedTerm)
  | .lan _ (_) => .error (.closed .unsupportedTerm)
  | .ran _ (_) => .error (.closed .unsupportedTerm)
  | .elim _ _ _ _ (_) => .error (.closed .unsupportedTerm)
  | .sec _ (_) => .error (.closed .unsupportedTerm)
  | .out _ _ (_) => .error (.closed .unsupportedTerm)
  | .letIn _ _ _ (_) => .error (.closed .unsupportedTerm)
  | .ann _ (_) => .error (.closed .unsupportedTerm)
  | .global (_) => .error (.closed .unsupportedTerm)
  | .lit (_) => .error (.closed .unsupportedTerm)
termination_by structural term => term

private def decodeChildren (spec : Spec) (context : Nat) (ctorName : String)
    (expected actual : Nat) : (args : List Term) → (n : Nat) →
    Except OpenDecodeError (DecodedChildren spec context args n)
  | [], 0 => .ok (decodedNil spec context)
  | [], _n + 1 => .error (.closed (.wrongArity ctorName expected actual))
  | (_arg :: _args), 0 => .error (.closed (.wrongArity ctorName expected actual))
  | arg :: args, n + 1 => match openDecode spec context arg with
    | .error error => .error error
    | .ok head => match decodeChildren spec context ctorName expected actual args n with
      | .error error => .error error
      | .ok tail => .ok (decodedCons head tail)
termination_by structural args => args

end

private theorem decodeChildren_cons {spec : Spec} {context : Nat}
    (name : String) (expected actual : Nat) {arg : Term} {args : List Term} {n : Nat}
    (head : OpenDecoded spec context arg) (tail : DecodedChildren spec context args n)
    (headEqual : openDecode spec context arg = .ok head)
    (tailEqual : decodeChildren spec context name expected actual args n = .ok tail) :
    decodeChildren spec context name expected actual (arg :: args) (n + 1) =
      .ok (decodedCons head tail) :=
  (congrArg (fun result : Except OpenDecodeError (OpenDecoded spec context arg) =>
    (match result with
    | .error error => .error error
    | .ok decodedHead => match decodeChildren spec context name expected actual args n with
      | .error error => .error error
      | .ok decodedTail => .ok (decodedCons decodedHead decodedTail) :
        Except OpenDecodeError (DecodedChildren spec context (arg :: args) (n + 1))))
      headEqual).trans
    (congrArg (fun result : Except OpenDecodeError (DecodedChildren spec context args n) =>
      (match result with
      | .error error => .error error
      | .ok decodedTail => .ok (decodedCons head decodedTail) :
        Except OpenDecodeError (DecodedChildren spec context (arg :: args) (n + 1)))) tailEqual)

private theorem decodeChildren_complete (spec : Spec) (context : Nat)
    (name : String) (expected actual : Nat) :
    ∀ (n : Nat) (children : Fin n → OpenTerm spec context),
      (∀ i, ∃ decoded, openDecode spec context (children i).encode = .ok decoded) →
      ∃ decoded, decodeChildren spec context name expected actual
        (List.ofFn (fun i => (children i).encode)) n = .ok decoded
  | 0, _children, _accepted => ⟨decodedNil spec context, rfl⟩
  | n + 1, children, accepted =>
      Eq.mpr (congrArg (fun args => ∃ decoded,
        decodeChildren spec context name expected actual args (n + 1) = .ok decoded)
          (List.ofFn_succ (f := fun i => (children i).encode)))
        (Exists.elim (accepted 0) (fun head headEqual =>
          Exists.elim (decodeChildren_complete spec context name expected actual n
            (fun i => children i.succ) (fun i => accepted i.succ))
            (fun tail tailEqual => ⟨decodedCons head tail,
              decodeChildren_cons name expected actual head tail headEqual tailEqual⟩)))

private theorem decode_node {spec : Spec} {context : Nat}
    (ctor : spec.Constructor) (args : List Term)
    (children : DecodedChildren spec context args (spec.arity ctor))
    (ctorEqual : searchConstructor (spec.constructorName ctor) spec.constructors = .ok ⟨ctor, rfl⟩)
    (childrenEqual : decodeChildren spec context (spec.constructorName ctor) (spec.arity ctor)
      args.length args (spec.arity ctor) = .ok children) :
    openDecode spec context
      (.intro (family spec.familyName) (.actor (spec.constructorName ctor)) args) =
      .ok (decodedNode rfl ctor rfl children) :=
  (dif_pos (rfl : spec.familyName = spec.familyName)).trans
    ((congrArg (constructorResult spec context spec.familyName (spec.constructorName ctor) args rfl
      (fun found => decodeChildren spec context (spec.constructorName ctor) (spec.arity found)
        args.length args (spec.arity found))) ctorEqual).trans
      (congrArg (nodeResult rfl ctor rfl) childrenEqual))

private theorem searchConstructor_complete {spec : Spec} (valid : spec.Valid)
    (ctor : spec.Constructor) :
    searchConstructor (spec.constructorName ctor) spec.constructors = .ok ⟨ctor, rfl⟩ :=
  match searchConstructor (spec.constructorName ctor) spec.constructors with
  | .error absent => False.elim (absent.down ctor rfl)
  | .ok found => congrArg Except.ok
      (Subtype.ext (a1 := found) (a2 := ⟨ctor, rfl⟩)
        (constructorName_injective valid found.property))

private theorem decode_complete {spec : Spec} {context : Nat} (valid : spec.Valid) :
    ∀ value : OpenTerm spec context,
      ∃ decoded, openDecode spec context value.encode = .ok decoded
  | .var index => ⟨⟨.var index, rfl⟩, dif_pos index.isLt⟩
  | .node ctor children =>
      Exists.elim (decodeChildren_complete spec context (spec.constructorName ctor)
        (spec.arity ctor) (List.ofFn (fun i => (children i).encode)).length
        (spec.arity ctor) children (fun i => decode_complete valid (children i)))
        (fun decoded childrenEqual =>
          ⟨decodedNode rfl ctor rfl decoded,
            decode_node ctor (List.ofFn (fun i => (children i).encode)) decoded
              (searchConstructor_complete valid ctor) childrenEqual⟩)

/-- Encoding then decoding preserves variable indices and every ordered constructor child. -/
theorem openDecode_encode {spec : Spec} {context : Nat} (valid : spec.Valid)
    (value : OpenTerm spec context) :
    openDecode spec context value.encode = .ok ⟨value, rfl⟩ :=
  Exists.elim (decode_complete valid value) (fun decoded accepted =>
    accepted.trans (congrArg Except.ok
      (match decoded with
      | ⟨_decodedValue, agreement⟩ =>
          let equal := encode_injective valid agreement
          Eq.rec (motive := fun decodedValue (_equal) =>
            ∀ agreement : value.encode = decodedValue.encode,
              OpenDecoded.mk decodedValue agreement = OpenDecoded.mk value rfl)
            (fun (_agreement) => rfl) equal agreement)))

/-- Accepted terms equal their decoded raw encoding, without a validity assumption. -/
theorem openDecode_sound (spec : Spec) (context : Nat) (term : Term)
    (value : OpenTerm spec context)
    (accepted : (openDecode spec context term).map OpenDecoded.value = .ok value) :
    term = value.encode :=
  match found : openDecode spec context term with
  | .ok decoded =>
      decoded.agreement.trans (congrArg encode (Except.ok.inj (found ▸ accepted)))
  | .error failure =>
      let refuted : Except.map OpenDecoded.value (Except.error failure)
          = Except.ok value := found ▸ accepted
      nomatch refuted

/-- For valid declarations, acceptance is exactly membership in the encoding image. -/
theorem openDecode_accepts_iff {spec : Spec} (valid : spec.Valid)
    (context : Nat) (term : Term) :
    (∃ decoded, openDecode spec context term = .ok decoded) ↔
      ∃ value : OpenTerm spec context, term = value.encode :=
  ⟨fun ⟨decoded, _accepted⟩ => ⟨decoded.value, decoded.agreement⟩,
    fun ⟨value, equal⟩ =>
      Eq.mpr (congrArg (fun raw => ∃ decoded, openDecode spec context raw = .ok decoded) equal)
        ⟨⟨value, rfl⟩, openDecode_encode valid value⟩⟩

/-- A zero-size context accepts precisely the terms accepted by the closed
decoder. -/
theorem openDecode_zero_iff {spec : Spec} (valid : spec.Valid) (term : Term) :
    (∃ decoded, openDecode spec 0 term = .ok decoded) ↔
      ∃ decoded, decode spec term = .ok decoded :=
  ⟨fun ⟨decoded, _accepted⟩ =>
      let equal := decoded.agreement.trans (encode_close decoded.value).symm
      Eq.mpr (congrArg (fun raw => ∃ result, decode spec raw = .ok result) equal)
        ⟨⟨decoded.value.close, rfl⟩,
          KanonMeta.MuFinitary.decode_encode valid decoded.value.close⟩,
    fun ⟨decoded, _accepted⟩ =>
      let value : OpenTerm spec 0 := ofValue decoded.value
      let equal : term = value.encode :=
        decoded.agreement.trans (encode_ofValue decoded.value).symm
      Eq.mpr (congrArg (fun raw => ∃ result, openDecode spec 0 raw = .ok result) equal)
        ⟨⟨value, rfl⟩, openDecode_encode valid value⟩⟩

end KanonMeta.MuFinitary.OpenTerm
