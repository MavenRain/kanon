/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.MuFinitaryElimCoherence
import test.MuFinitaryElimSubst

namespace KanonMeta.MuFinitary.Tests.ElimCoherence

open Elim (spec)
open ElimSubst

/-- The two naturality transports are both retained in this observation. -/
noncomputable def sequentialWitness
    (supplied : (i : Fin 2) → Witness (environment i)) :
    Witness (pattern.interpret
      (fun i => (replacement i).interpret
        (fun j => (nestedReplacement j).interpret environment))) :=
  Eq.mp (congrArg Witness (OpenTerm.interpret_substitute replacement
    (fun j => (nestedReplacement j).interpret environment) pattern))
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute nestedReplacement environment
      (pattern.substitute replacement)))
      (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret
        Witness step environment supplied))

theorem sequential_transport_observation : (sequentialWitness witnesses).2 = 2577 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment witnesses pattern)

theorem sequential_dependent_observation : (sequentialWitness witnesses).1.val = 299 :=
  congrArg (fun witness => witness.1.val)
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment witnesses pattern)

theorem alternate_sequential_transport_observation :
    (sequentialWitness alternateWitnesses).2 = 2849 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment alternateWitnesses pattern)

/-- Equal semantic inputs still retain different user-supplied annotations. -/
theorem sequential_transport_retains_supplied_data :
    sequentialWitness witnesses ≠ sequentialWitness alternateWitnesses :=
  fun equal => (show (2577 : Nat) ≠ 2849 from of_decide_eq_true rfl)
    (sequential_transport_observation.symm.trans
      ((congrArg Prod.snd equal).trans alternate_sequential_transport_observation))

/-- Align the direct replacement environment with the iterated environment. -/
noncomputable def composedEndpointWitness
    (supplied : (i : Fin 2) → Witness (environment i)) :
    Witness (pattern.interpret
      (fun i => (replacement i).interpret
        (fun j => (nestedReplacement j).interpret environment))) :=
  Eq.mp (congrArg Witness
    (congrArg (fun env : Fin 2 → Carrier spec => pattern.interpret env)
      (funext (fun i => OpenTerm.interpret_substitute nestedReplacement environment
        (replacement i)))))
    (pattern.inductInterpret Witness step
      (fun i => ((replacement i).substitute nestedReplacement).interpret environment)
      (fun i => ((replacement i).substitute nestedReplacement).inductInterpret
        Witness step environment supplied))

theorem composed_endpoint_transport_observation :
    (composedEndpointWitness witnesses).2 = 2577 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_comp_coherent Witness step replacement
      nestedReplacement environment witnesses pattern)

theorem alternate_composed_endpoint_transport_observation :
    (composedEndpointWitness alternateWitnesses).2 = 2849 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_comp_coherent Witness step replacement
      nestedReplacement environment alternateWitnesses pattern)

theorem environment_congruence_with_transported_witnesses :
    composedEndpointWitness witnesses =
      pattern.inductInterpret Witness step
        (fun i => (replacement i).interpret
          (fun j => (nestedReplacement j).interpret environment))
        (fun i => (replacement i).inductInterpret Witness step
          (fun j => (nestedReplacement j).interpret environment)
          (fun j => (nestedReplacement j).inductInterpret Witness step environment witnesses)) :=
  OpenTerm.inductInterpret_congr Witness step
    (fun i => OpenTerm.interpret_substitute nestedReplacement environment (replacement i))
    (fun i => ((replacement i).substitute nestedReplacement).inductInterpret
      Witness step environment witnesses)
    (fun i => (replacement i).inductInterpret Witness step
      (fun j => (nestedReplacement j).interpret environment)
      (fun j => (nestedReplacement j).inductInterpret Witness step environment witnesses))
    (fun i => OpenTerm.inductInterpret_substitute Witness step nestedReplacement environment
      witnesses (replacement i)) pattern

theorem sequential_and_composed_endpoints_agree :
    sequentialWitness witnesses = composedEndpointWitness witnesses :=
  (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
    environment witnesses pattern).trans
    (OpenTerm.inductInterpret_substitute_comp_coherent Witness step replacement
      nestedReplacement environment witnesses pattern).symm

/-- This route performs syntax reassociation, naturality, then environment alignment. -/
noncomputable def composedRouteWitness
    (supplied : (i : Fin 2) → Witness (environment i)) :
    Witness (pattern.interpret
      (fun i => (replacement i).interpret
        (fun j => (nestedReplacement j).interpret environment))) :=
  Eq.mp (congrArg Witness
    (congrArg (fun env : Fin 2 → Carrier spec => pattern.interpret env)
      (funext (fun i => OpenTerm.interpret_substitute nestedReplacement environment
        (replacement i)))))
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute composedReplacement
      environment pattern))
      (Eq.mp (congrArg Witness
        (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
          (OpenTerm.substitute_comp replacement nestedReplacement pattern)))
        (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret
          Witness step environment supplied)))

