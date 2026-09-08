import KanonMeta

open KanonMeta

universe u

noncomputable def publicInitial {Index : Type u} (Q : FinitaryConstruction.Signature Index) :
    Initiality.Initial (FinitaryConstruction.recursive Q) :=
  FinitaryConstruction.recursiveInitial Q

noncomputable def publicPreservation {Index : Type u} (Q : FinitaryConstruction.Signature Index)
    (S : InitialChain.Sequence Index) :
    InitialChain.Colimit (InitialChain.mappedCocone Q.polynomial (ChainColimit.cocone S)) :=
  FinitaryConstruction.preserves Q S

theorem publicDependentBeta {Index : Type u} (Q : FinitaryConstruction.Signature Index)
    (D : Initiality.Displayed (FinitaryConstruction.recursive Q)) {i : Index}
    (shape : Q.polynomial.Shape i)
    (xs : (p : Q.polynomial.Position shape) →
      (FinitaryConstruction.recursive Q).Carrier (Q.polynomial.child shape p)) :
    Initiality.elim (publicInitial Q) D ((FinitaryConstruction.recursive Q).roll shape xs) =
      D.step shape xs (fun p => Initiality.elim (publicInitial Q) D (xs p)) :=
  Initiality.elim_beta (publicInitial Q) D shape xs

#check FinitaryConstruction.node
#print axioms publicInitial
#print axioms publicPreservation
#print axioms publicDependentBeta
