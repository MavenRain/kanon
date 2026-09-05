(** The M0 surface elaborator, brief section 3.9.  It reads a surface
    tree and writes the kernel term of the sugar row that SPEC.md
    section 7 gives the production.  There is no metavariable and no
    unification:  a row that needs a type asks the checker for it, so
    the elaborator is bidirectional in the same sense check.ml is.

    Mirrors kan-lang-tot-pin/surface/elab.ml for the walk:  a name
    resolves against the local telescope first and against the globals
    second, a binder pushes one local, and a form that the kernel
    refuses in inference position takes its expected type from the
    caller.  tot's holes, its instance search and its data items have no
    M0 production and are left out.

    The elaboration context is [Check.ctx] itself.  It carries the local
    names, their marks and their types as values, which is exactly what
    the two type directed rows need (SB-D14), and it carries the globals
    a name resolves against.  No second context type exists, so the
    names the elaborator counts and the names the checker counts can
    never drift.

    Every inference the elaborator makes is check time, so it asks
    [Check.infer] at mark [Zero] (SB-D31):  an erased binder is readable
    at that mark, and the mark the kernel enforces on the term is the
    one [Check.check_decls] applies afterwards. *)

open Kanon_kernel

let ( let* ) = Result.bind

let no_expect (what : string) : Error.t =
  Error.Cannot_infer (what ^ " needs an expected type")

(** The de Bruijn index of a name in the local telescope, innermost
    first.  A name that is not local is a global, and an unbound global
    is the checker's [Unbound], not the elaborator's:  the elaborator
    never decides that a name does not exist (SB-D30). *)
let rec index_of (x : string) (names : string list) : int option =
  match names with
  | [] -> None
  | y :: rest ->
      if String.equal x y then Some 0 else Option.map succ (index_of x rest)

let globals_of (c : Check.ctx) : Global.t = c.Check.globals
let env_of (c : Check.ctx) : Value.t list = c.Check.env
let size_of (c : Check.ctx) : int = c.Check.size

let eval_in (c : Check.ctx) (t : Term.t) : (Value.t, Error.t) result =
  Eval.eval (globals_of c) (env_of c) t

let whnf_in (c : Check.ctx) (v : Value.t) : (Value.t, Error.t) result =
  Eval.whnf (globals_of c) v

(** The type of a term, at the check time mark.  The answer feeds a
    type directed row and never reaches the checked term. *)
let type_of (c : Check.ctx) (t : Term.t) : (Value.t, Error.t) result =
  let* v = Check.infer c Quantity.Zero t in
  whnf_in c v

(** The universe a level names, [Prop] at zero and [Type n] at n + 1
    (SB-D2). *)
let univ_of_int (n : int) : (Term.t, Error.t) result =
  Level.of_int n
  |> Option.to_result
       ~none:(Error.Universe (Printf.sprintf "the universe level %d is not a level" n))
  |> Result.map (fun (l : Level.t) -> Term.Univ l)

(** The point former under a left or a right former, as the pair of the
    mark and the domain value the shape carries. *)
let point_of (s : Value.t Shape.t) : (Quantity.t * string * Value.t) option =
  Rules.as_vpi s

let leg_expectations (c : Check.ctx) (expected : Value.t option) (n : int)
    ~(left : bool) : (Value.t option list, Error.t) result =
  let none_list : Value.t option list = List.init n (fun (_k : int) -> None) in
  let view : Value.t -> (Value.t Shape.t * Value.closure * Level.t option) option =
    if left then Value.as_lan else Value.as_ran
  in
  expected
  |> Option.fold ~none:(Ok none_list) ~some:(fun (ty : Value.t) ->
         let* w = whnf_in c ty in
         view w
         |> Option.fold ~none:(Ok none_list)
              ~some:(fun
                  ( (vs : Value.t Shape.t),
                    (dclo : Value.closure),
                    (_u : Level.t option) )
                ->
                Rules.as_vcoll vs
                |> Option.fold ~none:(Ok none_list) ~some:(fun (dn : int) ->
                       if Int.equal dn n then
                         let* dlegs = Rules.coll_legs_of Check.ops c dclo in
                         Rules.all_ok
                           (List.init n (fun (k : int) ->
                                Result.map Option.some
                                  (Rules.coll_leg_ty Check.ops c dlegs k)))
                       else Ok none_list)))

