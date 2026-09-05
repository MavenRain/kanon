(** The M0 surface tree and its printer (SA-D2).  One constructor per
    production of SPEC.md section 9, plus application (SA-D1) and auto
    (SA-D3).  No node holds a position, so two trees compare with
    structural equality and the round-trip test needs no position
    normalisation.

    Mirrors kan-lang-tot-pin/surface/syntax.ml:1-105 for the layout of
    the tree and for [Loc]-free reading of a branch as a triple.  tot's
    positions, its data and class items and its IO sugar have no M0
    production and are left out.

    No constructor here spells a shape name, and no production is a
    former:  every form below maps to one kernel constructor through the
    sugar table of SPEC.md section 7. *)

(** The five nat primitives of plan section 8, one constructor each, so
    a match over them is exhaustive and no name is a bare string. *)
type prim =
  | PAdd
  | PSub
  | PMul
  | PEq
  | PLt

(** A binder, SPEC.md section 9:  "(" mark? name ":" term ")".  SA-D17:
    the mark "0" is [Quantity.Zero] and an absent mark is
    [Kanon_kernel.Quantity.Many].  SB-D3:  Stage B gives the mark "1"
    its own reading, [Kanon_kernel.Quantity.One], which the M0 checker
    counts as [Many] and the printer writes back as "1 ". *)
type binder = {
  b_q : Kanon_kernel.Quantity.t;
  b_name : string;
  b_ty : t;
}

(** A case motive, "as x return P".  The kernel motive carries an
    inductive name and an index telescope;  neither has an M0
    production, so the surface motive is the self name and the body. *)
and motive = {
  mo_self : string;
  mo_body : t;
}

(** A case branch, "| k binder* => body".  The key is the leg number,
    which the elaborator reads as the leg address at Stage B. *)
and branch = {
  br_leg : int;
  br_binders : binder list;
  br_body : t;
}

