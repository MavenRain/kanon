/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

The disclosure driver of gate SF-G4 and the conditional initiality bridge.
It prints the four syntax theorem reports followed by the bridge's public
eliminator and laws. The report is
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
