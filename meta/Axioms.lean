/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

The disclosure driver of gate SF-G4 and the initiality developments.
It prints the six syntax theorem reports. It also prints the
natural-family group of `KanonMeta.MuNat`, the binary-tree group of
`KanonMeta.MuTree`, the indexed-vector group of `KanonMeta.MuVector`,
the finite-family group of `KanonMeta.MuFinitary`, its open
constructor group `KanonMeta.MuFinitary.OpenTerm`,
and the public initiality and initial-chain results. The report is
disclosure and not a zero-axioms gate: `propext`, `Classical.choice` and
`Quot.sound` are the three admissible names.

Run it with
`lake +leanprover/lean4:v4.33.0-rc1 --dir META env lean META/Axioms.lean`.
-/

import KanonMeta

#print axioms KanonMeta.bc_lan_smu
#print axioms KanonMeta.bc_ran_smu
#print axioms KanonMeta.MuNat.decode_encode
#print axioms KanonMeta.MuNat.encode_injective
#print axioms KanonMeta.MuNat.fold_interpret
#print axioms KanonMeta.MuNat.semanticFold_zero
#print axioms KanonMeta.MuNat.semanticFold_succ
#print axioms KanonMeta.MuNat.semanticFold_unique
#print axioms KanonMeta.MuNat.semanticCase_zero
#print axioms KanonMeta.MuNat.semanticCase_succ
#print axioms KanonMeta.MuNat.observe_interpret
#print axioms KanonMeta.MuNat.interpret_injective
#print axioms KanonMeta.MuNat.FoldProgram.run_interpret
#print axioms KanonMeta.MuNat.Value.fold_zero
#print axioms KanonMeta.MuNat.Value.fold_succ
#print axioms KanonMeta.MuNat.interpret_zero
#print axioms KanonMeta.MuNat.interpret_succ
#print axioms KanonMeta.MuNat.observe_zero
#print axioms KanonMeta.MuNat.observe_succ
#print axioms KanonMeta.MuNat.Value.toNat_injective
#print axioms KanonMeta.MuNat.interpret_separates
#print axioms KanonMeta.MuNat.semanticDouble_zero
#print axioms KanonMeta.MuNat.semanticDouble_succ
#print axioms KanonMeta.MuNat.double_interpret
#print axioms KanonMeta.MuNat.wrap_encode
#print axioms KanonMeta.MuNat.wrap_interpret
#print axioms KanonMeta.MuNat.FoldProgram.run_zero
#print axioms KanonMeta.MuNat.FoldProgram.run_succ
#print axioms KanonMeta.MuNat.FoldProgram.interpret_zero
#print axioms KanonMeta.MuNat.FoldProgram.interpret_succ
#print axioms KanonMeta.MuNat.doubleProgram_semantics

#print axioms KanonMeta.MuTree.decode_encode
#print axioms KanonMeta.MuTree.encode_injective
#print axioms KanonMeta.MuTree.Value.fold_leaf
#print axioms KanonMeta.MuTree.Value.fold_fork
#print axioms KanonMeta.MuTree.Value.fold_constructors
#print axioms KanonMeta.MuTree.recursiveInitial
#print axioms KanonMeta.MuTree.interpret_leaf
#print axioms KanonMeta.MuTree.interpret_fork
#print axioms KanonMeta.MuTree.semanticFold_leaf
#print axioms KanonMeta.MuTree.semanticFold_fork
#print axioms KanonMeta.MuTree.fold_interpret
#print axioms KanonMeta.MuTree.semanticFold_unique
#print axioms KanonMeta.MuTree.reify_interpret
#print axioms KanonMeta.MuTree.interpret_injective
#print axioms KanonMeta.MuTree.interpret_separates
#print axioms KanonMeta.MuTree.semanticMirror_leaf
#print axioms KanonMeta.MuTree.semanticMirror_fork
#print axioms KanonMeta.MuTree.mirror_interpret

