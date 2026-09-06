(** The emitter, plan section 7.  It reads the erased rows, asks link.ml
    for every index, and answers the binary module.  The arms past M0
    refuse with their milestone name.

    The calling conventions are the two of SD-D2 and SD-D3.  A known
    global of a known arity is called through its typed signature.  Any
    other head is a closure:  a struct of the arity, the code reference
    and the environment, called through the generic signature fn<n>
    where every argument and the answer is an eq reference.

    A value crosses between the two conventions by a cast only, because
    every typed form is a subtype of eq. *)

module E = Kanon_kernel.Eterm
module Err = Kanon_kernel.Error
module P = Kanon_kernel.Prim
module Lit = Kanon_kernel.Literal
module G = Gc_encode
module L = Link

let ( let* ) = Result.bind

(** SD-D7.  A natural rides in an i31, so it holds thirty bits. *)
let nat_max : int = 1073741823

(* ---------- locals ---------- *)

type st = {
  base : int;  (** the number of parameters *)
  extra : G.valtype list;  (** the locals after them, in order *)
}

let alloc (s : st) (v : G.valtype) : int * st =
  (s.base + List.length s.extra, { s with extra = s.extra @ [ v ] })

(** [n] fresh i32 locals, and the index of the first of them.  A count of
    zero answers the index the next allocation would take, which no body
    reads. *)
let alloc_i32s (s : st) (n : int) : int * st =
  ( s.base + List.length s.extra,
    List.fold_left
      (fun (acc : st) (_i : int) -> snd (alloc acc G.I32))
      s
      (List.init n (fun (i : int) -> i)) )

type ctx = {
  l : L.t;
  res : E.repr;  (** the result repr of the function being written *)
}

