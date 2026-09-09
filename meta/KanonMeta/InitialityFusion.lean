/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.Initiality

/-!
Constructor-preserving maps between displayed algebras commute with dependent
elimination. The base algebra stays fixed; fibres and carriers inhabit the
same universe as in `Initiality`. Constant fibres recover ordinary folds.
-/

namespace KanonMeta.Initiality

universe u s p a

variable {Index : Type u} {P : Polynomial.{u, s, p} Index}
    {A : Algebra.{u, s, p, a} P}

/-- A map of dependent witnesses over a fixed base that preserves constructors. -/
structure DisplayedHom (D E : Displayed A) where
  map : {i : Index} → (x : A.Carrier i) → D.Fibre x → E.Fibre x
  comm : ∀ {i : Index} (shape : P.Shape i) (xs) (witnesses),
    map (A.roll shape xs) (D.step shape xs witnesses) =
      E.step shape xs (fun pos => map (xs pos) (witnesses pos))

/-- The identity retains each dependent witness. -/
def DisplayedHom.id (D : Displayed A) : DisplayedHom D D where
  map := fun _ witness => witness
  comm := fun _ _ _ => rfl

/-- Compose witness maps without changing their base values. -/
def DisplayedHom.comp {D E F : Displayed A}
    (g : DisplayedHom E F) (f : DisplayedHom D E) : DisplayedHom D F where
  map := fun x witness => g.map x (f.map x witness)
  comm := fun shape xs witnesses =>
    (congrArg (g.map (A.roll shape xs)) (f.comm shape xs witnesses)).trans
      (g.comm shape xs (fun pos => f.map (xs pos) (witnesses pos)))

/-- A displayed map induces an ordinary map on the total algebras. -/
def DisplayedHom.totalHom {D E : Displayed A} (f : DisplayedHom D E) :
    Hom D.total E.total where
  map := fun pair => ⟨pair.1, f.map pair.1 pair.2⟩
  comm := fun shape xs => congrArg (Sigma.mk (A.roll shape (fun pos => (xs pos).1)))
    (f.comm shape (fun pos => (xs pos).1) (fun pos => (xs pos).2))

/-- Changing the base by equality commutes with a displayed witness map. -/
theorem DisplayedHom.map_transport {D E : Displayed A} (f : DisplayedHom D E)
    {i : Index} {x y : A.Carrier i} (equal : x = y) (witness : D.Fibre x) :
    f.map y (Eq.mp (congrArg D.Fibre equal) witness) =
      Eq.mp (congrArg E.Fibre equal) (f.map x witness) :=
  @Eq.rec (A.Carrier i) x (fun y equal =>
    f.map y (Eq.mp (congrArg D.Fibre equal) witness) =
      Eq.mp (congrArg E.Fibre equal) (f.map x witness)) rfl y equal

/-- Initiality forces every displayed map to preserve the chosen eliminator. -/
theorem elim_fusion (h : Initial A) {D E : Displayed A} (f : DisplayedHom D E)
    {i : Index} (x : A.Carrier i) : f.map x (elim h D x) = elim h E x :=
  eq_of_heq (Sigma.mk.inj
    ((congrArg f.totalHom.map (fold_eq_section h D x)).symm.trans
      ((h.unique E.total (f.totalHom.comp (h.fold D.total)) (h.fold E.total) x).trans
        (fold_eq_section h E x)))).2

/-- A second algebra supplies a displayed algebra whose fibres ignore the base. -/
def Displayed.constant (A B : Algebra.{u, s, p, a} P) : Displayed A where
  Fibre := fun {i} _ => B.Carrier i
  step := fun shape _ witnesses => B.roll shape witnesses

/-- Elimination into constant fibres is the ordinary initial fold. -/
theorem elim_constant (h : Initial A) (B : Algebra.{u, s, p, a} P)
    {i : Index} (x : A.Carrier i) :
    elim h (Displayed.constant A B) x = (h.fold B).map x :=
  (elim_unique h (Displayed.constant A B) (h.fold B).map (h.fold B).comm x).symm

end KanonMeta.Initiality
