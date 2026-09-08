/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitary

/-!
Total decoding for the declaration-driven finite recursive fragment. Every
successful result certifies exact equality with its raw constructor encoding.
The decoder traverses the raw term and its ordered child lists structurally.
-/

namespace KanonMeta.MuFinitary

inductive DecodeError where
  | wrongShape
  | wrongFamily (name : String)
  | indexedFamily (count : Nat)
  | nonConstructorAddress
  | wrongAddress (name : String)
  | wrongArity (name : String) (expected actual : Nat)
  | unsupportedTerm
  deriving DecidableEq, Repr

/-- A decoded value carries exact agreement with the supplied raw term. -/
structure Decoded (spec : Spec) (term : Term) where
  value : Value spec
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

private structure DecodedChildren (spec : Spec) (args : List Term) (n : Nat) where
  values : Fin n → Value spec
  agreement : args = List.ofFn (fun i => (values i).encode)

private def decodedNil (spec : Spec) : DecodedChildren spec [] 0 :=
  ⟨Fin.elim0, rfl⟩

private def decodedCons {spec : Spec} {arg : Term} {args : List Term} {n : Nat}
    (head : Decoded spec arg) (tail : DecodedChildren spec args n) :
    DecodedChildren spec (arg :: args) (n + 1) :=
  ⟨Fin.cases head.value tail.values,
    (congrArg (fun term => term :: args) head.agreement).trans
      ((congrArg (List.cons head.value.encode) tail.agreement).trans
        (List.ofFn_succ (f := fun i =>
          (Fin.cases (motive := fun (_i : Fin (n + 1)) => Value spec)
            head.value tail.values i).encode)).symm)⟩

private def decodedNode {spec : Spec} {name ctorName : String} {args : List Term}
    (nameEqual : name = spec.familyName) (ctor : spec.Constructor)
    (ctorEqual : spec.constructorName ctor = ctorName)
    (children : DecodedChildren spec args (spec.arity ctor)) :
    Decoded spec (.intro (.SMu name []) (.actor ctorName) args) :=
  ⟨.node ctor children.values,
    (congrArg (fun familyName => Term.intro (.SMu familyName []) (.actor ctorName) args)
      nameEqual).trans
      ((congrArg (fun constructorName => Term.intro (family spec.familyName)
        (.actor constructorName) args) ctorEqual.symm).trans
        (congrArg (Term.intro (family spec.familyName) (.actor (spec.constructorName ctor)))
          children.agreement))⟩

private def nodeResult {spec : Spec} {name ctorName : String} {args : List Term}
    (nameEqual : name = spec.familyName) (ctor : spec.Constructor)
    (ctorEqual : spec.constructorName ctor = ctorName) :
    Except DecodeError (DecodedChildren spec args (spec.arity ctor)) →
    Except DecodeError (Decoded spec (.intro (.SMu name []) (.actor ctorName) args))
  | .error error => .error error
  | .ok children => .ok (decodedNode nameEqual ctor ctorEqual children)

