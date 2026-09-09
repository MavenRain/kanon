/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryOpen
import test.MuFinitary

namespace KanonMeta.MuFinitary.Tests.Open

def variable0 : OpenTerm spec 2 := .var 0
def variable1 : OpenTerm spec 2 := .var 1

def branch {n : Nat} (left right : OpenTerm spec n) : OpenTerm spec n :=
  .node ⟨2, of_decide_eq_true rfl⟩ (Fin.cases left (fun (_pos) => right))

def pattern : OpenTerm spec 2 := branch variable0 (branch variable1 variable0)

def environment : Fin 2 → Nat := Fin.cases 7 (fun (_index) => 11)

theorem independent_observation : pattern.evaluate environment weight = 143 := rfl

def permutation : Fin 2 → Fin 2 := Fin.cases 1 (fun (_index) => 0)

theorem permuted_observation :
    (pattern.rename permutation).evaluate environment weight = 163 := rfl

def replacement : Fin 2 → OpenTerm spec 1 :=
  Fin.cases (.var 0) (fun (_index) => branch (.var 0) (.var 0))

theorem changes_context_size :
    (pattern.substitute replacement).evaluate (fun (_index) => 3) weight = 123 := rfl

def closedReplacement : Fin 2 → OpenTerm spec 0 :=
  Fin.cases (OpenTerm.ofValue bud) (fun (_index) => OpenTerm.ofValue (shoot bud))

theorem closes_variables :
    (pattern.substitute closedReplacement).close.fold weight = 23 := rfl

def rawReplacement : Subst := fun index =>
  match index with
  | 0 => .var 0
  | 1 => (branch (.var 0) (.var 0) : OpenTerm spec 1).encode
  | _index + 2 => .global "unused"

theorem raw_substitution_observation :
    subst rawReplacement pattern.encode = (pattern.substitute replacement).encode := rfl

theorem empty_context_encoding :
    (OpenTerm.ofValue sample : OpenTerm spec 0).encode = Generated.sample := rfl

theorem empty_context_roundtrip :
    (OpenTerm.ofValue sample : OpenTerm spec 0).close = sample :=
  OpenTerm.close_ofValue sample

theorem structural_identity {n : Nat} (term : OpenTerm spec n) :
    term.substitute OpenTerm.var = term := OpenTerm.substitute_id term

theorem structural_composition {n m k : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (tau : Fin m → OpenTerm spec k) :
    (term.substitute sigma).substitute tau =
      term.substitute (fun i => (sigma i).substitute tau) :=
  OpenTerm.substitute_comp sigma tau term

theorem structural_renaming_identity {n : Nat} (term : OpenTerm spec n) :
    term.rename (fun i => i) = term := OpenTerm.rename_id term

theorem structural_renaming_composition {n m k : Nat}
    (term : OpenTerm spec n) (rho : Fin n → Fin m) (tau : Fin m → Fin k) :
    (term.rename rho).rename tau = term.rename (fun i => tau (rho i)) :=
  OpenTerm.rename_comp rho tau term

theorem encoding_substitution {n m : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (raw : Subst) (agreement : ∀ i : Fin n, raw i.val = (sigma i).encode) :
    (term.substitute sigma).encode = subst raw term.encode :=
  OpenTerm.encode_substitute sigma raw agreement term

theorem encoding_renaming {n m : Nat}
    (term : OpenTerm spec n) (rho : Fin n → Fin m)
    (raw : Ren) (agreement : ∀ i : Fin n, raw i.val = (rho i).val) :
    (term.rename rho).encode = ren raw term.encode :=
  OpenTerm.encode_rename rho raw agreement term

theorem semantic_substitution {n m : Nat}
    (term : OpenTerm spec n) (sigma : Fin n → OpenTerm spec m)
    (env : Fin m → Carrier spec) :
    (term.substitute sigma).interpret env =
      term.interpret (fun i => (sigma i).interpret env) :=
  OpenTerm.interpret_substitute sigma env term

theorem semantic_renaming {n m : Nat}
    (term : OpenTerm spec n) (rho : Fin n → Fin m) (env : Fin m → Carrier spec) :
    (term.rename rho).interpret env = term.interpret (fun i => env (rho i)) :=
  OpenTerm.interpret_rename rho env term

theorem semantic_observation (env : Fin 2 → Carrier spec) :
    semanticFold spec Nat weight (pattern.interpret env) =
      pattern.evaluate (fun i => semanticFold spec Nat weight (env i)) weight :=
  OpenTerm.fold_interpret Nat weight env pattern

end KanonMeta.MuFinitary.Tests.Open
