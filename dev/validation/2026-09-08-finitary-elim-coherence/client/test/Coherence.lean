import KanonCoherenceClient

namespace KanonCoherenceClient.Tests

open KanonMeta.MuFinitary

theorem valid_spec : spec.Valid := of_decide_eq_true rfl

theorem equal_variable_semantics : environment 0 = environment 1 := rfl

theorem different_variable_data : witnesses 0 ≠ witnesses 1 :=
  fun equal => (show (7 : Nat) ≠ 11 from of_decide_eq_true rfl) (congrArg Prod.snd equal)

theorem zero_is_not_a_leaf_witness :
    ¬ ∃ witness : Witness leaf.interpret, witness.1.val = 0 :=
  fun ⟨witness, zero⟩ => (show (2 : Nat) ≠ 0 from of_decide_eq_true rfl)
    ((fold_interpret Nat weight leaf).symm.trans (witness.1.property.symm.trans zero))

theorem repeated_ordered_variable_observation :
    (pattern.inductInterpret Witness step environment witnesses).2 = 361 := rfl

theorem permuted_variable_observation :
    (reversed.inductInterpret Witness step environment witnesses).2 = 413 := rfl

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

theorem nested_transport_annotation : (sequentialWitness witnesses).2 = 10064 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment witnesses pattern)

theorem nested_transport_certificate : (sequentialWitness witnesses).1.val = 2368 :=
  congrArg (fun witness => witness.1.val)
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment witnesses pattern)

theorem alternate_nested_transport_annotation :
    (sequentialWitness alternateWitnesses).2 = 10952 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step replacement nestedReplacement
      environment alternateWitnesses pattern)

theorem composed_transport_retains_supplied_annotation :
    sequentialWitness witnesses ≠ sequentialWitness alternateWitnesses :=
  fun equal => (show (10064 : Nat) ≠ 10952 from of_decide_eq_true rfl)
    (nested_transport_annotation.symm.trans
      ((congrArg Prod.snd equal).trans alternate_nested_transport_annotation))

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

theorem composed_endpoint_annotation : (composedEndpointWitness witnesses).2 = 10064 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_comp_coherent Witness step replacement
      nestedReplacement environment witnesses pattern)

theorem explicit_environment_congruence :
    (composedEndpointWitness alternateWitnesses).2 = 10952 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_congr Witness step
      (fun i => OpenTerm.interpret_substitute nestedReplacement environment (replacement i))
      (fun i => ((replacement i).substitute nestedReplacement).inductInterpret
        Witness step environment alternateWitnesses)
      (fun i => (replacement i).inductInterpret Witness step
        (fun j => (nestedReplacement j).interpret environment)
        (fun j => (nestedReplacement j).inductInterpret
          Witness step environment alternateWitnesses))
      (fun i => OpenTerm.inductInterpret_substitute Witness step nestedReplacement environment
        alternateWitnesses (replacement i)) pattern)

noncomputable def composedRouteWitness
    (supplied : (i : Fin 2) → Witness (environment i)) :
    Witness (pattern.interpret
      (fun i => (replacement i).interpret
        (fun j => (nestedReplacement j).interpret environment))) :=
  Eq.mp (congrArg Witness
    (congrArg (fun env : Fin 2 → Carrier spec => pattern.interpret env)
      (funext (fun i => OpenTerm.interpret_substitute nestedReplacement environment
        (replacement i)))))
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
      (fun i => (replacement i).substitute nestedReplacement) environment pattern))
      (Eq.mp (congrArg Witness
        (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
          (OpenTerm.substitute_comp replacement nestedReplacement pattern)))
        (((pattern.substitute replacement).substitute nestedReplacement).inductInterpret
          Witness step environment supplied)))

theorem substitution_routes (supplied : (i : Fin 2) → Witness (environment i)) :
    sequentialWitness supplied = composedRouteWitness supplied :=
  OpenTerm.inductInterpret_substitute_comp_routes Witness step replacement nestedReplacement
    environment supplied pattern

theorem three_transport_route_annotation : (composedRouteWitness witnesses).2 = 10064 :=
  (congrArg Prod.snd (substitution_routes witnesses)).symm.trans nested_transport_annotation

theorem noninjective_renaming : collapse 0 = collapse 1 := rfl

theorem sequential_rename_annotation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename collapse
      (fun i => environment (embedSecond i)) pattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_rename embedSecond environment
        (pattern.rename collapse)))
        (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step
          environment witnesses))).2 = 473 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_seq Witness step collapse embedSecond environment
      witnesses pattern)

theorem composed_rename_annotation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_rename
      (fun i => embedSecond (collapse i)) environment pattern))
      (Eq.mp (congrArg Witness
        (congrArg (fun body : OpenTerm spec 2 => body.interpret environment)
          (OpenTerm.rename_comp collapse embedSecond pattern)))
        (((pattern.rename collapse).rename embedSecond).inductInterpret Witness step
          environment witnesses))).2 = 473 :=
  (congrArg Prod.snd
    (OpenTerm.inductInterpret_rename_comp_routes Witness step collapse embedSecond environment
      witnesses pattern)).symm.trans sequential_rename_annotation

theorem empty_context_substitution_annotation :
    (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
      (Fin.elim0 : Fin 0 → OpenTerm spec 0)
      (fun j : Fin 0 => (Fin.elim0 j : OpenTerm spec 0).interpret Fin.elim0) closedPattern))
      (Eq.mp (congrArg Witness (OpenTerm.interpret_substitute
        (Fin.elim0 : Fin 0 → OpenTerm spec 0) Fin.elim0
        (closedPattern.substitute Fin.elim0)))
        (((closedPattern.substitute Fin.elim0).substitute Fin.elim0).inductInterpret
          Witness step Fin.elim0 emptyWitnesses))).2 = 16 :=
  congrArg Prod.snd
    (OpenTerm.inductInterpret_substitute_seq Witness step
      (Fin.elim0 : Fin 0 → OpenTerm spec 0) (Fin.elim0 : Fin 0 → OpenTerm spec 0)
      Fin.elim0 emptyWitnesses closedPattern)

#print axioms composed_transport_retains_supplied_annotation
#print axioms nested_transport_certificate
#print axioms composed_endpoint_annotation
#print axioms explicit_environment_congruence
#print axioms substitution_routes
#print axioms three_transport_route_annotation
#print axioms sequential_rename_annotation
#print axioms composed_rename_annotation
#print axioms empty_context_substitution_annotation

end KanonCoherenceClient.Tests
