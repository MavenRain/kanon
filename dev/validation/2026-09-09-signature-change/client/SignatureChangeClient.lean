import KanonMeta

namespace SignatureChangeClient

open KanonMeta.Initiality

universe u s p a

variable {Index : Type u} {P Q R : Polynomial.{u, s, p} Index}
    {A : Algebra.{u, s, p, a} P} {B : Algebra.{u, s, p, a} Q}

/-- Downstream clients retain independent index, shape, position and carrier levels. -/
theorem composed (f : SignatureMap P Q) (g : SignatureMap Q R)
    (hA : Initial A) (hB : Initial B) (C : Algebra.{u, s, p, a} R)
    {i : Index} (x : A.Carrier i) :
    (g.translate hB C).map ((f.translate hA B).map x) = ((g.comp f).translate hA C).map x :=
  g.translate_comp f hA hB C x

theorem dependent (f : SignatureMap P Q) (hA : Initial A) (hB : Initial B)
    (E : Displayed B) {i : Index} (x : A.Carrier i) :
    elim hA ((f.restrictDisplayed E).pullback (f.translate hA B)) x =
      elim hB E ((f.translate hA B).map x) :=
  f.elim_translate hA hB E x

/-- Two indices have different carriers; the selected child changes with the result index. -/
def source : Polynomial Bool where
  Shape := fun (_i) => Unit
  Position := fun (_s) => Unit
  child := fun {i} (_s) (_p) => !i

def target : Polynomial Bool where
  Shape := fun (_i) => Unit
  Position := fun (_s) => Unit
  child := fun {i} (_s) (_p) => !i

def signature : SignatureMap source target where
  shape := fun s => s
  position := fun (_s) p => p
  child := fun (_s) (_p) => rfl

def family : Bool → Type := fun i => Fin (i.toNat + 2)

theorem false_child :
    (signature.children (X := family) (i := false) ()
      (fun (_p) => (⟨2, Nat.lt_succ_self 2⟩ : Fin 3)) ()).val = 2 := rfl

theorem true_child :
    (signature.children (X := family) (i := true) ()
      (fun (_p) => (⟨1, Nat.lt_succ_self 1⟩ : Fin 2)) ()).val = 1 := rfl

#print axioms composed
#print axioms dependent
#print axioms false_child
#print axioms true_child

end SignatureChangeClient
