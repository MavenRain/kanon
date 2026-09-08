import KanonMeta

namespace MuBridgeClient

open KanonMeta KanonMeta.MuNat

def decodeChecked (declaration : Declaration) (supported : declaration.Supported)
    (term : Term) : Except DecodeError (CheckedValue declaration) :=
  checkedDecode declaration supported term

theorem roundtrip (value : Value) : decode value.encode = .ok value :=
  decode_encode value

theorem foldCorrespondence (program : FoldProgram) (value : Value) :
    program.interpret value.interpret = (program.run value).interpret :=
  program.run_interpret value

theorem separation {left right : Value} (different : left ≠ right) :
    left.interpret ≠ right.interpret := interpret_separates different

#print axioms roundtrip
#print axioms foldCorrespondence
#print axioms separation

end MuBridgeClient
