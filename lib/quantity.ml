(* carried from tot 8cf0b8b lib/quantity.ml, delta: this header line, and the third mark One between Zero and Many with its mul, equal and to_string arms (SB-D3) *)
(** Usage marks for the 0/1/omega fragment of QTT. [Zero] binders exist
    only at check time (types, proofs) and erase before evaluation.
    [One] is the linear mark: the surface reads it from the '1' binder
    mark and the M0 checker counts it as [Many] (SB-D3), so the linear
    counter is an M1 obligation, listed in SPEC.md section 10.  [Many]
    binders are runtime data. *)

type t =
  | Zero
  | One
  | Many

(** [Zero] absorbs, [One] is the unit and [Many] is the result of every
    other pair. *)
let mul (a : t) (b : t) : t =
  match (a, b) with
  | Zero, Zero -> Zero
  | Zero, One -> Zero
  | Zero, Many -> Zero
  | One, Zero -> Zero
  | Many, Zero -> Zero
  | One, One -> One
  | One, Many -> Many
  | Many, One -> Many
  | Many, Many -> Many

let equal (a : t) (b : t) : bool =
  match (a, b) with
  | Zero, Zero -> true
  | One, One -> true
  | Many, Many -> true
  | Zero, One -> false
  | Zero, Many -> false
  | One, Zero -> false
  | One, Many -> false
  | Many, Zero -> false
  | Many, One -> false

let to_string (q : t) : string =
  match q with
  | Zero -> "0"
  | One -> "1"
  | Many -> "w"
