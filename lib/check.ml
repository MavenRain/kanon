(** The bidirectional checker, plan section 6.  The context is tot's
    (kan-lang-tot-pin/lib/check.ml:14 and :27):  an evaluation
    environment, the locals with their name, quantity and type, the size
    that turns an index into a level, and the budget.

    [infer] reads a type out of a term and [check] pushes an expected
    type into one.  Four constructors are checked and never inferred:  a
    section and an injection need the former they live in, and an
    elimination without a motive needs the expected type as its constant
    cocone (kan-lang-tot-pin/lib/term.ml:38-40).  Everything else is
    inferred and then converted against the expectation.

    Quantities are modes, not counters, exactly as the pin has them.  A
    binder at [Zero] exists at check time only, so reading it at a
    runtime mode is [Error (Quantity ..)].  [One] counts as [Many] at M0
    (SB-D3) and the linear counter is an M1 obligation in SPEC.md
    section 10.

    Every entry point takes an optional budget and every [infer] polls
    it, so a driver can stop a check that does not end.

    No shape name appears in this file.  Each former, injection, section,
    projection and elimination goes to the pack of its shape, and the
    pack is looked up in rules.ml. *)

let ( let* ) = Result.bind

type ctx = {
  globals : Global.t;
  env : Value.t list;  (** one value per local, innermost first *)
  locals : (string * Quantity.t * Value.t) list;  (** innermost first *)
  size : int;
  budget : Budget.t;
}

let make (globals : Global.t) (budget : Budget.t) : ctx =
  { globals; env = []; locals = []; size = 0; budget }

(** A bound local stands for itself, so its value is the variable at the
    level the context has grown to (kan-lang-tot-pin/lib/check.ml:27). *)
let bind (x : string) (q : Quantity.t) (ty : Value.t) (c : ctx) : ctx =
  {
    c with
    env = Value.var c.size :: c.env;
    locals = (x, q, ty) :: c.locals;
    size = c.size + 1;
  }

(** A let bound local stands for its definition. *)
let define (x : string) (q : Quantity.t) (ty : Value.t) (v : Value.t) (c : ctx) : ctx =
  { c with env = v :: c.env; locals = (x, q, ty) :: c.locals; size = c.size + 1 }

let budget_msg : string = "the check budget is exhausted"
let string_word : string = "string types arrive at M1"

let no_infer (what : string) : Error.t =
  Error.Cannot_infer (what ^ " has no type of its own;  it needs an expected type")

(** A local at [Zero] is check time only.  At mode [Zero] every local
    reads, at a runtime mode an erased one does not (SB-D3:  [One] is a
    runtime mode at M0). *)
let readable (mode : Quantity.t) (q : Quantity.t) : bool =
  Quantity.equal mode Quantity.Zero || not (Quantity.equal q Quantity.Zero)

let names_of (c : ctx) : string list =
  List.map
    (fun ((x : string), (_q : Quantity.t), (_ty : Value.t)) -> x)
    c.locals

let rec ops : ctx Rules.ops =
  {
    Rules.o_infer = (fun (c : ctx) (q : Quantity.t) (t : Term.t) -> infer c q t);
    o_check = (fun (c : ctx) (q : Quantity.t) (t : Term.t) (ty : Value.t) -> check c q t ty);
    o_infer_univ = (fun (c : ctx) (t : Term.t) -> infer_univ c t);
    o_conv = (fun (c : ctx) ~(ty : Value.t) (a : Value.t) (b : Value.t) -> Conv.conv ops c ~ty a b);
    o_conv_type = (fun (c : ctx) (a : Value.t) (b : Value.t) -> Conv.conv_type ops c a b);
    o_eval = (fun (c : ctx) (t : Term.t) -> Eval.eval c.globals c.env t);
    o_whnf = (fun (c : ctx) (v : Value.t) -> Eval.whnf c.globals v);
    o_bind = (fun (x : string) (q : Quantity.t) (ty : Value.t) (c : ctx) -> bind x q ty c);
    o_size = (fun (c : ctx) -> c.size);
    o_env = (fun (c : ctx) -> c.env);
    o_ev = (fun (c : ctx) -> Eval.ev c.globals);
    o_pp = (fun (c : ctx) (v : Value.t) -> pp_value c v);
    o_quote = (fun (c : ctx) (v : Value.t) -> Eval.quote c.globals c.size v);
    o_head_ty = (fun (c : ctx) (h : Value.head) -> head_ty c h);
  }

and pp_value (c : ctx) (v : Value.t) : string =
  Eval.quote c.globals c.size v
  |> Result.map (Pp.term (names_of c))
  |> Result.value ~default:"a value that does not read back"

(** The type a neutral head carries, which is what lets conversion walk a
    spine at a type. *)