let take (n : int) (xs : 'a list) : 'a list = List.filteri (fun (i : int) (_x : 'a) -> i < n) xs
let drop (n : int) (xs : 'a list) : 'a list = List.filteri (fun (i : int) (_x : 'a) -> i >= n) xs

let rec each (f : st -> 'a -> (G.instr list * st, Err.t) result) (s : st) (xs : 'a list) :
    (G.instr list * st, Err.t) result =
  match xs with
  | [] -> Ok ([], s)
  | x :: rest ->
      let* i1, s1 = f s x in
      let* i2, s2 = each f s1 rest in
      Ok (i1 @ i2, s2)

let rec each2 (f : st -> 'a -> 'b -> (G.instr list * st, Err.t) result) (s : st)
    (xs : 'a list) (ys : 'b list) : (G.instr list * st, Err.t) result =
  match (xs, ys) with
  | [], [] -> Ok ([], s)
  | x :: xr, y :: yr ->
      let* i1, s1 = f s x y in
      let* i2, s2 = each2 f s1 xr yr in
      Ok (i1 @ i2, s2)
  | [], _ :: _ -> Error (Err.Mismatch "an argument list is shorter than its signature")
  | _ :: _, [] -> Error (Err.Mismatch "an argument list is longer than its signature")

(* ---------- the crossing between the conventions ---------- *)

let same (a : E.repr) (b : E.repr) : bool = String.equal (E.print_repr a) (E.print_repr b)

(** The instructions that take a value of [src] to [dst].  Every typed
    form is a subtype of eq, so widening is free and narrowing is one
    cast (SD-D6). *)
let coerce (l : L.t) (src : E.repr) (dst : E.repr) : (G.instr list, Err.t) result =
  if same src dst then Ok []
  else
    match (src, dst) with
    | E.RStruct (E.Tid a), E.RStruct (E.Tid b) ->
        let* af = L.fields_of a in
        let* bf = L.fields_of b in
        if Int.equal (List.length af) (List.length bf) then Ok []
        else Error (Err.Mismatch "aggregate representations have different widths")
    | _src, E.RUnion _t -> Ok []
    | _src, E.RI31 -> Ok [ G.Ref_cast G.HI31 ]
    | _src, E.RStruct (E.Tid t) ->
        Result.map (fun (i : int) -> [ G.Ref_cast (G.HType i) ]) (L.type_index l t)
    | _src, E.RFunc _t ->
        Result.map (fun (i : int) -> [ G.Ref_cast (G.HType i) ]) (L.type_index l L.clos_key)
    | _src, E.RThunk _t -> Error (Err.Not_yet "RThunk arrives at M2")

(** An empty elimination has no value to cast.  Keep its terminal
    unreachable without emitting a dead [Ref_cast] after it. *)
let with_coercion (body : G.instr list) (cast : G.instr list) : G.instr list =
  match List.rev body with
  | G.Unreachable :: _rest -> body
  | [] -> body @ cast
  | _i :: _rest -> body @ cast

(** The i31 boundary of SD-D7:  a primitive reads two tagged integers,
    works on i32 and tags its answer again.  natEq and natLt answer the
    tag of a two leg sum, and one is the true leg.

    An answer above the bound is a trap and not a wrapped number, so
    natAdd and natMul read their answer before they tag it (SD-D23).
    [over_bound] is that reading:  the answer stays in the local [t] and
    the module traps when it is above the bound. *)
let over_bound (t : int) : G.instr list =
  [
    G.Local_get t; G.I32_const nat_max; G.I32_gt_u;
    G.If (None, [ G.Unreachable ], []);
  ]

(** Truncated subtraction needs the two operands twice, so it holds two
    locals of its own (lib/prim.ml, SB-D4).  It never leaves the range,
    because it answers zero below zero. *)
let prim_sub (a : int) (b : int) : G.instr list =
  [
    G.Local_set b; G.Local_set a; G.Local_get a; G.Local_get b; G.I32_lt_u;
    G.If
      ( Some G.I32,
        [ G.I32_const 0 ],
        [ G.Local_get a; G.Local_get b; G.I32_sub ] );
    G.Ref_i31;
  ]

(** Addition holds one local:  the sum of two naturals of the range
    cannot wrap an i32, so the bound alone is read (SD-D7). *)
let prim_add (t : int) : G.instr list =
  [ G.I32_add; G.Local_set t ] @ over_bound t @ [ G.Local_get t; G.Ref_i31 ]

(** Multiplication holds three locals:  the two operands and the
    product.  The i32 product of two naturals of the range can wrap, so
    the division reads the wrap back first, and the bound is read after
    it.  A first operand of zero gives a product of zero, which no
    division reads (SD-D7). *)
let prim_mul (a : int) (b : int) (t : int) : G.instr list =
  [
    G.Local_set b; G.Local_set a; G.Local_get a; G.Local_get b; G.I32_mul;
    G.Local_set t; G.Local_get a; G.I32_const 0; G.I32_ne;
    G.If
      ( None,
        [
          G.Local_get t; G.Local_get a; G.I32_div_u; G.Local_get b; G.I32_ne;
          G.If (None, [ G.Unreachable ], []);
        ],
        [] );
  ]
  @ over_bound t
  @ [ G.Local_get t; G.Ref_i31 ]

(** The i32 locals a primitive holds beyond its two operands. *)
let prim_locals (p : P.t) : int =
  match p with
  | P.Nat_add -> 1
  | P.Nat_mul -> 3
  | P.Nat_sub -> 2
  | P.Nat_eq | P.Nat_lt -> 0

(** The body of a primitive, with the two untagged operands on the stack
    and the first of its own locals at [base]. *)
let prim_body (p : P.t) (base : int) : G.instr list =
  match p with
  | P.Nat_add -> prim_add base
  | P.Nat_mul -> prim_mul base (base + 1) (base + 2)
  | P.Nat_sub -> prim_sub base (base + 1)
  | P.Nat_eq -> [ G.I32_eq; G.Ref_i31 ]
  | P.Nat_lt -> [ G.I32_lt_u; G.Ref_i31 ]

(** The two arguments of a primitive, each untagged as it is pushed. *)
let prim_args (args : G.instr list list) : (G.instr list, Err.t) result =
  match args with
  | [ ia; ib ] ->
      Ok (ia @ [ G.Ref_cast G.HI31; G.I31_get_u ] @ ib @ [ G.Ref_cast G.HI31; G.I31_get_u ])
  | [] | [ _ ] | _ :: _ :: _ :: _ -> Error (Err.Mismatch "a primitive takes two arguments")

(* ---------- the term walk ---------- *)

let rep (c : ctx) (env : (int * E.repr) list) (tm : E.ktm) : (E.repr, Err.t) result =
  L.infer c.l.L.prog
    (List.map (fun (((_i : int), (r : E.repr)) : int * E.repr) -> r) env)
    tm

let tail_ok (c : ctx) (tail : bool) (r : E.repr) : bool =
  tail
  && Result.fold
       ~ok:(fun (is : G.instr list) -> Int.equal (List.length is) 0)
       ~error:(fun (_e : Err.t) -> false)
       (coerce c.l r c.res)

let literal (lit : Lit.t) : (G.instr list, Err.t) result =
  match lit with
  | Lit.LInt n ->
      if n >= 0 && n <= nat_max then Ok [ G.I32_const n; G.Ref_i31 ]
      else
        Error
          (Err.Overflow
             (Printf.sprintf "the literal %d leaves the i31 range of a natural" n))
  | Lit.LString _s -> Error (Err.Not_yet "a string literal has no wasm form at M0")

let tid_of (r : E.repr) : (string, Err.t) result =
  L.tid_text r
  |> Option.fold
       ~none:(Error (Err.Mismatch "a case scrutinee has no tid"))
       ~some:(fun (t : string) -> Ok t)

let nth_leg (ls : L.leg list) (k : int) (t : string) : (L.leg, Err.t) result =
  L.nth_at ls k
  |> Option.fold
       ~none:(Error (Err.Wrong_leg (Printf.sprintf "leg %d of %s" k t)))
       ~some:(fun (l : L.leg) -> Ok l)

(** The closure of a global read as a value:  the arity, the wrapper and
    an environment nothing reads. *)
let closure_value (c : ctx) (s : st) (n : string) (m : int) :
    (G.instr list * st, Err.t) result =
  let* wi = L.func_index c.l (L.wrap_fkey n 0) in
  let* ci = L.type_index c.l L.clos_key in
  Ok ([ G.I32_const m; G.Ref_func wi; G.I32_const 0; G.Ref_i31; G.Struct_new ci ], s)

(** The distinct leg struct shapes of a sum, in the order the legs give
    them. *)
let leg_shapes (c : ctx) (legs : L.leg list) : (int list, Err.t) result =
  let keys : string list =
    List.filter_map
      (fun (l : L.leg) ->
        Option.map
          (fun (((k : string), (_rs : E.repr list)) : string * E.repr list) -> k)
          (L.leg_type l))
      legs
  in
  let once : string list =
    List.fold_left
      (fun (acc : string list) (k : string) ->
        if List.mem k acc then acc else acc @ [ k ])
      [] keys
  in
  L.seq (List.map (fun (k : string) -> L.type_index c.l k) once)

(** The tag of a case scrutinee.  A payload free leg is the bare tagged
    integer and a leg with a payload is a struct whose first field is the
    tag, so one br_on_cast per shape sorts them out (SD-D5). *)
let tag_block (sv : int) (shapes : int list) : G.instr =
  let p : int = List.length shapes in
  let core : G.instr list =
    [ G.Local_get sv; G.Br_on_cast (0, G.HEq, G.HI31) ]
    @ List.mapi
        (fun (j : int) (lj : int) -> G.Br_on_cast (j + 1, G.HEq, G.HType lj))
        shapes
    @ [ G.Unreachable ]
  in
  let start : G.instr list =
    [ G.Block (Some (G.Ref G.HI31), core); G.I31_get_u ]
    @ (if Int.equal p 0 then [] else [ G.Br p ])
  in
  let rec layers (j : int) (acc : G.instr list) (rest : int list) : G.instr list =
    match rest with
    | [] -> acc
    | lj :: more ->
        let blk : G.instr = G.Block (Some (G.Ref (G.HType lj)), acc) in
        let post : G.instr list =
          [ G.Struct_get (lj, 0); G.I31_get_u ]
          @ (if Int.equal (List.length more) 0 then [] else [ G.Br (p - j - 1) ])
        in
        layers (j + 1) ([ blk ] @ post) more
  in
  G.Block (Some G.I32, layers 0 start shapes)

(** The type key and the fields of the leg a branch reads.  A branch
    that binds a field of a payload free leg is a mismatch. *)
let leg_payload (lg : L.leg) : (string * E.repr list, Err.t) result =
  Option.fold
    ~none:(Error (Err.Mismatch "a branch binds a field of a payload free leg"))
    ~some:(fun ((x : string * E.repr list)) -> Ok x)
    (L.leg_type lg)

(** The reads of a leg payload:  one local per runtime field, in
    declaration order, out of the field of the leg struct that follows
    the tag.  The answer carries the binders innermost first, so the
    last runtime field is the binder of index zero (SJ-D25). *)
let rec leg_reads (c : ctx) (s : st) (sv : int) (li : int) (i : int)
    (rs : E.repr list) : (G.instr list * (int * E.repr) list * st, Err.t) result =
  match rs with
  | [] -> Ok ([], [], s)
  | r :: more ->
      let* vt = L.valtype_of c.l r in
      let idx, s1 = alloc s vt in
      let* cz = coerce c.l L.any_repr r in
      let* irest, brest, s2 = leg_reads c s1 sv li (i + 1) more in
      Ok
        ( [ G.Local_get sv; G.Ref_cast (G.HType li); G.Struct_get (li, i + 1) ]
          @ cz @ [ G.Local_set idx ] @ irest,
          brest @ [ (idx, r) ],
          s2 )

(** One term.  [tail] is true when the value of the term is the value of
    the function, so a call in that place is a tail call. *)
let rec go (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool) (tm : E.ktm) :
    (G.instr list * st, Err.t) result =
  match tm with
  | E.KVar i ->
      L.nth_at env i
      |> Option.fold
           ~none:(Error (Err.Unbound (Printf.sprintf "KVar %d is out of scope" i)))
           ~some:(fun (((idx : int), (_r : E.repr)) : int * E.repr) ->
             Ok ([ G.Local_get idx ], s))
  | E.KLit lit -> Result.map (fun (is : G.instr list) -> (is, s)) (literal lit)
  | E.KGlobal n -> global c s n tail
  | E.KErased -> Ok ([ G.I32_const 0; G.Ref_i31 ], s)
  | E.KLet (_x, v, b) ->
      let* iv, s1 = go c s env false v in
      let* vr = rep c env v in
      let* vt = L.valtype_of c.l vr in
      let idx, s2 = alloc s1 vt in
      let* ib, s3 = go c s2 ((idx, vr) :: env) tail b in
      Ok (iv @ [ G.Local_set idx ] @ ib, s3)
  | E.KClos (E.Fid f, n, caps) ->
      let* crs = L.capture_reprs c.l.L.prog f (List.length caps) in
      let* ic, s1 =
        each2 (fun (s0 : st) (t : E.ktm) (r : E.repr) -> arg_at c s0 env t r)
          s caps crs in
      let* wi = L.func_index c.l (L.wrap_fkey f (List.length caps)) in
      let* ci = L.type_index c.l L.clos_key in
      let* ienv =
        match () with
        | () when Int.equal (List.length caps) 0 -> Ok [ G.I32_const 0; G.Ref_i31 ]
        | () ->
            let* ei = L.type_index c.l (L.env_tid crs) in
            Ok (ic @ [ G.Struct_new ei ])
      in
      Ok ([ G.I32_const n; G.Ref_func wi ] @ ienv @ [ G.Struct_new ci ], s1)
  | E.KApp (h, args) -> apply c s env false h args
  | E.KTail (h, args) -> apply c s env tail h args
  | E.KStruct (E.Tid t, fs) ->
      let* frs = L.fields_of t in
      let* ti = L.type_index c.l t in
      let* ifs, s1 =
        each2 (fun (s0 : st) (x : E.ktm) (r : E.repr) -> arg_at c s0 env x r) s fs frs
      in
      Ok (ifs @ [ G.Struct_new ti ], s1) (* SD-M3 site *)
  | E.KProj (E.Tid t, k, x) ->
      let* ix, s1 = arg_at c s env x (E.RStruct (E.Tid t)) in
      let* ti = L.type_index c.l t in
      let* r = rep c env tm in
      let* cz = coerce c.l L.any_repr r in
      Ok (ix @ [ G.Struct_get (ti, k) ] @ cz, s1)
  | E.KTag (E.Tid t, k, ps) ->
      let* ls = L.sum_legs_p c.l.L.prog t in
      let* lg = nth_leg ls k t in
      let head : G.instr list = [ G.I32_const k; G.Ref_i31 ] in
      Option.fold
        ~none:(Ok (head, s))
        ~some:(fun (((key : string), (rs : E.repr list)) : string * E.repr list) ->
          let* li = L.type_index c.l key in
          let* ip, s1 =
            each2
              (fun (s0 : st) (x : E.ktm) (rr : E.repr) -> arg_at c s0 env x rr)
              s ps rs
          in
          Ok (head @ ip @ [ G.Struct_new li ], s1))
        (L.leg_type lg)
  | E.KCase (tid, sc, bs) -> (
      let* isc, s1 = go c s env false sc in
      match bs with
      | [] -> Ok (isc @ [ G.Unreachable ], s1)
      | b0 :: brest -> case c s1 env tail tid sc isc (b0 :: brest))
  | E.KDelay (_f, _cs) -> Error (Err.Not_yet "KDelay arrives at M2")
  | E.KForce _x -> Error (Err.Not_yet "KForce arrives at M2")

and arg_at (c : ctx) (s : st) (env : (int * E.repr) list) (t : E.ktm) (r : E.repr) :
    (G.instr list * st, Err.t) result =
  let* it, s1 = go c s env false t in
  let* tr = rep c env t in
  let* cz = coerce c.l tr r in
  Ok (it @ cz, s1)

and global (c : ctx) (s : st) (n : string) (tail : bool) :
    (G.instr list * st, Err.t) result =
  match L.head_kind c.l.L.prog (E.KGlobal n) with
  | L.HFun (_x, f) ->
      let m : int = List.length f.L.params in
      let* fi = L.func_index c.l (L.fun_fkey n) in
      (match () with
      | () when m > 0 -> closure_value c s n m
      | () when tail_ok c tail f.L.result -> Ok ([ G.Return_call fi ], s)
      | () -> Ok ([ G.Call fi ], s))
  | L.HPrim _p -> closure_value c s n 2
  | L.HValue ->
      let* _r = L.global_repr c.l.L.prog n in
      Error (Err.Unbound ("no runtime value for " ^ n))

and apply (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool) (h : E.ktm)
    (args : E.ktm list) : (G.instr list * st, Err.t) result =
  match () with
  | () when Int.equal (List.length args) 0 -> go c s env tail h
  | () -> (
      match L.head_kind c.l.L.prog h with
      | L.HFun (n, f) -> direct c s env tail n f.L.params f.L.result args
      | L.HPrim p -> prim c s env tail p args
      | L.HValue ->
          let* ih, s1 = go c s env false h in
          let* hr = rep c env h in
          steps c s1 env tail ih hr args)

and direct (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool) (n : string)
    (params : E.repr list) (result : E.repr) (args : E.ktm list) :
    (G.instr list * st, Err.t) result =
  let m : int = List.length params in
  match () with
  | () when List.length args < m ->
      let* ih, s1 = closure_value c s n m in
      steps c s1 env tail ih (E.RFunc (E.Tid (L.fn_key m))) args
  | () ->
      let* ia, s1 =
        each2
          (fun (s0 : st) (x : E.ktm) (r : E.repr) -> arg_at c s0 env x r)
          s (take m args) params
      in
      let* fi = L.func_index c.l (L.fun_fkey n) in
      let rest : E.ktm list = drop m args in
      let last : G.instr list =
        if tail_ok c tail result then [ G.Return_call fi ] (* SD-M2 site *)
        else [ G.Call fi ]
      in
      (match () with
      | () when Int.equal (List.length rest) 0 -> Ok (ia @ last, s1)
      | () -> steps c s1 env tail (ia @ [ G.Call fi ]) result rest)

and prim (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool) (p : P.t)
    (args : E.ktm list) : (G.instr list * st, Err.t) result =
  match () with
  | () when List.length args < 2 ->
      let* ih, s1 = closure_value c s (P.name p) 2 in
      steps c s1 env tail ih (E.RFunc (E.Tid (L.fn_key 2))) args
  | () ->
      let* ias, s1 = each_list c s env (take 2 args) in
      let* ia = prim_args ias in
      let base, s2 = alloc_i32s s1 (prim_locals p) in
      let body : G.instr list = ia @ prim_body p base in
      let rest : E.ktm list = drop 2 args in
      (match () with
      | () when Int.equal (List.length rest) 0 -> Ok (body, s2)
      | () -> steps c s2 env tail body (L.prim_result p) rest)

and each_list (c : ctx) (s : st) (env : (int * E.repr) list) (xs : E.ktm list) :
    (G.instr list list * st, Err.t) result =
  match xs with
  | [] -> Ok ([], s)
  | x :: rest ->
      let* i1, s1 = go c s env false x in
      let* ir, s2 = each_list c s1 env rest in
      Ok (i1 :: ir, s2)

(** The generic spine of SD-D3 and SD-D4:  a head of a known arity calls
    its code, and anything else goes through the apply helper. *)
and steps (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool)
    (ih : G.instr list) (hr : E.repr) (args : E.ktm list) :
    (G.instr list * st, Err.t) result =
  match () with
  | () when Int.equal (List.length args) 0 -> Ok (ih, s)
  | () -> (
      let* ss = L.steps_of hr (List.length args) in
      match ss with
      | [] -> Ok (ih, s)
      | L.SApply k :: _more ->
          let* ia, s1 = each (fun (s0 : st) (t : E.ktm) -> go c s0 env false t) s args in
          let* fi = L.func_index c.l (L.apply_fkey k) in
          let callins : G.instr list =
            if tail_ok c tail L.any_repr then [ G.Return_call fi ] else [ G.Call fi ]
          in
          (* The helper answers an eq reference, so a partial application
             comes back to the closure repr the caller expects. *)
          let* want = L.steps_result hr k in
          let* cz = coerce c.l L.any_repr want in
          Ok (ih @ ia @ callins @ cz, s1)
      | L.SCallRef m :: _more ->
          let* cast = coerce c.l hr (E.RFunc (E.Tid (L.fn_key m))) in
          let* ci = L.type_index c.l L.clos_key in
          let* fti = L.type_index c.l (L.fn_key m) in
          let idx, s1 = alloc s (G.Ref (G.HType ci)) in
          let* ia, s2 =
            each (fun (s0 : st) (t : E.ktm) -> go c s0 env false t) s1 (take m args)
          in
          let later : E.ktm list = drop m args in
          let last : bool = Int.equal (List.length later) 0 in
          let callins : G.instr list =
            if last && tail_ok c tail L.any_repr then [ G.Return_call_ref fti ]
            else [ G.Call_ref fti ]
          in
          let spine : G.instr list =
            ih @ cast
            @ [ G.Local_set idx; G.Local_get idx; G.Struct_get (ci, 2) ]
            @ ia
            @ [ G.Local_get idx; G.Struct_get (ci, 1); G.Ref_cast (G.HType fti) ]
            @ callins
          in
          (match () with
          | () when last -> Ok (spine, s2)
          | () -> steps c s2 env tail spine L.any_repr later))

and case (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool)
    (tid : E.tid) (sc : E.ktm)
    (isc : G.instr list) (bs : E.kbranch list) : (G.instr list * st, Err.t) result =
  let sr = E.RUnion tid in
  let* stid = tid_of sr in
  let* legs = L.sum_legs_p c.l.L.prog stid in
  let* shapes = leg_shapes c legs in
  let sv, s1 = alloc s (G.Ref G.HEq) in
  let tg, s2 = alloc s1 G.I32 in
  let* cr = rep c env (E.KCase (tid, sc, bs)) in
  let* cvt = L.valtype_of c.l cr in
  let block : G.instr = tag_block sv shapes in
  let* dis, s3 = branches c s2 env tail sr sv cvt cr tg bs in
  Ok (isc @ [ G.Local_set sv; block; G.Local_set tg ] @ dis, s3)

and branches (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool) (sr : E.repr)
    (sv : int) (cvt : G.valtype) (cr : E.repr) (tg : int) (bs : E.kbranch list) :
    (G.instr list * st, Err.t) result =
  match bs with
  | [] -> Ok ([ G.Unreachable ], s)
  | b :: rest ->
      let* body, s1 = branch_body c s env tail sr sv cr b in
      let* others, s2 = branches c s1 env tail sr sv cvt cr tg rest in
      Ok
        ( [
            G.Local_get tg; G.I32_const b.E.tag; G.I32_eq; G.If (Some cvt, body, others);
          ],
          s2 )

and branch_body (c : ctx) (s : st) (env : (int * E.repr) list) (tail : bool)
    (sr : E.repr) (sv : int) (cr : E.repr) (b : E.kbranch) :
    (G.instr list * st, Err.t) result =
  let* binders = L.branch_binders c.l.L.prog sr b in
  match binders with
  | [] ->
      let* ib, s1 = go c s env tail b.E.body in
      let* br = rep c env b.E.body in
      let* cz = coerce c.l br cr in
      Ok (with_coercion ib cz, s1)
  | _r :: _more ->
      let* lg = L.branch_leg c.l.L.prog sr b in
      let* key, rs = leg_payload lg in
      let* li = L.type_index c.l key in
      let* reads, benv, s1 = leg_reads c s sv li 0 rs in
      let env2 : (int * E.repr) list = benv @ env in
      let* ib, s2 = go c s1 env2 tail b.E.body in
      let* br = rep c env2 b.E.body in
      let* cz = coerce c.l br cr in
      Ok (reads @ with_coercion ib cz, s2)

(* ---------- the functions of the module ---------- *)

(** A parameter is a local of its own index and the innermost binder is
    the last parameter. *)
let param_env (params : E.repr list) : (int * E.repr) list =
  List.rev (List.mapi (fun (i : int) (r : E.repr) -> (i, r)) params)

let prog_func (l : L.t) (f : L.fn) : (G.func, Err.t) result =
  let* ft = L.type_index l (L.sig_key f.L.params f.L.result) in
  let c : ctx = { l; res = f.L.result } in
  let s0 : st = { base = List.length f.L.params; extra = [] } in
  let* ib, s1 = go c s0 (param_env f.L.params) true f.L.body in
  let* br = L.infer l.L.prog (List.rev f.L.params) f.L.body in
  let* cz = coerce l br f.L.result in
  Ok { G.ftype = ft; locals = s1.extra; body = with_coercion ib cz }

let prim_wrapper (l : L.t) (p : P.t) : (G.func, Err.t) result =
  let* ft = L.type_index l (L.fn_key 2) in
  let pre : G.instr list =
    [
      G.Local_get 1; G.Ref_cast G.HI31; G.I31_get_u; G.Local_get 2; G.Ref_cast G.HI31;
      G.I31_get_u;
    ]
  in
  let body : G.instr list = pre @ prim_body p 3 in
  let locals : G.valtype list =
    List.init (prim_locals p) (fun (_i : int) -> G.I32)
  in
  Ok { G.ftype = ft; locals; body }

(** The generic face of a known function (SD-D2).  It reads the captures
    out of the environment, casts every argument to its typed repr and
    tail calls the typed code. *)
let wrapper (l : L.t) (name : string) (caps : int) : (G.func, Err.t) result =
  match L.head_kind l.L.prog (E.KGlobal name) with
  | L.HFun (_x, f) ->
      let n : int = List.length f.L.params - caps in
      let* ft = L.type_index l (L.fn_key n) in
      let* fi = L.func_index l (L.fun_fkey name) in
      let* capr = L.capture_reprs l.L.prog name caps in
      let* cap_ins =
        match () with
        | () when Int.equal caps 0 -> Ok []
        | () ->
            let* ei = L.type_index l (L.env_tid capr) in
            let* reads = L.seq
              (List.mapi
                 (fun (i : int) (r : E.repr) ->
                   let* cz = coerce l L.any_repr r in
                   Ok ([ G.Local_get 0; G.Ref_cast (G.HType ei); G.Struct_get (ei, i) ] @ cz))
                 capr) in
            Ok (List.concat reads)
      in
      let* arg_ins =
        L.seq
          (List.mapi
             (fun (j : int) (r : E.repr) ->
               Result.map
                 (fun (cz : G.instr list) -> [ G.Local_get (1 + j) ] @ cz)
                 (coerce l L.any_repr r))
             (drop caps f.L.params))
      in
      Ok
        {
          G.ftype = ft;
          locals = [];
          body = cap_ins @ List.concat arg_ins @ [ G.Return_call fi ];
        }
  | L.HPrim p -> prim_wrapper l p
  | L.HValue -> Error (Err.Unbound ("no runtime value for " ^ name))

(** One arm of the apply helper:  the arity the closure carries decides
    between an exact call, a call that leaves arguments over and a
    partial application (SD-D4). *)
let apply_arm (l : L.t) (k : int) (m : int) (cl : int) (ci : int) :
    (G.instr list, Err.t) result =
  let* fm = L.type_index l (L.fn_key m) in
  let env_of : G.instr list = [ G.Local_get cl; G.Struct_get (ci, 2) ] in
  let code_of : G.instr list =
    [ G.Local_get cl; G.Struct_get (ci, 1); G.Ref_cast (G.HType fm) ]
  in
  let some_args (a : int) (b : int) : G.instr list =
    List.init (b - a + 1) (fun (i : int) -> G.Local_get (a + i))
  in
  match () with
  | () when Int.equal m k ->
      Ok (env_of @ some_args 1 k @ code_of @ [ G.Return_call_ref fm ])
  | () when m < k ->
      let* rest = L.func_index l (L.apply_fkey (k - m)) in
      Ok
        (env_of @ some_args 1 m @ code_of
        @ [ G.Call_ref fm ]
        @ some_args (m + 1) k
        @ [ G.Return_call rest ])
  | () ->
      let* pi = L.type_index l (L.pap_key m k) in
      let* fw = L.func_index l (L.papw_fkey m k) in
      Ok
        ([ G.I32_const (m - k); G.Ref_func fw; G.Local_get 0 ]
        @ some_args 1 k
        @ [ G.Struct_new pi; G.Struct_new ci ])

let apply_func (l : L.t) (k : int) : (G.func, Err.t) result =
  let* ft = L.type_index l (L.apply_ty_key k) in
  let* ci = L.type_index l L.clos_key in
  let cl : int = k + 1 in
  let ar : int = k + 2 in
  let pre : G.instr list =
    [
      G.Local_get 0; G.Ref_cast (G.HType ci); G.Local_set cl; G.Local_get cl;
      G.Struct_get (ci, 0); G.Local_set ar;
    ]
  in
  let* arms =
    L.seq
      (List.map
         (fun (m : int) ->
           Result.map (fun (b : G.instr list) -> (m, b)) (apply_arm l k m cl ci))
         l.L.arities)
  in
  let chain : G.instr list =
    List.fold_right
      (fun (((m : int), (body : G.instr list)) : int * G.instr list)
           (acc : G.instr list) ->
        [
          G.Local_get ar; G.I32_const m; G.I32_eq;
          G.If (Some (G.Ref G.HEq), body, acc);
        ])
      arms [ G.Unreachable ]
  in
  Ok
    {
      G.ftype = ft;
      locals = [ G.Ref (G.HType ci); G.I32 ];
      body = pre @ chain;
    }

(** The code of a partial application:  it holds the closure and the
    arguments it already has, and calls the target once the rest
    arrives. *)
let papw_func (l : L.t) (m : int) (k : int) : (G.func, Err.t) result =
  let n : int = m - k in
  let* ft = L.type_index l (L.fn_key n) in
  let* ci = L.type_index l L.clos_key in
  let* pi = L.type_index l (L.pap_key m k) in
  let* fm = L.type_index l (L.fn_key m) in
  let pv : int = n + 1 in
  let cv : int = n + 2 in
  let pre : G.instr list =
    [
      G.Local_get 0; G.Ref_cast (G.HType pi); G.Local_set pv; G.Local_get pv;
      G.Struct_get (pi, 0); G.Ref_cast (G.HType ci); G.Local_set cv;
    ]
  in
  let saved : G.instr list =
    List.concat
      (List.init k (fun (i : int) -> [ G.Local_get pv; G.Struct_get (pi, i + 1) ]))
  in
  let fresh : G.instr list = List.init n (fun (j : int) -> G.Local_get (1 + j)) in
  Ok
    {
      G.ftype = ft;
      locals = [ G.Ref (G.HType pi); G.Ref (G.HType ci) ];
      body =
        pre
        @ [ G.Local_get cv; G.Struct_get (ci, 2) ]
        @ saved @ fresh
        @ [
            G.Local_get cv; G.Struct_get (ci, 1); G.Ref_cast (G.HType fm);
            G.Return_call_ref fm;
          ];
    }

(** The export wrapper of SD-D8:  no argument, an i32 answer, and the
    natural leaves its i31 by a signed read. *)
let entry_func (l : L.t) (export : string) : (G.func, Err.t) result =
  let* ft = L.type_index l L.entry_ty_key in
  let* fi = L.func_index l (L.fun_fkey export) in
  Ok { G.ftype = ft; locals = []; body = [ G.Call fi; G.I31_get_s ] }

let one_func (l : L.t) (export : string) (spec : L.fspec) : (G.func, Err.t) result =
  match spec with
  | L.FSProg n ->
      List.assoc_opt n l.L.prog.L.funs
      |> Option.fold
           ~none:(Error (Err.Unbound ("no function named " ^ n)))
           ~some:(fun (f : L.fn) -> prog_func l f)
  | L.FSWrap (n, caps) -> wrapper l n caps
  | L.FSApply k -> apply_func l k
  | L.FSPapw (m, k) -> papw_func l m k
  | L.FSEntry -> entry_func l export

let check_export (p : L.prog) (export : string) : (unit, Err.t) result =
  let bad : (unit, Err.t) result =
    Error (Err.Mismatch (export ^ " is not a Nat definition of arity 0"))
  in
  List.assoc_opt export p.L.funs
  |> Option.fold
       ~none:(Error (Err.Unbound ("no definition named " ^ export)))
       ~some:(fun (f : L.fn) ->
         match () with
         | () when not (Int.equal (List.length f.L.params) 0) -> bad
         | () when not (same f.L.result E.RI31) -> bad
         | () -> Ok ())

(** The binary module of a program.  The kernel table rides along for
    Stage E and is not read at M0. *)
let program (_g : Kanon_kernel.Global.t)
    (rows : (string * Kanon_kernel.Erase.entry) list) ~(export : string) :
    (string, Err.t) result =
  let* _u = check_export (L.program_table rows) export in
  let* l = L.build rows in
  let* types = L.comptype_groups l in
  let* funcs =
    L.seq
      (List.map
         (fun (((_k : string), (spec : L.fspec)) : string * L.fspec) ->
           one_func l export spec)
         l.L.funcs)
  in
  let* ei = L.func_index l L.entry_fkey in
  Ok (G.encode { G.types; funcs; exports = [ (export, ei) ]; declared = l.L.declared })
