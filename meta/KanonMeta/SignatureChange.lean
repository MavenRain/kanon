/-
Copyright (c) 2026 Onyeka Obi. All rights reserved.
Released under MIT OR Apache 2.0 license.
-/

import KanonMeta.InitialityBaseChange

/-!
Change an indexed polynomial signature over a fixed index type. Shapes map
forward and recursive positions map backward, with an explicit child-index
equality. Position maps may permute, repeat or discard source children; they
are not assumed bijective. Restriction changes constructor operations while
retaining carriers. Initiality then supplies translation and dependent laws.
No initiality of a restricted target algebra is assumed.
-/

namespace KanonMeta.Initiality

universe u s p a

variable {Index : Type u} {P Q R : Polynomial.{u, s, p} Index}

/-- An indexed container map: output constructors select source children. -/
structure SignatureMap (P Q : Polynomial.{u, s, p} Index) where
  shape : {i : Index} → P.Shape i → Q.Shape i
  position : {i : Index} → (s : P.Shape i) → Q.Position (shape s) → P.Position s
  child : ∀ {i : Index} (s : P.Shape i) (q : Q.Position (shape s)),
    P.child s (position s q) = Q.child (shape s) q

/-- The identity keeps every constructor and recursive position. -/
def SignatureMap.id (P : Polynomial.{u, s, p} Index) : SignatureMap P P where
  shape := fun s => s
  position := fun (_s) q => q
  child := fun (_s) (_q) => rfl

/-- Compose constructor selection and the reverse maps on recursive positions. -/
def SignatureMap.comp (g : SignatureMap Q R) (f : SignatureMap P Q) : SignatureMap P R where
  shape := fun s => g.shape (f.shape s)
  position := fun s r => f.position s (g.position (f.shape s) r)
  child := fun s r => (f.child s (g.position (f.shape s) r)).trans (g.child (f.shape s) r)

private theorem transport_map {X Y : Index → Type a}
    (f : {i : Index} → X i → Y i) {i j : Index} (e : i = j) (x : X i) :
    f (e ▸ x) = e ▸ f x :=
  @Eq.rec Index i (fun (_j) e => f (e ▸ x) = e ▸ f x) rfl j e

private theorem transport_comp {X : Index → Type a} {i j k : Index}
    (e : i = j) (d : j = k) (x : X i) : d ▸ (e ▸ x) = e.trans d ▸ x :=
  @Eq.rec Index i (fun j e => ∀ d : j = k, d ▸ (e ▸ x) = e.trans d ▸ x)
    (fun (_d) => rfl) j e d

/-- Rearrange recursive children and transport each to its required index. -/
def SignatureMap.children (f : SignatureMap P Q) {X : Index → Type a}
    {i : Index} (s : P.Shape i) (xs : (p : P.Position s) → X (P.child s p)) :
    (q : Q.Position (f.shape s)) → X (Q.child (f.shape s) q) :=
  fun q => f.child s q ▸ xs (f.position s q)

/-- Rearranging children commutes with any indexed map of their values. -/
theorem SignatureMap.children_map (f : SignatureMap P Q) {X Y : Index → Type a}
    (h : {i : Index} → X i → Y i) {i : Index} (s : P.Shape i) (xs) :
    (fun q => h (f.children (X := X) s xs q)) =
      f.children (X := Y) s (fun p => h (xs p)) :=
  funext (fun q => transport_map (X := X) (Y := Y) (@h) (f.child s q) (xs (f.position s q)))

/-- Successive rearrangements agree with the composed signature map. -/
theorem SignatureMap.children_comp (g : SignatureMap Q R) (f : SignatureMap P Q)
    {X : Index → Type a} {i : Index} (s : P.Shape i)
    (xs : (p : P.Position s) → X (P.child s p)) :
    g.children (f.shape s) (f.children s xs) = (g.comp f).children s xs :=
  funext (fun r => transport_comp (f.child s (g.position (f.shape s) r))
    (g.child (f.shape s) r) (xs (f.position s (g.position (f.shape s) r))))