and head_ty (c : ctx) (h : Value.head) : (Value.t, Error.t) result =
  match h with
  | Value.HLocal lvl ->
      Rules.at (c.size - lvl - 1) c.locals
      |> Option.to_result
           ~none:(Error.Unbound "a local level is outside the context")
      |> Result.map (fun ((_x : string), (_q : Quantity.t), (ty : Value.t)) -> ty)
  | Value.HGlobal n ->
      Global.find n c.globals
      |> Option.to_result ~none:(Error.Unbound n)
      |> Fun.flip Result.bind (fun (e : Global.entry) ->
             Eval.eval c.globals [] (Global.entry_ty e))

(** The universe a term lives at.  A type is read at mode [Zero], so an
    erased local may appear in it. *)
and infer_univ (c : ctx) (t : Term.t) : (Level.t, Error.t) result =
  let* v = infer c Quantity.Zero t in
  let* w = Eval.whnf c.globals v in
  Value.as_univ w
  |> Option.to_result
       ~none:
         (Error.Universe
            ("a term used as a type is not a universe:  " ^ pp_value c w))

and infer (c : ctx) (mode : Quantity.t) (t : Term.t) : (Value.t, Error.t) result =
  if Budget.exhausted c.budget then Error (Error.Budget_exhausted budget_msg)
  else infer_node c mode t

and infer_node (c : ctx) (mode : Quantity.t) (t : Term.t) : (Value.t, Error.t) result =
  match t with
  | Term.Var ix ->
      let* x, q, ty =
        Rules.at ix c.locals
        |> Option.to_result
             ~none:
               (Error.Unbound
                  (Printf.sprintf "de Bruijn index %d is outside the context" ix))
      in
      if readable mode q then Ok ty
      else
        Error
          (Error.Quantity
             (Printf.sprintf "the erased binder %s is read in a runtime position" x))
  | Term.Univ l -> Ok (Value.VUniv (Level.succ l))
  | Term.Lan (s, diagram) ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules s in
      let* l = pack.Rules.form_lan ops c s diagram ~expected:None in
      Ok (Value.VUniv l)
  | Term.Ran (s, diagram) ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules s in
      let* l = pack.Rules.form_ran ops c s diagram ~expected:None in
      Ok (Value.VUniv l)
  | Term.Out (s, addr, scrut) ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules s in
      pack.Rules.elim_out ops c mode s addr scrut
  | Term.Elim e ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules e.Term.e_shape in
      pack.Rules.elim_elim ops c mode e ~expected:None
  | Term.Let (x, ty, def, body) ->
      let* c' = let_ctx c mode x ty def in
      infer c' mode body
  | Term.Ann (tm, ty) ->
      let* _l = infer_univ c ty in
      let* tyv = Eval.eval c.globals c.env ty in
      let* () = check c mode tm tyv in
      Ok tyv
  | Term.Global n ->
      Global.find n c.globals
      |> Option.to_result ~none:(Error.Unbound n)
      |> Fun.flip Result.bind (fun (e : Global.entry) ->
             Eval.eval c.globals [] (Global.entry_ty e))
  | Term.Lit (Literal.LInt _) -> Eval.eval c.globals [] Prim.nat_ty
  | Term.Lit (Literal.LString _) -> Error (Error.Not_yet string_word)
  | Term.In (_, _, _) -> Error (no_infer "an injection")
  | Term.Sec (_, _) -> Error (no_infer "a section")
  | Term.Auto -> Error (Error.Not_yet Rules.auto_word)

and check (c : ctx) (mode : Quantity.t) (t : Term.t) (expected : Value.t) :
    (unit, Error.t) result =
  match t with
  | Term.Sec (s, legs) ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules s in
      pack.Rules.intro_sec ops c mode s legs ~expected
  | Term.In (s, addr, args) ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules s in
      pack.Rules.intro_in ops c mode s addr args ~expected
  | Term.Elim e ->
      let* (pack : ctx Rules.rule_pack) = Rules.rules e.Term.e_shape in
      let* got = pack.Rules.elim_elim ops c mode e ~expected:(Some expected) in
      ensure c got expected
  | Term.Lan (s, diagram) -> check_former c s diagram expected ~left:true
  | Term.Ran (s, diagram) -> check_former c s diagram expected ~left:false
  | Term.Let (x, ty, def, body) ->
      let* c' = let_ctx c mode x ty def in
      check c' mode body expected
  | Term.Var _ | Term.Univ _ | Term.Out (_, _, _) | Term.Ann (_, _) | Term.Global _
  | Term.Lit _ | Term.Auto ->
      let* got = infer c mode t in
      ensure c got expected