(** The whole walk.  One arm per constructor of [Syntax.t], in the order
    syntax.ml declares them, and every arm names the sugar row of
    SPEC.md section 7 that it writes. *)
let rec elab (c : Check.ctx) ~(expected : Value.t option) (s : Syntax.t) :
    (Term.t, Error.t) result =
  match s with
  | Syntax.SVar x ->
      Ok
        (index_of x (Check.names_of c)
        |> Option.fold ~none:(Term.Global x) ~some:(fun (i : int) -> Term.Var i))
  | Syntax.SNat n -> Ok (Term.Lit (Literal.LInt n))
  | Syntax.SProp -> Ok (Term.Univ Level.zero)
  | Syntax.SType n -> univ_of_int (n + 1)
  | Syntax.SPrim p -> Ok (Term.Global (Syntax.prim_name p))
  | Syntax.SUnit -> Ok Rules.unit_val
  | Syntax.SAuto -> Ok Term.Auto
  | Syntax.SPair (a, b) -> elab_pair c ~expected a b
  | Syntax.STuple items ->
      let* legs = elab_items c ~expected items ~left:false in
      Ok (Term.Sec (Shape.SColl (List.length items), List.map Rules.leg_of legs))
  | Syntax.SSum items ->
      let* tys = Rules.all_ok (List.map (elab c ~expected:None) items) in
      Ok (Rules.sum_ty tys)
  | Syntax.SProd items ->
      let* tys = Rules.all_ok (List.map (elab c ~expected:None) items) in
      Ok (Rules.prod_ty tys)
  | Syntax.SProj (a, k) -> elab_proj c a k
  | Syntax.SInj (k, n, a) ->
      let* tys = leg_expectations c expected n ~left:true in
      let* payload = elab c ~expected:(Option.join (Rules.at k tys)) a in
      Ok (Term.In (Shape.SColl n, Term.ALeg k, [ payload ]))
  | Syntax.SAbsurd a ->
      let* scrut = elab c ~expected:None a in
      Ok
        (Term.Elim
           {
             Term.e_shape = Shape.SColl 0;
             e_scrut = scrut;
             e_scrut_q = Quantity.Many;
             e_motive = None;
             e_branches = [];
           })
  | Syntax.SApp (f, a) -> elab_app c f a
  | Syntax.SFun (bs, body) -> elab_fun c ~expected bs body
  | Syntax.SArrow (b, cod) -> elab_group c b cod ~left:false
  | Syntax.SStar (b, cod) -> elab_group c b cod ~left:true
  | Syntax.SLet (x, ty, def, body) ->
      let* ty' = elab c ~expected:None ty in
      let* tyv = eval_in c ty' in
      let* def' = elab c ~expected:(Some tyv) def in
      let* defv = eval_in c def' in
      let c' = Check.define x Quantity.Many tyv defv c in
      let* body' = elab c' ~expected body in
      Ok (Term.Let (x, ty', def', body'))
  | Syntax.SAnn (a, ty) ->
      let* ty' = elab c ~expected:None ty in
      let* tyv = eval_in c ty' in
      let* a' = elab c ~expected:(Some tyv) a in
      Ok (Term.Ann (a', ty'))
  | Syntax.SCase (scrut, mo, brs) -> elab_case c ~expected scrut mo brs

(** The items of a section, each at the leg type the expected type gives
    it when it gives one.  The two lists are paired by the total [zip] of
    rules.ml, so no length can surprise this row. *)
and elab_items (c : Check.ctx) ~(expected : Value.t option) (items : Syntax.t list)
    ~(left : bool) : (Term.t list, Error.t) result =
  let* tys = leg_expectations c expected (List.length items) ~left in
  let* pairs =
    Rules.zip items tys
    |> Option.to_result
         ~none:(Error.Mismatch "the item count and the leg count differ")
  in
  Rules.all_ok
    (List.map
       (fun ((it : Syntax.t), (ty : Value.t option)) -> elab c ~expected:ty it)
       pairs)

(** "(a, b)":  the pair of the sugar table.  The kernel refuses an
    injection in inference position, so the row needs the expected type
    and reads the point mark and the fibre from it. *)
and elab_pair (c : Check.ctx) ~(expected : Value.t option) (a : Syntax.t)
    (b : Syntax.t) : (Term.t, Error.t) result =
  let* ty = expected |> Option.to_result ~none:(no_expect "a pair") in
  let* w = whnf_in c ty in
  let* vs, dclo, _u =
    Value.as_lan w
    |> Option.to_result
         ~none:(Error.Mismatch "a pair needs a left former as its expected type")
  in
  let* q, x, dom_v =
    point_of vs
    |> Option.to_result ~none:(Error.Mismatch "a pair needs a point former")
  in
  let* point = elab c ~expected:(Some dom_v) a in
  let* point_v = eval_in c point in
  let* cod_v = Rules.open_closure (Eval.ev (globals_of c)) dclo [ point_v ] in
  let* fibre = elab c ~expected:(Some cod_v) b in
  let* dom_t = Eval.quote (globals_of c) (size_of c) dom_v in
  Ok (Term.In (Shape.SPi (q, x, dom_t), Term.APt (q, point), [ fibre ]))

(** The first answer of a list of candidates.  Two views on one value
    are exclusive here, so the list holds at most one [Some];  the
    thunk keeps the branch that did not fire from running, because
    [Option.fold] reads its [~none] argument eagerly. *)
and first_some (xs : 'a option list) : 'a option =
  List.fold_left
    (fun (acc : 'a option) (x : 'a option) ->
      Option.fold ~none:x ~some:Option.some acc)
    None xs

(** "p.1", "p.2" and "t.k" (SB-D14).  The scrutinee's type tells the two
    sugar rows apart:  a left former at the point shape is a pair and a
    right former at the collection shape is a tuple. *)
and elab_proj (c : Check.ctx) (a : Syntax.t) (k : int) : (Term.t, Error.t) result =
  let* scrut = elab c ~expected:None a in
  let* w = type_of c scrut in
  let candidates : (unit -> (Term.t, Error.t) result) option list =
    [
      Value.as_lan w
      |> Option.map
           (fun
             ( (vs : Value.t Shape.t),
               (dclo : Value.closure),
               (_u : Level.t option) )
           -> fun () -> elab_pair_proj c scrut vs dclo k);
      Value.as_ran w
      |> Option.map
           (fun
             ( (vs : Value.t Shape.t),
               (_dclo : Value.closure),
               (_u : Level.t option) )
           -> fun () -> elab_leg_proj c scrut vs k);
    ]
  in
  let* run =
    first_some candidates
    |> Option.to_result
         ~none:
           (Error.Mismatch
              "a projection reads a pair or a tuple, and this scrutinee is neither")
  in
  run ()

(** The two pair projections of D-M0-3:  one elimination at the left
    former of the point shape, with the projection motive and the branch
    that binds the point and the fibre element. *)
and elab_pair_proj (c : Check.ctx) (scrut : Term.t) (vs : Value.t Shape.t)
    (dclo : Value.closure) (k : int) : (Term.t, Error.t) result =
  let* q, x, dom_v =
    point_of vs
    |> Option.to_result ~none:(Error.Mismatch "a pair projection needs a point former")
  in
  let* which =
    (if Int.equal k 1 then Some 0 else if Int.equal k 2 then Some 1 else None)
    |> Option.to_result
         ~none:(Error.Wrong_leg "a pair carries the projections .1 and .2 only")
  in
  let size = size_of c in
  let ev = Eval.ev (globals_of c) in
  let* body_v =
    if Int.equal which 0 then Ok dom_v
    else
      let* point =
        Rules.elim_value ev vs q None (Rules.proj_branch q 0) (env_of c)
          (Value.var size)
      in
      Rules.open_closure ev dclo [ point ]
  in
  let* m_body = Eval.quote (globals_of c) (size + 1) body_v in
  let* dom_t = Eval.quote (globals_of c) size dom_v in
  Ok
    (Term.Elim
       {
         Term.e_shape = Shape.SPi (q, x, dom_t);
         e_scrut = scrut;
         e_scrut_q = Quantity.Many;
         e_motive =
           Some { Term.m_ind = None; m_idx = []; m_self = "self"; m_body };
         e_branches = Rules.proj_branch q which;
       })

(** "t.k", the leg of a tuple, 0 based (SB-D14). *)
and elab_leg_proj (c : Check.ctx) (scrut : Term.t) (vs : Value.t Shape.t) (k : int) :
    (Term.t, Error.t) result =
  let _ = c in
  let* n =
    Rules.as_vcoll vs
    |> Option.to_result
         ~none:(Error.Mismatch "a leg projection needs a collection former")
  in
  Ok (Term.Out (Shape.SColl n, Term.ALeg k, scrut))

(** "f a" (SA-D1).  The head is inferred, so the argument is elaborated
    at the domain the head's type names and the address carries the mark
    that type declares. *)
and elab_app (c : Check.ctx) (f : Syntax.t) (a : Syntax.t) : (Term.t, Error.t) result =
  let* head = elab c ~expected:None f in
  let* w = type_of c head in
  let* vs, _dclo, _u =
    Value.as_ran w
    |> Option.to_result
         ~none:(Error.Mismatch "the head of an application is not a function")
  in
  let* q, x, dom_v =
    point_of vs
    |> Option.to_result
         ~none:(Error.Mismatch "the head of an application is not a function")
  in
  let* arg = elab c ~expected:(Some dom_v) a in
  let* dom_t = Eval.quote (globals_of c) (size_of c) dom_v in
  Ok (Term.Out (Shape.SPi (q, x, dom_t), Term.APt (q, arg), head))

(** One binder:  its type is elaborated in the context it stands in, and
    the context the body reads holds the binder with its mark. *)
and elab_binder (c : Check.ctx) (b : Syntax.binder) :
    (Quantity.t * string * Term.t * Check.ctx, Error.t) result =
  let* ty = elab c ~expected:None b.Syntax.b_ty in
  let* tyv = eval_in c ty in
  Ok (b.Syntax.b_q, b.Syntax.b_name, ty, Check.bind b.Syntax.b_name b.Syntax.b_q tyv c)

(** The codomain the body of a lambda is elaborated at:  the expected
    type opened at the binder, when the expected type is a right former
    at the point shape.  A shape that does not match answers [None] and
    the checker reports it. *)
and cod_of (c : Check.ctx) ~(expected : Value.t option) :
    (Value.t option, Error.t) result =
  expected
  |> Option.fold ~none:(Ok None) ~some:(fun (ty : Value.t) ->
         let* w = whnf_in c ty in
         Value.as_ran w
         |> Option.fold ~none:(Ok None)
              ~some:(fun
                  ( (vs : Value.t Shape.t),
                    (dclo : Value.closure),
                    (_u : Level.t option) )
                ->
                point_of vs
                |> Option.fold ~none:(Ok None)
                     ~some:(fun
                         ( (_q : Quantity.t),
                           (_x : string),
                           (_dom : Value.t) )
                       ->
                       Result.map Option.some
                         (Rules.open_closure (Eval.ev (globals_of c)) dclo
                            [ Value.var (size_of c) ]))))

(** "fun (q x : A) => b", one section at the point shape per binder. *)
and elab_fun (c : Check.ctx) ~(expected : Value.t option) (bs : Syntax.binder list)
    (body : Syntax.t) : (Term.t, Error.t) result =
  match bs with
  | [] -> elab c ~expected body
  | b :: rest ->
      let* q, x, ty, c' = elab_binder c b in
      let* inner = cod_of c ~expected in
      let* body' = elab_fun c' ~expected:inner rest body in
      Ok
        (Term.Sec
           (Shape.SPi (q, x, ty), [ { Term.l_binders = [ (q, x) ]; l_body = body' } ]))

(** "(q x : A) -> B" is the right former and "(q x : A) * B" is the left
    one, both at the point shape. *)
and elab_group (c : Check.ctx) (b : Syntax.binder) (cod : Syntax.t) ~(left : bool) :
    (Term.t, Error.t) result =
  let* q, x, ty, c' = elab_binder c b in
  let* cod' = elab c' ~expected:None cod in
  let s : Term.t Shape.t = Shape.SPi (q, x, ty) in
  Ok (if left then Term.Lan (s, cod') else Term.Ran (s, cod'))

(** "case t [as x return M] with | k (y : T) => b".  The width comes from
    the scrutinee's type, so a case that misses a leg is the checker's
    [Missing_branch] and never a silent narrowing. *)
and elab_case (c : Check.ctx) ~(expected : Value.t option) (scrut : Syntax.t)
    (mo : Syntax.motive option) (brs : Syntax.branch list) : (Term.t, Error.t) result =
  let* scrut' = elab c ~expected:None scrut in
  let* w = type_of c scrut' in
  let* vs, dclo, _u =
    Value.as_lan w
    |> Option.to_result
         ~none:(Error.Mismatch "a case needs a left former as the type of its scrutinee")
  in
  let* n =
    Rules.as_vcoll vs
    |> Option.to_result ~none:(Error.Mismatch "a case eliminates a collection")
  in
  let* dlegs = Rules.coll_legs_of Check.ops c dclo in
  let* motive = elab_motive c mo w in
  let* branches =
    Rules.all_ok (List.map (elab_branch c vs dlegs motive expected) brs)
  in
  Ok
    (Term.Elim
       {
         Term.e_shape = Shape.SColl n;
         e_scrut = scrut';
         e_scrut_q = Quantity.Many;
         e_motive = motive;
         e_branches = branches;
       })

(** The motive is a type under the scrutinee, so it is elaborated with
    the self name bound at the erased mark. *)
and elab_motive (c : Check.ctx) (mo : Syntax.motive option) (scrut_ty : Value.t) :
    (Term.motive option, Error.t) result =
  mo
  |> Option.fold ~none:(Ok None) ~some:(fun (m : Syntax.motive) ->
         let c' = Check.bind m.Syntax.mo_self Quantity.Zero scrut_ty c in
         let* body = elab c' ~expected:None m.Syntax.mo_body in
         Ok
           (Some
              {
                Term.m_ind = None;
                m_idx = [];
                m_self = m.Syntax.mo_self;
                m_body = body;
              }))

(** One branch.  The payload's type is the diagram's leg, not the
    surface annotation (SB-D32), so the elaborator and the checker read
    the same type. *)
and elab_branch (c : Check.ctx) (vs : Value.t Shape.t) (dlegs : Value.vleg list)
    (motive : Term.motive option) (expected : Value.t option) (br : Syntax.branch) :
    (Term.addr * Term.leg, Error.t) result =
  let* b =
    Rules.one_of br.Syntax.br_binders
    |> Option.to_result
         ~none:(Error.Missing_branch "each branch binds its payload once")
  in
  let* ty = Rules.coll_leg_ty Check.ops c dlegs br.Syntax.br_leg in
  let self =
    Value.VIn (vs, Value.VALeg br.Syntax.br_leg, [ Value.var (size_of c) ])
  in
  let* target = branch_target c motive expected self in
  let c' = Check.bind b.Syntax.b_name b.Syntax.b_q ty c in
  let* body = elab c' ~expected:target br.Syntax.br_body in
  Ok
    ( Term.ALeg br.Syntax.br_leg,
      { Term.l_binders = [ (b.Syntax.b_q, b.Syntax.b_name) ]; l_body = body } )

(** The type a branch body is elaborated at:  the motive read at the
    branch's own value, or the caller's expectation as the constant
    cocone when there is no motive. *)
and branch_target (c : Check.ctx) (motive : Term.motive option)
    (expected : Value.t option) (self : Value.t) : (Value.t option, Error.t) result =
  motive
  |> Option.fold ~none:(Ok expected) ~some:(fun (_m : Term.motive) ->
         Result.map Option.some (Rules.elim_result Check.ops c motive expected self))

(** One declaration, elaborated into the row [Check.check_decls] reads.
    A definition's body is elaborated at its declared type, which is what
    gives every checking position form its expectation. *)
let elab_decl (c : Check.ctx) (d : Syntax.decl) : (Check.decl, Error.t) result =
  match d with
  | Syntax.DDef (name, ty, body) ->
      let* ty' = elab c ~expected:None ty in
      let* tyv = eval_in c ty' in
      let* body' = elab c ~expected:(Some tyv) body in
      Ok
        {
          Check.d_name = name;
          d_kind = Check.Definition;
          d_ty = ty';
          d_body = Some body';
        }
  | Syntax.DAxiom (name, ty) ->
      let* ty' = elab c ~expected:None ty in
      Ok { Check.d_name = name; d_kind = Check.Postulate; d_ty = ty'; d_body = None }

(** The whole file.  Each declaration is elaborated against the entries
    checked before it and then checked, so a self reference finds no
    entry and the checker answers [Unbound] (plan section 6). *)
let elab_program ?(budget : Budget.t = Budget.unlimited) (globals : Global.t)
    (ds : Syntax.decl list) : ((string * Global.entry) list, Error.t) result =
  List.fold_left
    (fun
      (acc : (Global.t * (string * Global.entry) list, Error.t) result)
      (d : Syntax.decl)
    ->
      let* g, rows = acc in
      let* row = elab_decl (Check.make g budget) d in
      let* checked = Check.check_decls ~budget g [ row ] in
      let* name, entry =
        Rules.one_of checked
        |> Option.to_result
             ~none:(Error.Cannot_infer "the checker answered no entry for a declaration")
      in
      Ok (Global.add name entry g, (name, entry) :: rows))
    (Ok (globals, []))
    ds
  |> Result.map
       (fun ((_g : Global.t), (rows : (string * Global.entry) list)) -> List.rev rows)

(** The checked form of one entry, the text "kanon check --print" writes
    and the suite compares against a golden file.  It is the kernel term,
    printed by pp.ml, so the golden shows what the checker accepted and
    not what the file said. *)
let entry_text ((name : string), (e : Global.entry)) : string =
  match e with
  | Global.Def d ->
      Printf.sprintf "def %s : %s := %s\n" name (Pp.term [] d.Global.ty)
        (Pp.term [] d.Global.def)
  | Global.Axiom a -> Printf.sprintf "axiom %s : %s\n" name (Pp.term [] a.Global.ax_ty)
  | Global.Prim p -> Printf.sprintf "prim %s : %s\n" name (Pp.term [] p.Global.p_ty)

let checked_form (rows : (string * Global.entry) list) : string =
  String.concat "" (List.map entry_text rows)

(** The axiom disclosure of R-Q3:  the postulates of the file, in
    declaration order. *)
let axiom_names (rows : (string * Global.entry) list) : string list =
  List.filter_map
    (fun ((name : string), (e : Global.entry)) ->
      Global.axiom_of e |> Option.map (fun (_a : Global.axiom_entry) -> name))
    rows

(** The whole surface pass over a file:  parse, elaborate and check. *)
let check_text ?(budget : Budget.t = Budget.unlimited) (globals : Global.t)
    (src : string) : ((string * Global.entry) list, Error.t) result =
  let* ds = Parser.parse src in
  elab_program ~budget globals ds
