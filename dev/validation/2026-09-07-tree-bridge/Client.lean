import KanonMeta

namespace TreeBridgeClient

open KanonMeta.MuTree

noncomputable section

def sample : Value := .fork .leaf (.fork .leaf .leaf)

theorem decode_sample : decode sample.encode = .ok sample := decode_encode sample

theorem fold_sample :
    semanticFold Nat 1 (fun left right => 2 * left + 3 * right) sample.interpret = 17 :=
  fold_interpret Nat 1 (fun left right => 2 * left + 3 * right) sample

theorem mirror_sample : semanticMirror sample.interpret = sample.mirror.interpret :=
  mirror_interpret sample

theorem mirror_weight :
    semanticFold Nat 1 (fun left right => 2 * left + 3 * right)
      (semanticMirror sample.interpret) = 13 :=
  (congrArg (semanticFold Nat 1 (fun left right => 2 * left + 3 * right))
    (mirror_interpret sample)).trans
      (fold_interpret Nat 1 (fun left right => 2 * left + 3 * right) sample.mirror)

theorem injective (left right : Value) (equal : left.interpret = right.interpret) :
    left = right := interpret_injective equal

#print axioms decode_sample
#print axioms fold_sample
#print axioms mirror_sample
#print axioms mirror_weight
#print axioms injective

end

end TreeBridgeClient