#print axioms KanonMeta.MuVector.indexValue_toNat
#print axioms KanonMeta.MuVector.decodeIndex_indexTerm
#print axioms KanonMeta.MuVector.checkIndex_indexTerm
#print axioms KanonMeta.MuVector.decode_encode
#print axioms KanonMeta.MuVector.encode_injective
#print axioms KanonMeta.MuVector.Value.fold_nil
#print axioms KanonMeta.MuVector.Value.fold_cons
#print axioms KanonMeta.MuVector.Value.fold_constructors
#print axioms KanonMeta.MuVector.interpret_nil
#print axioms KanonMeta.MuVector.interpret_cons
#print axioms KanonMeta.MuVector.semanticFold_nil
#print axioms KanonMeta.MuVector.semanticFold_cons
#print axioms KanonMeta.MuVector.fold_interpret
#print axioms KanonMeta.MuVector.semanticFold_unique
#print axioms KanonMeta.MuVector.reify_interpret
#print axioms KanonMeta.MuVector.interpret_injective
#print axioms KanonMeta.MuVector.interpret_separates
#print axioms KanonMeta.MuVector.Value.copy_eq
#print axioms KanonMeta.MuVector.semanticCopy_eq
#print axioms KanonMeta.MuVector.copy_interpret

#print axioms KanonMeta.MuFinitary.Validated.supported
#print axioms KanonMeta.MuFinitary.validate_sound
#print axioms KanonMeta.MuFinitary.Value.fold_node
#print axioms KanonMeta.MuFinitary.Value.fold_constructors
#print axioms KanonMeta.MuFinitary.recursiveInitial
#print axioms KanonMeta.MuFinitary.semanticFold_node
#print axioms KanonMeta.MuFinitary.fold_interpret
#print axioms KanonMeta.MuFinitary.semanticFold_unique
#print axioms KanonMeta.MuFinitary.reify_interpret
#print axioms KanonMeta.MuFinitary.interpret_injective
#print axioms KanonMeta.MuFinitary.constructorName_injective
#print axioms KanonMeta.MuFinitary.encode_injective
#print axioms KanonMeta.MuFinitary.decode_encode
#print axioms KanonMeta.MuFinitary.decode_sound
#print axioms KanonMeta.MuFinitary.decoded_fold_interpret

open KanonMeta

#print axioms bc_lan_spi
#print axioms bc_ran_spi
#print axioms bc_lan_scoll
#print axioms bc_ran_scoll

#print axioms Initiality.projection_fold
#print axioms Initiality.elim
#print axioms Initiality.fold_eq_section
#print axioms Initiality.elim_beta
#print axioms Initiality.Displayed.sectionHom
#print axioms Initiality.elim_unique

#print axioms InitialChain.polyMap_id
#print axioms InitialChain.polyMap_comp
#print axioms InitialChain.roll_on_leg
#print axioms InitialChain.fold_comm
#print axioms InitialChain.hom_on_leg
#print axioms InitialChain.chainInitial
#print axioms InitialChain.chainElim
#print axioms InitialChain.chainElim_beta

#print axioms ChainColimit.cocone
#print axioms ChainColimit.isColimit
#print axioms ChainColimit.initialOfPreserves
#print axioms ChainColimit.respects
#print axioms ChainColimit.descend_on_leg

#print axioms NatConstruction.natPreserves
#print axioms NatConstruction.recursiveInitial
#print axioms NatConstruction.map_zero
#print axioms NatConstruction.zero_node
#print axioms NatConstruction.succ_node
#print axioms NatConstruction.zero_legs

#print axioms LinearConstruction.preserves
#print axioms LinearConstruction.recursiveInitial
#print axioms LinearConstruction.nullary_node
#print axioms LinearConstruction.unary_node
#print axioms LinearConstruction.map_nullary
#print axioms LinearConstruction.fibre_factor
#print axioms LinearConstruction.fibre_unique
#print axioms LinearConstruction.nullary_legs

#print axioms VectorConstruction.recursiveInitial
#print axioms VectorConstruction.copy_eq
#print axioms VectorConstruction.copy_nil
#print axioms VectorConstruction.copy_cons

