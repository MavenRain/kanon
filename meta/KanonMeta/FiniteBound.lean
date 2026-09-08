/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import Init

namespace KanonMeta.FiniteBound

/-- A common upper bound for a finite family of stage numbers, including
the empty family. No choice of representatives is involved. -/
def bound : {n : Nat} → (Fin n → Nat) → Nat
  | 0, _ => 0
  | n + 1, f => max (f 0) (bound (fun p : Fin n => f p.succ))

theorem le_bound : {n : Nat} → (f : Fin n → Nat) → (p : Fin n) → f p ≤ bound f
  | 0, _, p => Fin.elim0 p
  | n + 1, f, p => Fin.cases
      (Nat.le_max_left (f 0) (bound (fun q : Fin n => f q.succ)))
      (fun q => Nat.le_trans (le_bound (fun r : Fin n => f r.succ) q)
        (Nat.le_max_right (f 0) (bound (fun r : Fin n => f r.succ)))) p

end KanonMeta.FiniteBound
