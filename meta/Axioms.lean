/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

The disclosure driver of gate SF-G4 and the initiality developments.
It prints the four syntax theorem reports followed by the public
initiality and initial-chain results. The report is
disclosure and not a zero-axioms gate: `propext`, `Classical.choice` and
`Quot.sound` are the three admissible names.

Run it with
`lake +leanprover/lean4:v4.33.0-rc1 --dir META env lean META/Axioms.lean`.
-/

import KanonMeta

open KanonMeta

#print axioms bc_lan_spi
#print axioms bc_ran_spi
#print axioms bc_lan_scoll
#print axioms bc_ran_scoll

#print axioms Initiality.projection_fold
#print axioms Initiality.elim
#print axioms Initiality.fold_eq_section
#print axioms Initiality.elim_beta

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