#print axioms FinitaryConstruction.preserves
#print axioms FinitaryConstruction.recursive
#print axioms FinitaryConstruction.recursiveInitial
#print axioms FinitaryConstruction.node_eta
#print axioms FinitaryConstruction.synchronize
#print axioms FinitaryConstruction.representatives_respect
#print axioms FinitaryConstruction.descend
#print axioms FinitaryConstruction.descend_on_leg

#print axioms FiniteBound.bound
#print axioms FiniteBound.le_bound

#print axioms KanonMeta.MuFinitary.OpenTerm.rename_id
#print axioms KanonMeta.MuFinitary.OpenTerm.rename_comp
#print axioms KanonMeta.MuFinitary.OpenTerm.substitute_id
#print axioms KanonMeta.MuFinitary.OpenTerm.substitute_comp
#print axioms KanonMeta.MuFinitary.OpenTerm.rename_eq_substitute
#print axioms KanonMeta.MuFinitary.OpenTerm.encode_substitute
#print axioms KanonMeta.MuFinitary.OpenTerm.encode_rename
#print axioms KanonMeta.MuFinitary.OpenTerm.evaluate_substitute
#print axioms KanonMeta.MuFinitary.OpenTerm.interpret_substitute
#print axioms KanonMeta.MuFinitary.OpenTerm.evaluate_rename
#print axioms KanonMeta.MuFinitary.OpenTerm.interpret_rename
#print axioms KanonMeta.MuFinitary.OpenTerm.encode_injective
#print axioms KanonMeta.MuFinitary.OpenTerm.encode_ofValue
#print axioms KanonMeta.MuFinitary.OpenTerm.encode_close
#print axioms KanonMeta.MuFinitary.OpenTerm.close_ofValue
#print axioms KanonMeta.MuFinitary.OpenTerm.ofValue_close
#print axioms KanonMeta.MuFinitary.OpenTerm.evaluate_ofValue
#print axioms KanonMeta.MuFinitary.OpenTerm.evaluate_close
#print axioms KanonMeta.MuFinitary.OpenTerm.interpret_ofValue
#print axioms KanonMeta.MuFinitary.OpenTerm.interpret_close
#print axioms KanonMeta.MuFinitary.OpenTerm.fold_interpret
#print axioms KanonMeta.MuFinitary.OpenTerm.openDecode_encode
#print axioms KanonMeta.MuFinitary.OpenTerm.openDecode_sound
#print axioms KanonMeta.MuFinitary.OpenTerm.openDecode_accepts_iff
#print axioms KanonMeta.MuFinitary.OpenTerm.openDecode_zero_iff

#print axioms KanonMeta.MuFinitary.displayed
#print axioms KanonMeta.MuFinitary.semanticElim
#print axioms KanonMeta.MuFinitary.semanticElim_node
#print axioms KanonMeta.MuFinitary.semanticElim_unique
#print axioms KanonMeta.MuFinitary.Value.inductInterpret
#print axioms KanonMeta.MuFinitary.Value.semanticElim_interpret
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret
#print axioms KanonMeta.MuFinitary.OpenTerm.semanticElim_interpret
#print axioms KanonMeta.MuFinitary.interpret_reify
#print axioms KanonMeta.MuFinitary.reify_injective

#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_id
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename_id
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_comp
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename_comp

#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_congr
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_comp_coherent
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_seq
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_comp_routes
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename_seq
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename_comp_routes

#print axioms KanonMeta.Initiality.DisplayedHom
#print axioms KanonMeta.Initiality.DisplayedHom.id
#print axioms KanonMeta.Initiality.DisplayedHom.comp
#print axioms KanonMeta.Initiality.DisplayedHom.totalHom
#print axioms KanonMeta.Initiality.DisplayedHom.map_transport
#print axioms KanonMeta.Initiality.elim_fusion
#print axioms KanonMeta.Initiality.Displayed.constant
#print axioms KanonMeta.Initiality.elim_constant
#print axioms KanonMeta.MuFinitary.displayedHom
#print axioms KanonMeta.MuFinitary.semanticElim_fusion
#print axioms KanonMeta.MuFinitary.Value.inductInterpret_fusion
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_fusion
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_substitute_fusion
#print axioms KanonMeta.MuFinitary.OpenTerm.inductInterpret_rename_fusion
