(** The shape sum.  Plan section 4 declares it whole at Stage A and the
    later arms are refused by their milestone name (D-M0-2), so the closed
    grammar is visible in SPEC.md from the first commit.

    SA-D5: the type is polymorphic in the kernel term, so term.ml carries
    no shape name and the R0-AUDIT gate leg runs from Stage A.  This
    module and pp.ml are the only two files in lib/ that spell a shape
    name;  rules.ml joins them at Stage B. *)

type 'a t =
  | SPi of Quantity.t * string * 'a
  | SColl of int
  | SPar of 'a * 'a
  | SMu of string * 'a list
  | SNu of string * 'a list

(** The five declared shapes, in the order of the sum above.  spec_count.ml
    prints the length of this list, so a sixth shape moves the R0 count. *)
let declared : string list = [ "SPi"; "SColl"; "SPar"; "SMu"; "SNu" ]

(** The two shapes admitted at M0 (R-Q2).  The other three are refused by
    rules.ml at Stage B with their milestone name. *)
let admitted : string list = [ "SPi"; "SColl" ]

let name (s : 'a t) : string =
  match s with
  | SPi (_, _, _) -> "SPi"
  | SColl _ -> "SColl"
  | SPar (_, _) -> "SPar"
  | SMu (_, _) -> "SMu"
  | SNu (_, _) -> "SNu"