(** A former checked against a universe passes the expected level to the
    pack (SB-D6), which is what gives the width zero collection its
    universe (D-M0-6).  M0 has no cumulativity, so the level the pack
    reports must be the level expected (SB-D2). *)
and check_former (c : ctx) (s : Term.t Shape.t) (diagram : Term.t) (expected : Value.t)
    ~(left : bool) : (unit, Error.t) result =
  let* w = Eval.whnf c.globals expected in
  let* l0 =
    Value.as_univ w
    |> Option.to_result
         ~none:
           (Error.Universe
              ("a type former is checked against a type that is not a universe:  "
              ^ pp_value c w))
  in
  let* (pack : ctx Rules.rule_pack) = Rules.rules s in
  let former = if left then pack.Rules.form_lan else pack.Rules.form_ran in
  let* l = former ops c s diagram ~expected:(Some l0) in
  if Level.equal l l0 then Ok ()
  else
    Error
      (Error.Universe
         (Printf.sprintf "the former lives at %s and the expected universe is %s"
            (Level.to_string l) (Level.to_string l0)))

(** The subsumption step:  an inferred type must convert with the
    expected one.  There is no cumulativity at M0, so conversion is the
    whole relation. *)
and ensure (c : ctx) (got : Value.t) (expected : Value.t) : (unit, Error.t) result =
  let* eq = Conv.conv_type ops c got expected in
  if eq then Ok ()
  else
    Error
      (Error.Mismatch
         (Printf.sprintf "the term has type %s and the expected type is %s"
            (pp_value c got) (pp_value c expected)))

(** A let binds its definition, so the body sees the value and not only
    the name.  The local carries the mode the let was read at, so an
    erased let stays erased in its body. *)
and let_ctx (c : ctx) (mode : Quantity.t) (x : string) (ty : Term.t) (def : Term.t) :
    (ctx, Error.t) result =
  let* _l = infer_univ c ty in
  let* tyv = Eval.eval c.globals c.env ty in
  let* () = check c mode def tyv in
  let* defv = Eval.eval c.globals c.env def in
  Ok (define x mode tyv defv c)

(** The two kinds of declaration M0 has.  A definition carries a body, an
    axiom does not (R-Q3). *)
type kind =
  | Definition
  | Postulate

type decl = {
  d_name : string;
  d_kind : kind;
  d_ty : Term.t;
  d_body : Term.t option;  (** [None] for a postulate *)
}

let missing_body (n : string) : Error.t =
  Error.Cannot_infer ("the definition " ^ n ^ " has no body")

(** Check one declaration against the environment built so far.  The name
    is added by the caller and only after this returns, so a self
    reference in the body is [Error (Unbound name)]. *)
let check_decl (globals : Global.t) (budget : Budget.t) (d : decl) :
    (Global.entry, Error.t) result =
  let c : ctx = make globals budget in
  let* _l = infer_univ c d.d_ty in
  let* tyv = Eval.eval globals [] d.d_ty in
  match d.d_kind with
  | Postulate -> Ok (Global.Axiom { Global.ax_ty = d.d_ty })
  | Definition ->
      let* body =
        d.d_body |> Option.to_result ~none:(missing_body d.d_name)
      in
      let* () = check c Quantity.Many body tyv in
      (* SB-D24:  M0 has no recursion, so unfolding ends and every
         definition is reducible with no guarded argument. *)
      Ok
        (Global.Def
           {
             Global.ty = d.d_ty;
             def = body;
             reducible = true;
             rec_arg = None;
             partial = false;
           })

(** Check a declaration list in order and return the checked entries in
    declaration order.  Each entry joins the environment the next
    declaration is checked against. *)
let check_decls ?(budget : Budget.t = Budget.unlimited) (globals : Global.t)
    (ds : decl list) : ((string * Global.entry) list, Error.t) result =
  List.fold_left
    (fun (acc : (Global.t * (string * Global.entry) list, Error.t) result) (d : decl) ->
      let* g, rows = acc in
      let* entry = check_decl g budget d in
      Ok (Global.add d.d_name entry g, (d.d_name, entry) :: rows))
    (Ok (globals, []))
    ds
  |> Result.map
       (fun ((_g : Global.t), (rows : (string * Global.entry) list)) -> List.rev rows)

(** Entry points for one term, for a driver and for the suite. *)
let infer_term ?(budget : Budget.t = Budget.unlimited) (globals : Global.t)
    (t : Term.t) : (Value.t, Error.t) result =
  infer (make globals budget) Quantity.Many t

let check_term ?(budget : Budget.t = Budget.unlimited) (globals : Global.t) (t : Term.t)
    (ty : Value.t) : (unit, Error.t) result =
  check (make globals budget) Quantity.Many t ty