/-- Interpret source constructors using their selected target constructors. -/
def SignatureMap.restrict (f : SignatureMap P Q) (B : Algebra.{u, s, p, a} Q) : Algebra P where
  Carrier := B.Carrier
  roll := fun s xs => B.roll (f.shape s) (f.children s xs)

/-- A target algebra map also preserves the restricted source operations. -/
def SignatureMap.restrictHom (f : SignatureMap P Q)
    {B C : Algebra.{u, s, p, a} Q} (h : Hom B C) : Hom (f.restrict B) (f.restrict C) where
  map := h.map
  comm := fun s xs => (h.comm (f.shape s) (f.children s xs)).trans
    (congrArg (C.roll (f.shape s)) (f.children_map (X := B.Carrier) (Y := C.Carrier) (@h.map) s xs))

/-- Restriction along the identity retains the carrier and constructor values. -/
def SignatureMap.restrictId (B : Algebra.{u, s, p, a} P) : Hom ((SignatureMap.id P).restrict B) B where
  map := fun x => x
  comm := fun (_s) (_xs) => rfl

/-- Restricting twice agrees with the composite on every carrier value. -/
def SignatureMap.restrictComp (g : SignatureMap Q R) (f : SignatureMap P Q)
    (C : Algebra.{u, s, p, a} R) : Hom (f.restrict (g.restrict C)) ((g.comp f).restrict C) where
  map := fun x => x
  comm := fun s xs => congrArg (C.roll (g.shape (f.shape s))) (g.children_comp f s xs)

private def transport_witness {X : Index → Type a}
    (F : {i : Index} → X i → Type a) {i j : Index} (e : i = j)
    (x : X i) (w : F x) : F (e ▸ x) :=
  @Eq.rec Index i (fun (_j) e => F (e ▸ x)) w j e

private theorem transport_section {X : Index → Type a}
    (F : {i : Index} → X i → Type a)
    (choose : {i : Index} → (x : X i) → F x)
    {i j : Index} (e : i = j) (x : X i) :
    transport_witness (X := X) (@F) e x (choose x) = choose (e ▸ x) :=
  @Eq.rec Index i (fun (_j) e =>
    transport_witness (X := X) (@F) e x (choose x) = choose (e ▸ x)) rfl j e

/-- Restrict a dependent constructor operation, retaining its actual witnesses. -/
def SignatureMap.restrictDisplayed (f : SignatureMap P Q)
    {B : Algebra.{u, s, p, a} Q} (E : Displayed B) : Displayed (f.restrict B) where
  Fibre := E.Fibre
  step := fun s xs witnesses => E.step (f.shape s) (f.children s xs)
    (fun q => transport_witness (X := B.Carrier) (@E.Fibre) (f.child s q)
      (xs (f.position s q)) (witnesses (f.position s q)))

/-- A lawful target section remains lawful for the restricted signature. -/
theorem SignatureMap.restrict_section (f : SignatureMap P Q)
    {B : Algebra.{u, s, p, a} Q} (E : Displayed B)
    (choose : {i : Index} → (x : B.Carrier i) → E.Fibre x)
    (comm : ∀ {i : Index} (s : Q.Shape i) (xs),
      choose (B.roll s xs) = E.step s xs (fun q => choose (xs q)))
    {i : Index} (s : P.Shape i) (xs) :
    choose ((f.restrict B).roll s xs) =
      (f.restrictDisplayed E).step s xs (fun p => choose (xs p)) :=
  (comm (f.shape s) (f.children s xs)).trans
    (congrArg (E.step (f.shape s) (f.children s xs))
      (funext (fun q => (transport_section (X := B.Carrier) (@E.Fibre) (@choose) (f.child s q)
        (xs (f.position s q))).symm)))

variable {A : Algebra.{u, s, p, a} P}

