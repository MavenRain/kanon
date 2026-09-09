import KanonMeta

namespace BaseChangeClient

open KanonMeta.Initiality

def signature : Polynomial Bool where
  Shape := fun (_i) => Unit
  Position := fun (_shape) => Empty
  child := fun (_shape) pos => nomatch pos

def source : Algebra signature where
  Carrier := fun (_i) => Unit
  roll := fun (_shape) (_xs) => ()

def sourceFold (B : Algebra signature) : Hom source B where
  map := fun (_x) => B.roll () (fun pos => nomatch pos)
  comm := fun shape => match shape with
    | () => fun (_xs) => congrArg (B.roll ()) (funext (fun pos => nomatch pos))

def sourceInitial : Initial source where
  fold := sourceFold
  unique := fun B f g {i} x =>
    PUnit.rec ((f.comm (i := i) () (fun pos => nomatch pos)).trans
      ((congrArg (B.roll ()) (funext (fun pos => nomatch pos))).trans
        (g.comm (i := i) () (fun pos => nomatch pos)).symm)) x

def offset (i : Bool) : Nat := if i then 13 else 5

/-- The target includes values outside the image of its nullary constructor. -/
def target : Algebra signature where
  Carrier := fun (_i) => Nat
  roll := fun {i} (_shape) (_xs) => offset i

def changeBase : Hom source target where
  map := fun {i} (_x) => offset i
  comm := fun (_shape) (_xs) => rfl

def witness (n : Nat) : Fin (n + 1) × Nat := (⟨n, Nat.lt_succ_self n⟩, n + 100)

def display : Displayed target where
  Fibre := fun (n : Nat) => Fin (n + 1) × Nat
  step := fun {i} (_shape) (_xs) (_ih) => witness (offset i)

theorem witness_comm {i : Bool} (shape : signature.Shape i) (xs) :
    witness (target.roll shape xs) = display.step shape xs (fun pos => witness (xs pos)) := rfl

theorem result (i : Bool) :
    elim sourceInitial (display.pullback changeBase) (i := i) () = witness (offset i) :=
  elim_pullback_section sourceInitial changeBase display witness witness_comm ()

theorem false_certificate :
    (elim sourceInitial (display.pullback changeBase) (i := false) ()).1.val = 5 :=
  congrArg (fun value => value.1.val) (result false)

theorem true_certificate :
    (elim sourceInitial (display.pullback changeBase) (i := true) ()).1.val = 13 :=
  congrArg (fun value => value.1.val) (result true)

theorem false_annotation :
    (elim sourceInitial (display.pullback changeBase) (i := false) ()).2 = 105 :=
  congrArg Prod.snd (result false)

theorem true_annotation :
    (elim sourceInitial (display.pullback changeBase) (i := true) ()).2 = 113 :=
  congrArg Prod.snd (result true)

#print axioms result
#print axioms true_annotation

end BaseChangeClient
