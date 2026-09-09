import KanonMeta

namespace Client

open KanonMeta KanonMeta.MuFinitary

def spec : Spec := ⟨"Bush", [⟨"tip", []⟩, ⟨"fork", ["a", "b", "c", "d"]⟩]⟩

theorem valid : spec.Valid := of_decide_eq_true rfl

def expression : OpenTerm spec 2 :=
  .node ⟨1, of_decide_eq_true rfl⟩
    (Fin.cases (.var 0) (Fin.cases (.var 1)
      (Fin.cases (.var 0) (fun (_index) => .var 1))))

def observe : (ctor : spec.Constructor) → (Fin (spec.arity ctor) → Nat) → Nat :=
  Fin.cases (motive := fun ctor => (Fin (spec.arity ctor) → Nat) → Nat)
    (fun (_children) => 1)
    (Fin.cases (fun children => children (0 : Fin 4) + 2 * children (1 : Fin 4) +
      3 * children (2 : Fin 4) + 5 * children (3 : Fin 4)) (fun index => Fin.elim0 index))

def environment : Fin 2 → Nat := Fin.cases 7 (fun (_index) => 11)

theorem ordered_observation : expression.evaluate environment observe = 105 := rfl

theorem reconstruction :
    OpenTerm.openDecode spec 2 expression.encode = .ok ⟨expression, rfl⟩ :=
  OpenTerm.openDecode_encode valid expression

theorem out_of_scope :
    (OpenTerm.openDecode spec 2 (.var 2)).map OpenTerm.OpenDecoded.value =
      .error (.outOfScopeVariable 2 2) := rfl

theorem structural_substitution {n m k : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (tau : Fin m → OpenTerm spec k) :
    (term.substitute sigma).substitute tau =
      term.substitute (fun i => (sigma i).substitute tau) :=
  OpenTerm.substitute_comp sigma tau term

theorem raw_substitution {n m : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (raw : Subst) (agreement : ∀ i : Fin n, raw i.val = (sigma i).encode) :
    (term.substitute sigma).encode = subst raw term.encode :=
  OpenTerm.encode_substitute sigma raw agreement term

theorem semantic_substitution {n m : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (env : Fin m → Carrier spec) :
    (term.substitute sigma).interpret env =
      term.interpret (fun i => (sigma i).interpret env) :=
  OpenTerm.interpret_substitute sigma env term

theorem observe_semantics (env : Fin 2 → Carrier spec) :
    semanticFold spec Nat observe (expression.interpret env) =
      expression.evaluate (fun i => semanticFold spec Nat observe (env i)) observe :=
  OpenTerm.fold_interpret Nat observe env expression

theorem closed_agreement (term : OpenTerm spec 0) :
    term.close.interpret = term.interpret Fin.elim0 :=
  OpenTerm.interpret_close term

end Client