private def constructorResult (spec : Spec) (name ctorName : String) (args : List Term)
    (nameEqual : name = spec.familyName)
    (children : (ctor : spec.Constructor) →
      Except DecodeError (DecodedChildren spec args (spec.arity ctor))) :
    Except (PLift (∀ i : spec.Constructor, spec.constructorName i ≠ ctorName))
      {i : spec.Constructor // spec.constructorName i = ctorName} →
    Except DecodeError (Decoded spec (.intro (.SMu name []) (.actor ctorName) args))
  | .error (_absent) => .error (.wrongAddress ctorName)
  | .ok ⟨ctor, ctorEqual⟩ => nodeResult nameEqual ctor ctorEqual (children ctor)

mutual

/-- Accept exactly closed canonical introductions with the declared ordered arity. -/
def decode (spec : Spec) : (term : Term) → Except DecodeError (Decoded spec term)
  | .intro (.SMu name indices) address args =>
      if nameEqual : name = spec.familyName then
        match indices with
        | [] => match address with
          | .actor ctorName => constructorResult spec name ctorName args nameEqual
              (fun ctor => decodeChildren spec ctorName (spec.arity ctor) args.length
                args (spec.arity ctor))
              (searchConstructor ctorName spec.constructors)
          | .apt _ (_) => .error .nonConstructorAddress
          | .aleg (_) => .error .nonConstructorAddress
        | (_head :: _tail) => .error (.indexedFamily indices.length)
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

private def decodeChildren (spec : Spec) (ctorName : String) (expected actual : Nat) :
    (args : List Term) → (n : Nat) →
    Except DecodeError (DecodedChildren spec args n)
  | [], 0 => .ok (decodedNil spec)
  | [], _n + 1 => .error (.wrongArity ctorName expected actual)
  | (_arg :: _args), 0 => .error (.wrongArity ctorName expected actual)
  | arg :: args, n + 1 => match decode spec arg with
    | .error error => .error error
    | .ok head => match decodeChildren spec ctorName expected actual args n with
      | .error error => .error error
      | .ok tail => .ok (decodedCons head tail)
termination_by structural args => args

end

/-- Name uniqueness identifies the declaration position, including reordered declarations. -/
theorem constructorName_injective {spec : Spec} (valid : spec.Valid)
    {left right : spec.Constructor}
    (equal : spec.constructorName left = spec.constructorName right) : left = right :=
  Fin.ext ((List.getElem_inj
    (h₀ := (List.length_map (f := ConstructorSpec.name)).symm ▸ left.isLt)
    (h₁ := (List.length_map (f := ConstructorSpec.name)).symm ▸ right.isLt)
    valid.2.2).mp
      ((List.getElem_map ConstructorSpec.name).trans
        (equal.trans (List.getElem_map ConstructorSpec.name).symm)))

private theorem ofFn_position {α : Type} {n : Nat} (values : Fin n → α) (i : Fin n) :
    (List.ofFn values)[i.val]? = some (values i) :=
  List.getElem?_ofFn.trans (dif_pos i.isLt)

private theorem ofFn_injective {α : Type} {n : Nat} {left right : Fin n → α}
    (equal : List.ofFn left = List.ofFn right) (i : Fin n) : left i = right i :=
  Option.some.inj ((ofFn_position left i).symm.trans
    ((congrArg (fun values => values[i.val]?) equal).trans (ofFn_position right i)))

/-- For valid declarations, raw encodings retain constructor identity and ordered children. -/
theorem encode_injective {spec : Spec} (valid : spec.Valid) :
    ∀ {left right : Value spec}, left.encode = right.encode → left = right
  | .node leftCtor leftChildren, .node _rightCtor rightChildren, equal =>
      let ctorEqual :=
        constructorName_injective valid (Addr.actor.inj (Term.intro.inj equal).2.1)
      Eq.rec (motive := fun ctor (_equal) =>
        ∀ children : Fin (spec.arity ctor) → Value spec,
          (Value.node leftCtor leftChildren).encode = (Value.node ctor children).encode →
          Value.node leftCtor leftChildren = Value.node ctor children)
        (fun _children equalChildren => congrArg (Value.node leftCtor) (funext (fun i =>
          encode_injective valid (ofFn_injective (Term.intro.inj equalChildren).2.2 i))))
        ctorEqual rightChildren equal

private theorem decodeChildren_cons {spec : Spec} (name : String) (expected actual : Nat)
    {arg : Term} {args : List Term} {n : Nat}
    (head : Decoded spec arg) (tail : DecodedChildren spec args n)
    (headEqual : decode spec arg = .ok head)
    (tailEqual : decodeChildren spec name expected actual args n = .ok tail) :
    decodeChildren spec name expected actual (arg :: args) (n + 1) =
      .ok (decodedCons head tail) :=
  (congrArg (fun result : Except DecodeError (Decoded spec arg) =>
    (match result with
    | .error error => .error error
    | .ok decodedHead => match decodeChildren spec name expected actual args n with
      | .error error => .error error
      | .ok decodedTail => .ok (decodedCons decodedHead decodedTail) :
        Except DecodeError (DecodedChildren spec (arg :: args) (n + 1)))) headEqual).trans
    (congrArg (fun result : Except DecodeError (DecodedChildren spec args n) =>
      (match result with
      | .error error => .error error
      | .ok decodedTail => .ok (decodedCons head decodedTail) :
        Except DecodeError (DecodedChildren spec (arg :: args) (n + 1)))) tailEqual)

private theorem decodeChildren_complete (spec : Spec) (name : String) (expected actual : Nat) :
    ∀ (n : Nat) (children : Fin n → Value spec),
      (∀ i, ∃ decoded, decode spec (children i).encode = .ok decoded) →
      ∃ decoded, decodeChildren spec name expected actual
        (List.ofFn (fun i => (children i).encode)) n = .ok decoded
  | 0, _children, _accepted => ⟨decodedNil spec, rfl⟩
  | n + 1, children, accepted =>
      Eq.mpr (congrArg (fun args => ∃ decoded,
        decodeChildren spec name expected actual args (n + 1) = .ok decoded)
          (List.ofFn_succ (f := fun i => (children i).encode)))
        (Exists.elim (accepted 0) (fun head headEqual =>
          Exists.elim (decodeChildren_complete spec name expected actual n
            (fun i => children i.succ) (fun i => accepted i.succ))
            (fun tail tailEqual => ⟨decodedCons head tail,
              decodeChildren_cons name expected actual head tail headEqual tailEqual⟩)))

private theorem decode_node {spec : Spec} (ctor : spec.Constructor) (args : List Term)
    (children : DecodedChildren spec args (spec.arity ctor))
    (ctorEqual : searchConstructor (spec.constructorName ctor) spec.constructors = .ok ⟨ctor, rfl⟩)
    (childrenEqual : decodeChildren spec (spec.constructorName ctor) (spec.arity ctor)
      args.length args (spec.arity ctor) = .ok children) :
    decode spec (.intro (family spec.familyName) (.actor (spec.constructorName ctor)) args) =
      .ok (decodedNode rfl ctor rfl children) :=
  (dif_pos (rfl : spec.familyName = spec.familyName)).trans
    ((congrArg (constructorResult spec spec.familyName (spec.constructorName ctor) args rfl
      (fun found => decodeChildren spec (spec.constructorName ctor) (spec.arity found)
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

private theorem decode_complete {spec : Spec} (valid : spec.Valid) :
    ∀ value : Value spec, ∃ decoded, decode spec value.encode = .ok decoded
  | .node ctor children =>
      Exists.elim (decodeChildren_complete spec (spec.constructorName ctor)
        (spec.arity ctor) (List.ofFn (fun i => (children i).encode)).length
        (spec.arity ctor) children (fun i => decode_complete valid (children i)))
        (fun decoded childrenEqual =>
          ⟨decodedNode rfl ctor rfl decoded,
            decode_node ctor (List.ofFn (fun i => (children i).encode)) decoded
              (searchConstructor_complete valid ctor) childrenEqual⟩)

/-- Every encoded value is accepted, with the original constructor positions and children. -/
theorem decode_encode {spec : Spec} (valid : spec.Valid) (value : Value spec) :
    decode spec value.encode = .ok ⟨value, rfl⟩ :=
  Exists.elim (decode_complete valid value) (fun decoded accepted =>
    accepted.trans (congrArg Except.ok
      (match decoded with
      | ⟨_decodedValue, agreement⟩ =>
          let equal := encode_injective valid agreement
          Eq.rec (motive := fun decodedValue (_equal) =>
            ∀ agreement : value.encode = decodedValue.encode,
              Decoded.mk decodedValue agreement = Decoded.mk value rfl)
            (fun (_agreement) => rfl) equal
            agreement)))

/-- Successful decoding supplies the exact raw encoding, including every child. -/
theorem decode_sound (spec : Spec) (term : Term) (value : Value spec)
    (accepted : (decode spec term).map Decoded.value = .ok value) : term = value.encode :=
  match found : decode spec term with
  | .ok decoded =>
      decoded.agreement.trans (congrArg Value.encode (Except.ok.inj (found ▸ accepted)))
  | .error failure =>
      let refuted : Except.map Decoded.value (Except.error failure)
          = Except.ok value := found ▸ accepted
      nomatch refuted

/-- The checked wrapper keeps the declaration certificate with the decoded value. -/
def Decoded.checkedValue {declaration : Declaration} (checked : Validated declaration)
    {term : Term} (decoded : Decoded checked.spec term) : CheckedValue declaration :=
  ⟨checked, decoded.value⟩

/-- Decode a raw term against the specification of a validated declaration. -/
def checkedDecode {declaration : Declaration} (checked : Validated declaration)
    (term : Term) : Except DecodeError (Decoded checked.spec term) :=
  decode checked.spec term

noncomputable def Decoded.interpret {spec : Spec} {term : Term}
    (decoded : Decoded spec term) : Carrier spec := decoded.value.interpret

theorem decoded_fold_interpret {spec : Spec} {term : Term} (decoded : Decoded spec term)
    (X : Type) (step : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → X) → X) :
    semanticFold spec X step decoded.interpret = decoded.value.fold step :=
  fold_interpret X step decoded.value

end KanonMeta.MuFinitary
