import KanonMeta

namespace VectorBridgeClient

open KanonMeta
open KanonMeta.MuVector

noncomputable section

def sample : Value 2 := .cons 17 (.cons 25 .nil)

theorem decode_sample : decode 2 sample.encode = .ok sample := decode_encode sample

theorem copy_sample : semanticCopy sample.interpret = sample.interpret :=
  semanticCopy_eq sample.interpret

theorem copy_interpretation : semanticCopy sample.interpret = sample.copy.interpret :=
  copy_interpret sample

theorem injective {n : Nat} (left right : Value n)
    (equal : left.interpret = right.interpret) : left = right := interpret_injective equal

def weightedAlgebra : Initiality.Algebra (VectorConstruction.polynomial Nat) where
  Carrier := fun (_n) => Nat
  roll := fun shape => match shape with
    | .inl .nil => fun (_children) => 0
    | .inr (.cons (_n) payload) => fun children => payload + 2 * children PUnit.unit

def weighted {n : Nat} (value : (VectorConstruction.recursive Nat).Carrier n) : Nat :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).map value

theorem weighted_nil : weighted VectorConstruction.nil = 0 :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).comm
    (.inl .nil) (fun position => nomatch position)

theorem weighted_cons {n : Nat} (payload : Nat)
    (tail : (VectorConstruction.recursive Nat).Carrier n) :
    weighted (VectorConstruction.cons payload tail) = payload + 2 * weighted tail :=
  ((VectorConstruction.recursiveInitial Nat).fold weightedAlgebra).comm
    (.inr (.cons n payload)) (fun (_position) => tail)

theorem sample_observation : weighted sample.interpret = 67 :=
  (weighted_cons 17 (VectorConstruction.cons 25 VectorConstruction.nil)).trans
    (congrArg (fun value => 17 + 2 * value)
      ((weighted_cons 25 VectorConstruction.nil).trans
        (congrArg (fun value => 25 + 2 * value) weighted_nil)))

theorem copy_observation : weighted (semanticCopy sample.interpret) = 67 :=
  (congrArg weighted copy_sample).trans sample_observation

#print axioms decode_sample
#print axioms copy_sample
#print axioms copy_interpretation
#print axioms injective
#print axioms sample_observation
#print axioms copy_observation

end

end VectorBridgeClient
