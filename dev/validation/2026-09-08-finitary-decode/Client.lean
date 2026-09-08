import KanonMeta

namespace Client

open KanonMeta KanonMeta.MuFinitary

def spec : Spec := ⟨"Signal", [⟨"off", []⟩, ⟨"on", []⟩,
  ⟨"bundle", ["first", "second", "third", "fourth"]⟩]⟩

def off : Term := .intro (family "Signal") (.actor "off") []
def on : Term := .intro (family "Signal") (.actor "on") []
def raw : Term := .intro (family "Signal") (.actor "bundle") [off, on, on, off]

def checked : Validated spec.declaration := ⟨spec, of_decide_eq_true rfl, rfl⟩

example : validate spec.declaration = .ok checked := rfl

example : (decode spec raw).map (fun decoded => decoded.value.encode) = .ok raw := rfl

theorem exact_input (decoded : Decoded spec raw) : raw = decoded.value.encode :=
  decoded.agreement

theorem arbitrary_value_roundtrip (value : Value spec) :
    decode spec value.encode = .ok ⟨value, rfl⟩ := decode_encode checked.valid value

theorem distinct_encodings (left right : Value spec)
    (equal : left.encode = right.encode) : left = right :=
  encode_injective checked.valid equal

theorem semantic_observation (decoded : Decoded spec raw) :
    semanticFold spec Nat (fun ctor (_children) => ctor.val) decoded.value.interpret =
      decoded.value.fold (fun ctor (_children) => ctor.val) :=
  fold_interpret Nat (fun ctor (_children) => ctor.val) decoded.value

example : (decode spec
    (.intro (family "Signal") (.actor "bundle") [off, on])).map
      (fun decoded => decoded.value.encode) = .error (.wrongArity "bundle" 4 2) := rfl

#print axioms exact_input
#print axioms semantic_observation
#print axioms arbitrary_value_roundtrip
#print axioms distinct_encodings

end Client