and t =
  | SVar of string
  | SNat of int
  | SProp
  | SType of int
  | SPrim of prim
  | SUnit
  | SAuto
  | SPair of t * t
  | STuple of t list
  | SSum of t list
      (** SB-D1.  [sum (A1, .., An)] is the left former at the
          collection shape over the diagram of its items, and the empty
          form [sum ()] takes its universe from an annotation. *)
  | SProd of t list  (** SB-D1.  The right former at the same shape. *)
  | SProj of t * int
      (** SA-D16.  One projection node for ".1", ".2" and ".k":  the
          three spell the same text for the same leg and the sugar
          table's two rows differ by the type of the scrutinee, which
          Stage B's elaborator reads and Stage A does not have. *)
  | SInj of int * int * t
  | SAbsurd of t
  | SApp of t * t
  | SFun of binder list * t
  | SArrow of binder * t
  | SStar of binder * t
  | SLet of string * t * t * t
  | SAnn of t * t
  | SCase of t * motive option * branch list

type decl =
  | DDef of string * t * t
  | DAxiom of string * t

let prim_name (p : prim) : string =
  match p with
  | PAdd -> "natAdd"
  | PSub -> "natSub"
  | PMul -> "natMul"
  | PEq -> "natEq"
  | PLt -> "natLt"

(** Printing levels, loosest first, SPEC.md section 9.  Level 0 is a
    whole term, level 1 an application and level 2 an atom.  A node
    printed where a tighter level is wanted takes parentheses, which is
    the whole of the round-trip discipline:  [print] never emits text
    that re-parses to another tree. *)
let level_of (s : t) : int =
  match s with
  | SVar _ -> 2
  | SNat _ -> 2
  | SProp -> 2
  | SType _ -> 2
  | SPrim _ -> 2
  | SUnit -> 2
  | SAuto -> 2
  | SPair (_, _) -> 2
  | STuple _ -> 2
  | SSum _ -> 2
  | SProd _ -> 2
  | SProj (_, _) -> 2
  | SAnn (_, _) -> 2
  | SInj (_, _, _) -> 1
  | SAbsurd _ -> 1
  | SApp (_, _) -> 1
  | SFun (_, _) -> 0
  | SArrow (_, _) -> 0
  | SStar (_, _) -> 0
  | SLet (_, _, _, _) -> 0
  | SCase (_, _, _) -> 0

let mark (q : Kanon_kernel.Quantity.t) : string =
  match q with
  | Kanon_kernel.Quantity.Zero -> "0 "
  | Kanon_kernel.Quantity.One -> "1 "
  | Kanon_kernel.Quantity.Many -> ""

let rec at (lvl : int) (s : t) : string =
  let text = raw s in
  if level_of s >= lvl then text else "(" ^ text ^ ")"

and binder_text (b : binder) : string =
  Printf.sprintf "(%s%s : %s)" (mark b.b_q) b.b_name (at 0 b.b_ty)

(** A branch body and a motive body print at level 1, so a term that
    reaches to the right (a case, a fun, a let, an arrow or a star)
    takes parentheses and cannot swallow the branch bar that follows
    it. *)
and branch_text (br : branch) : string =
  Printf.sprintf " | %d%s => %s" br.br_leg
    (String.concat "" (List.map (fun b -> " " ^ binder_text b) br.br_binders))
    (at 1 br.br_body)

and motive_text (mo : motive) : string =
  Printf.sprintf " as %s return %s" mo.mo_self (at 1 mo.mo_body)

and raw (s : t) : string =
  match s with
  | SVar x -> x
  | SNat n -> string_of_int n
  | SProp -> "Prop"
  | SType n -> "Type " ^ string_of_int n
  | SPrim p -> prim_name p
  | SUnit -> "()"
  | SAuto -> "auto"
  | SPair (a, b) -> Printf.sprintf "(%s, %s)" (at 0 a) (at 0 b)
  | STuple items ->
      Printf.sprintf "tuple (%s)" (String.concat ", " (List.map (at 0) items))
  | SSum items ->
      Printf.sprintf "sum (%s)" (String.concat ", " (List.map (at 0) items))
  | SProd items ->
      Printf.sprintf "prod (%s)" (String.concat ", " (List.map (at 0) items))
  | SProj (a, k) -> Printf.sprintf "%s.%d" (at 2 a) k
  | SInj (k, n, a) -> Printf.sprintf "inj %d of %d %s" k n (at 1 a)
  | SAbsurd a -> "absurd " ^ at 1 a
  | SApp (f, a) -> at 1 f ^ " " ^ at 2 a
  | SFun (bs, body) ->
      Printf.sprintf "fun %s => %s"
        (String.concat " " (List.map binder_text bs))
        (at 0 body)
  | SArrow (b, cod) -> binder_text b ^ " -> " ^ at 0 cod
  | SStar (b, cod) -> binder_text b ^ " * " ^ at 0 cod
  | SLet (x, ty, def, body) ->
      Printf.sprintf "let %s : %s := %s in %s" x (at 1 ty) (at 1 def) (at 0 body)
  | SAnn (a, ty) -> Printf.sprintf "(%s : %s)" (at 0 a) (at 0 ty)
  | SCase (scrut, mo, brs) ->
      Printf.sprintf "case %s%s with%s" (at 1 scrut)
        (mo |> Option.fold ~none:"" ~some:motive_text)
        (String.concat "" (List.map branch_text brs))

let decl_text (d : decl) : string =
  match d with
  | DDef (name, ty, def) ->
      Printf.sprintf "def %s : %s := %s\n" name (at 0 ty) (at 0 def)
  | DAxiom (name, ty) -> Printf.sprintf "axiom %s : %s\n" name (at 0 ty)

(** The printer of SA-D2:  its output re-parses to an equal tree.  An
    empty tree prints as the empty text, which parses back to the empty
    tree. *)
let print (ds : decl list) : string = String.concat "" (List.map decl_text ds)