theorem substitution_routes_agree (supplied : (i : Fin 2) → Witness (environment i)) :
    sequentialWitness supplied = composedRouteWitness supplied :=
  OpenTerm.inductInterpret_substitute_comp_routes Witness step replacement nestedReplacement
    environment supplied pattern

theorem composed_route_transport_observation : (composedRouteWitness witnesses).2 = 2577 :=
  (congrArg Prod.snd (substitution_routes_agree witnesses)).symm.trans
    sequential_transport_observation

theorem alternate_composed_route_transport_observation :
    (composedRouteWitness alternateWitnesses).2 = 2849 :=
  (congrArg Prod.snd (substitution_routes_agree alternateWitnesses)).symm.trans
    alternate_sequential_transport_observation

theorem ordered_chain_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute replacement
      (fun j => (nestedReplacement j).interpret environment) reversed))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute nestedReplacement environment
        (reversed.substitute replacement)))
        (((reversed.substitute replacement).substitute nestedReplacement).inductInterpret
          Witness step environment witnesses))).2 = 2574 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment witnesses reversed)

theorem sequential_renaming_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse
      (fun i => environment (embedSecond i)) pattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename embedSecond environment
        (pattern.rename collapse)))
        (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step
          environment witnesses))).2 = 187 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_seq Witness step collapse embedSecond environment
      witnesses pattern)

theorem alternate_sequential_renaming_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse
      (fun i => environment (embedSecond i)) pattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename embedSecond environment
        (pattern.rename collapse)))
        (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step
          environment alternateWitnesses))).2 = 221 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_seq Witness step collapse embedSecond environment
      alternateWitnesses pattern)

theorem composed_renaming_route_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename
      (fun i => embedSecond (collapse i)) environment pattern))
      (Eq.mp (congrArg Witness
        (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
          (OpenTerm.rename_comp collapse embedSecond pattern)))
        (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step
          environment witnesses))).2 = 187 :=
  (congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_comp_routes Witness step collapse embedSecond environment
      witnesses pattern)).symm.trans sequential_renaming_transport_observation

theorem identity_chain_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute OpenTerm.var environment pattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute OpenTerm.var environment
        (pattern.substitute OpenTerm.var)))
        (((pattern.substitute OpenTerm.var).substitute OpenTerm.var).inductInterpret
          Witness step environment witnesses))).2 = 159 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step OpenTerm.var OpenTerm.var
      environment witnesses pattern)

theorem closing_chain_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute closedReplacement
      (fun j : Fin 0 => (Fin.elim0 j : OpenTerm spec 0).interpret Fin.elim0) pattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
        (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0
        (pattern.substitute closedReplacement)))
        (((pattern.substitute closedReplacement).substitute Fin.elim0).inductInterpret
          Witness step Fin.elim0 emptyWitnesses))).2 = 27 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step closedReplacement
      (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0 emptyWitnesses pattern)

theorem empty_context_chain_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
      (Fin.elim0 : Fin 0 → OpenTerm spec 0)
      (fun j : Fin 0 => (Fin.elim0 j : OpenTerm spec 0).interpret Fin.elim0) closedSample))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
        (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0
        (closedSample.substitute Fin.elim0)))
        (((closedSample.substitute Fin.elim0).substitute Fin.elim0).inductInterpret
          Witness step Fin.elim0 emptyWitnesses))).2 = 51 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step
      (Fin.elim0 : Fin 0 → OpenTerm spec 0) (Fin.elim0 : Fin 0 → OpenTerm spec 0)
      Fin.elim0 emptyWitnesses closedSample)

theorem empty_context_renaming_chain_transport_observation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename
      (Fin.elim0 : Fin 0 → Fin 0)
      (fun j : Fin 0 => (Fin.elim0 : Fin 0 → Carrier spec)
        ((Fin.elim0 : Fin 0 → Fin 0) j)) closedSample))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename
        (Fin.elim0 : Fin 0 → Fin 0) Fin.elim0 (closedSample.rename Fin.elim0)))
        (((closedSample.rename Fin.elim0).rename Fin.elim0).inductInterpret
          Witness step Fin.elim0 emptyWitnesses))).2 = 51 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_seq Witness step
      (Fin.elim0 : Fin 0 → Fin 0) (Fin.elim0 : Fin 0 → Fin 0)
      Fin.elim0 emptyWitnesses closedSample)

#print axioms sequential_transport_observation
#print axioms sequential_dependent_observation
#print axioms sequential_transport_retains_supplied_data
#print axioms composed_endpoint_transport_observation
#print axioms environment_congruence_with_transported_witnesses
#print axioms sequential_and_composed_endpoints_agree
#print axioms substitution_routes_agree
#print axioms composed_route_transport_observation
#print axioms ordered_chain_transport_observation
#print axioms sequential_renaming_transport_observation
#print axioms composed_renaming_route_observation
#print axioms identity_chain_transport_observation
#print axioms closing_chain_transport_observation
#print axioms empty_context_chain_transport_observation
#print axioms empty_context_renaming_chain_transport_observation

end KanonMeta.MuFinitary.Tests.ElimCoherence