/-- Translate out of an initial source by folding into a restricted target. -/
def SignatureMap.translate (f : SignatureMap P Q) (hA : Initial A)
    (B : Algebra.{u, s, p, a} Q) : Hom A (f.restrict B) := hA.fold (f.restrict B)

/-- Translation maps a source constructor and its selected recursive children. -/
theorem SignatureMap.translate_beta (f : SignatureMap P Q) (hA : Initial A)
    (B : Algebra.{u, s, p, a} Q) {i : Index} (s : P.Shape i) (xs) :
    (f.translate hA B).map (A.roll s xs) =
      B.roll (f.shape s) (f.children s (fun p => (f.translate hA B).map (xs p))) :=
  (f.translate hA B).comm s xs

/-- Translation is unique among maps satisfying the translated constructor law. -/
theorem SignatureMap.translate_unique (f : SignatureMap P Q) (hA : Initial A)
    (B : Algebra.{u, s, p, a} Q) (h : Hom A (f.restrict B))
    {i : Index} (x : A.Carrier i) : h.map x = (f.translate hA B).map x :=
  hA.unique (f.restrict B) h (f.translate hA B) x

/-- Folding after translation agrees with translating directly into the target. -/
theorem SignatureMap.translate_fusion (f : SignatureMap P Q) (hA : Initial A)
    {B C : Algebra.{u, s, p, a} Q} (h : Hom B C) {i : Index} (x : A.Carrier i) :
    h.map ((f.translate hA B).map x) = (f.translate hA C).map x :=
  f.translate_unique hA C ((f.restrictHom h).comp (f.translate hA B)) x

/-- Translating the identity signature returns the original value. -/
theorem SignatureMap.translate_id (hA : Initial A) {i : Index} (x : A.Carrier i) :
    ((SignatureMap.id P).translate hA A).map x = x :=
  hA.unique A ((SignatureMap.restrictId A).comp ((SignatureMap.id P).translate hA A))
    (Hom.id A) x

/-- Two translations equal the composed translation; only the first two
algebras need initiality, and the final target may be arbitrary. -/
theorem SignatureMap.translate_comp (g : SignatureMap Q R) (f : SignatureMap P Q)
    (hA : Initial A) {B : Algebra.{u, s, p, a} Q} (hB : Initial B)
    (C : Algebra.{u, s, p, a} R) {i : Index} (x : A.Carrier i) :
    (g.translate hB C).map ((f.translate hA B).map x) = ((g.comp f).translate hA C).map x :=
  (g.comp f).translate_unique hA C
    ((g.restrictComp f C).comp ((f.restrictHom (g.translate hB C)).comp (f.translate hA B))) x

/-- Dependent elimination after signature translation agrees with any lawful
target section. The restricted target need not be initial. -/
theorem SignatureMap.elim_translate_section (f : SignatureMap P Q) (hA : Initial A)
    {B : Algebra.{u, s, p, a} Q} (E : Displayed B)
    (choose : {i : Index} → (x : B.Carrier i) → E.Fibre x)
    (comm : ∀ {i : Index} (s : Q.Shape i) (xs),
      choose (B.roll s xs) = E.step s xs (fun q => choose (xs q)))
    {i : Index} (x : A.Carrier i) :
    elim hA ((f.restrictDisplayed E).pullback (f.translate hA B)) x =
      choose ((f.translate hA B).map x) :=
  elim_pullback_section hA (f.translate hA B) (f.restrictDisplayed E) choose
    (f.restrict_section E choose comm) x

/-- Dependent elimination is natural between initial algebras of different signatures. -/
theorem SignatureMap.elim_translate (f : SignatureMap P Q) (hA : Initial A)
    {B : Algebra.{u, s, p, a} Q} (hB : Initial B) (E : Displayed B)
    {i : Index} (x : A.Carrier i) :
    elim hA ((f.restrictDisplayed E).pullback (f.translate hA B)) x =
      elim hB E ((f.translate hA B).map x) :=
  f.elim_translate_section hA E (elim hB E) (elim_beta hB E) x

end KanonMeta.Initiality
