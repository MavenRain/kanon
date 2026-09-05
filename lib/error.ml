(** Kernel and surface errors.  Stage B extends this sum with the check
    errors;  every consumer matches it exhaustively, so a new arm is a
    compile error at every reader before it is a silent fallthrough.

    [Not_yet] carries a milestone name, plan section 5:  rules.ml returns
    it for a shape that M0 does not admit, and the parser returns it
    through [Parse] for a surface word that M0 reserves.

    [message] returns the bare text and [to_string] adds the position, so
    a test can compare the text a producer chose without also fixing the
    position format. *)

type t =
  | Not_yet of string
  | Parse of string * int * int
  | Carry of string

let message (e : t) : string =
  match e with
  | Not_yet m -> m
  | Parse (m, _, _) -> m
  | Carry m -> m

let to_string (e : t) : string =
  match e with
  | Not_yet m -> "not yet: " ^ m
  | Parse (m, line, column) -> Printf.sprintf "line %d, column %d: %s" line column m
  | Carry m -> "carry: " ^ m
