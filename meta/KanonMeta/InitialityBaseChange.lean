/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityFusion

/-!
Pull back displayed algebras along constructor-preserving base maps. The
constructor equality determines the direction of witness transport. Identity
and composition preserve witnesses, and initiality gives elimination naturality.
Indices, shapes and positions have independent universes; carriers and fibres
share the existing carrier universe. The results are propositional.
-/

namespace KanonMeta.Initiality

universe u s p a

variable {Index : Type u} {P : Polynomial.{u, s, p} Index}
    {A B C : Algebra.{u, s, p, a} P}

private theorem cast_comp {X Y Z : Type a} (first : X = Y) (second : Y = Z) (x : X) :
    Eq.mp second (Eq.mp first x) = Eq.mp (first.trans second) x :=
  @Eq.rec (Type a) X (fun Y first => ∀ second : Y = Z,
    Eq.mp second (Eq.mp first x) = Eq.mp (first.trans second) x)
    (fun _second => rfl) Y first second

/-- The pullback fibre over `x` is the target fibre over its mapped base value. -/
def Displayed.pullback (E : Displayed B) (f : Hom A B) : Displayed A where
  Fibre := fun x => E.Fibre (f.map x)
  step := fun shape xs witnesses =>
    Eq.mp (congrArg E.Fibre (f.comm shape xs).symm)
      (E.step shape (fun pos => f.map (xs pos)) witnesses)

/-- Identity base change preserves the witness itself. It is definitional:
`D.pullback (Hom.id A)` reduces to `D`, so this map acts as `DisplayedHom.id D`. -/
def Displayed.pullbackId (D : Displayed A) :
    DisplayedHom (D.pullback (Hom.id A)) D where
  map := fun _x witness => witness
  comm := fun _shape _xs _witnesses => rfl

/-- Successive base changes agree with the composed base change on witnesses. -/
def Displayed.pullbackComp (E : Displayed C) (f : Hom A B) (g : Hom B C) :
    DisplayedHom ((E.pullback g).pullback f) (E.pullback (g.comp f)) where
  map := fun _x witness => witness
  comm := fun shape xs witnesses =>
    cast_comp (congrArg E.Fibre (g.comm shape (fun pos => f.map (xs pos))).symm)
      (congrArg (fun x => E.Fibre (g.map x)) (f.comm shape xs).symm)
      (E.step shape (fun pos => g.map (f.map (xs pos))) witnesses)

/-- Pulling back a displayed map retains its action at every mapped base value. -/
def DisplayedHom.pullback (f : Hom A B) {D E : Displayed B} (h : DisplayedHom D E) :
    DisplayedHom (D.pullback f) (E.pullback f) where
  map := fun x witness => h.map (f.map x) witness
  comm := fun shape xs witnesses =>
    (h.map_transport (f.comm shape xs).symm
      (D.step shape (fun pos => f.map (xs pos)) witnesses)).trans
      (congrArg (Eq.mp (congrArg E.Fibre (f.comm shape xs).symm))
        (h.comm shape (fun pos => f.map (xs pos)) witnesses))

/-- A displayed map over a possibly different base algebra. -/
abbrev DisplayedHomOver (f : Hom A B) (D : Displayed A) (E : Displayed B) :=
  DisplayedHom D (E.pullback f)

/-- Identity acts on both the base and the supplied witness. -/
def DisplayedHomOver.id (D : Displayed A) : DisplayedHomOver (Hom.id A) D D :=
  DisplayedHom.id D

/-- Compose displayed maps while composing their base maps. -/
def DisplayedHomOver.comp {f : Hom A B} {g : Hom B C}
    {D : Displayed A} {E : Displayed B} {F : Displayed C}
    (q : DisplayedHomOver g E F) (r : DisplayedHomOver f D E) :
    DisplayedHomOver (g.comp f) D F :=
  (F.pullbackComp f g).comp ((q.pullback f).comp r)

/-- A dependent section commutes with transport between its base values. -/
theorem Displayed.section_transport (E : Displayed B)
    (choose : {i : Index} → (x : B.Carrier i) → E.Fibre x)
    {i : Index} {x y : B.Carrier i} (equal : x = y) :
    Eq.mp (congrArg E.Fibre equal) (choose x) = choose y :=
  @Eq.rec (B.Carrier i) x (fun y equal =>
    Eq.mp (congrArg E.Fibre equal) (choose x) = choose y) rfl y equal

/-- A lawful target section pulls back to the chosen source eliminator.
Only the source algebra must be initial. -/
theorem elim_pullback_section (hA : Initial A) (f : Hom A B) (E : Displayed B)
    (choose : {i : Index} → (x : B.Carrier i) → E.Fibre x)
    (comm : ∀ {i : Index} (shape : P.Shape i) (xs),
      choose (B.roll shape xs) = E.step shape xs (fun pos => choose (xs pos)))
    {i : Index} (x : A.Carrier i) :
    elim hA (E.pullback f) x = choose (f.map x) :=
  (elim_unique hA (E.pullback f) (fun x => choose (f.map x))
    (fun shape xs =>
      (E.section_transport choose (f.comm shape xs).symm).symm.trans
        (congrArg (Eq.mp (congrArg E.Fibre (f.comm shape xs).symm))
          (comm shape (fun pos => f.map (xs pos))))) x).symm

/-- Dependent elimination commutes with maps between initial base algebras. -/
theorem elim_pullback (hA : Initial A) (hB : Initial B)
    (f : Hom A B) (E : Displayed B) {i : Index} (x : A.Carrier i) :
    elim hA (E.pullback f) x = elim hB E (f.map x) :=
  elim_pullback_section hA f E (elim hB E) (elim_beta hB E) x

/-- Fusion permits a constructor-preserving change of base as well as witness. -/
theorem elim_fusion_over (hA : Initial A) (hB : Initial B)
    {f : Hom A B} {D : Displayed A} {E : Displayed B}
    (hom : DisplayedHomOver f D E) {i : Index} (x : A.Carrier i) :
    hom.map x (elim hA D x) = elim hB E (f.map x) :=
  (elim_fusion hA hom x).trans (elim_pullback hA hB f E x)

/-- Identity base change leaves dependent elimination unchanged. Both sides
reduce to the same term, so this law also holds by `rfl`. The proof routes
through `pullbackId`, and `hA` keeps the statement form of the other laws. -/
theorem elim_pullback_id (hA : Initial A) (D : Displayed A)
    {i : Index} (x : A.Carrier i) :
    elim hA (D.pullback (Hom.id A)) x = elim hA D x :=
  elim_fusion hA D.pullbackId x

/-- Eliminating through successive pullbacks equals the composed route.
The intermediate and target algebras need not be initial. -/
theorem elim_pullback_comp (hA : Initial A) (f : Hom A B) (g : Hom B C)
    (E : Displayed C) {i : Index} (x : A.Carrier i) :
    elim hA ((E.pullback g).pullback f) x = elim hA (E.pullback (g.comp f)) x :=
  elim_fusion hA (E.pullbackComp f g) x

end KanonMeta.Initiality
