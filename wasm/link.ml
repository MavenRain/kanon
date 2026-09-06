(** One pass from the erased rows to indices.  link.ml parses the tid
    texts of the erased form, dedups them by text, orders the composite
    types and the functions, and answers an index for every name emit.ml
    needs.  The emitter never computes an index (eterm.ml, repair one).

    The repr of a term is inferred here too (SD-D20):  the type table
    needs the repr of every capture and of every let, so inference and
    index assignment are the same walk over the program.

    No shape name appears in this file. *)

module E = Kanon_kernel.Eterm
module Err = Kanon_kernel.Error
module P = Kanon_kernel.Prim
module G = Gc_encode

let ( let* ) = Result.bind

let rec seq (xs : ('a, Err.t) result list) : ('a list, Err.t) result =
  match xs with
  | [] -> Ok []
  | x :: rest ->
      let* v = x in
      let* vs = seq rest in
      Ok (v :: vs)

(** The total reader of a list position (SD-D22).  A position outside the
    list answers [None], and a negative position walks the list down to
    the empty case, so the reader is total and terminates. *)
let rec nth_at (xs : 'a list) (i : int) : 'a option =
  match (xs, i) with
  | [], _k -> None
  | x :: _rest, 0 -> Some x
  | _x :: rest, k -> nth_at rest (k - 1)

let first_some (fs : (unit -> 'a option) list) : 'a option =
  List.fold_left
    (fun (acc : 'a option) (f : unit -> 'a option) ->
      if Option.is_some acc then acc else f ())
    None fs

(* ---------- the tid grammar ---------- *)

let slice (s : string) (start : int) (len : int) : string =
  if start >= 0 && len >= 0 && start + len <= String.length s then
    String.sub s start len (* @total-accessor *)
  else ""

(** The text between a prefix and the closing angle bracket. *)
let inside (prefix : string) (s : string) : string option =
  if String.starts_with ~prefix s && String.ends_with ~suffix:">" s then
    Some (slice s (String.length prefix) (String.length s - String.length prefix - 1))
  else None

(** Split on a separator at bracket depth zero, so a nested tid text
    keeps its own separators. *)
let split_top (sep : char) (s : string) : string list =
  let one (c : char) : string = String.make 1 c in
  let _depth, cur, acc =
    String.fold_left
      (fun ((d : int), (cur : string), (acc : string list)) (c : char) ->
        match () with
        | () when Char.equal c '<' -> (d + 1, cur ^ one c, acc)
        | () when Char.equal c '>' -> (d - 1, cur ^ one c, acc)
        | () when Char.equal c sep && Int.equal d 0 -> (d, "", acc @ [ cur ])
        | () -> (d, cur ^ one c, acc))
      (0, "", []) s
  in
  acc @ [ cur ]

let repr_of_text (s : string) : (E.repr, Err.t) result =
  let tail (p : string) : string =
    slice s (String.length p) (String.length s - String.length p)
  in
  match () with
  | () when String.equal s "i31" -> Ok E.RI31
  | () when String.starts_with ~prefix:"struct " s ->
      Ok (E.RStruct (E.Tid (tail "struct ")))
  | () when String.starts_with ~prefix:"union " s ->
      Ok (E.RUnion (E.Tid (tail "union ")))
  | () when String.starts_with ~prefix:"func " s -> Ok (E.RFunc (E.Tid (tail "func ")))
  | () when String.starts_with ~prefix:"thunk " s ->
      Ok (E.RThunk (E.Tid (tail "thunk ")))
  | () -> Error (Err.Mismatch ("a repr does not parse:  " ^ s))

type leg =
  | LUnit  (** a payload free leg *)
  | LRepr of E.repr

type form =
  | FI31
  | FUnit
  | FAny
  | FFields of E.repr list  (** pair and tuple *)
  | FSum of leg list
  | FFn of int

let parse_fields (body : string) : (E.repr list, Err.t) result =
  if String.equal body "" then Ok [] else seq (List.map repr_of_text (split_top ',' body))

let parse_legs (body : string) : (leg list, Err.t) result =
  if String.equal body "" then Ok []
  else
    seq
      (List.map
         (fun (t : string) ->
           if String.equal t "unit" then Ok LUnit
           else Result.map (fun (r : E.repr) -> LRepr r) (repr_of_text t))
         (split_top '|' body))

let parse_tid (t : string) : (form, Err.t) result =
  let wrapped (pfx : string) (k : string -> (form, Err.t) result) :
      unit -> (form, Err.t) result option =
   fun () -> Option.map k (inside pfx t)
  in
  let word (w : string) (f : form) : unit -> (form, Err.t) result option =
   fun () -> if String.equal t w then Some (Ok f) else None
  in
  first_some
    [
      word "i31" FI31;
      word "unit" FUnit;
      word "any" FAny;
      wrapped "fn<" (fun (b : string) ->
          Option.fold
            ~none:(Error (Err.Mismatch ("an arity does not parse:  " ^ t)))
            ~some:(fun (n : int) -> Ok (FFn n))
            (int_of_string_opt b));
      wrapped "pair<" (fun (b : string) ->
          Result.map (fun (rs : E.repr list) -> FFields rs) (parse_fields b));
      wrapped "tuple<" (fun (b : string) ->
          Result.map (fun (rs : E.repr list) -> FFields rs) (parse_fields b));
      wrapped "sum<" (fun (b : string) ->
          Result.map (fun (ls : leg list) -> FSum ls) (parse_legs b));
    ]
  |> Option.fold
       ~none:(Error (Err.Mismatch ("a tid does not parse:  " ^ t)))
       ~some:Fun.id

let tid_text (r : E.repr) : string option =
  match r with
  | E.RI31 -> None
  | E.RStruct (E.Tid t) -> Some t
  | E.RUnion (E.Tid t) -> Some t
  | E.RFunc (E.Tid t) -> Some t
  | E.RThunk (E.Tid t) -> Some t

(* ---------- the program table ---------- *)

type fn = {
  params : E.repr list;
  result : E.repr;
  body : E.ktm;
}

type prog = {
  funs : (string * fn) list;  (** every KFun of every entry, in order *)
  posts : (string * E.repr) list;  (** the axioms with a runtime type *)
}

let clos_key : string = "clos"
let fn_key (n : int) : string = Printf.sprintf "fn<%d>" n
let apply_ty_key (k : int) : string = Printf.sprintf "applyfn<%d>" k
let pap_key (m : int) (k : int) : string = Printf.sprintf "pap<%d,%d>" m k
let entry_ty_key : string = "entryfn"

let leg_key (rs : E.repr list) : string =
  "leg<" ^ String.concat "," (List.map E.print_repr rs) ^ ">"

let sig_key (params : E.repr list) (result : E.repr) : string =
  "sig<"
  ^ String.concat "," (List.map E.print_repr params)
  ^ "->" ^ E.print_repr result ^ ">"

let env_tid (rs : E.repr list) : string =
  "tuple<" ^ String.concat "," (List.map E.print_repr rs) ^ ">"

let fun_fkey (name : string) : string = "fun:" ^ name
let wrap_fkey (name : string) (caps : int) : string = Printf.sprintf "wrap:%s:%d" name caps
let apply_fkey (k : int) : string = Printf.sprintf "apply:%d" k
let papw_fkey (m : int) (k : int) : string = Printf.sprintf "papw:%d:%d" m k
let entry_fkey : string = "entry"

let decls_of_entry (e : Kanon_kernel.Erase.entry) : E.kdecl list =
  match e with
  | Kanon_kernel.Erase.Dropped -> []
  | Kanon_kernel.Erase.Postulate _ -> []
  | Kanon_kernel.Erase.Code ds -> ds

let fn_of_decl (d : E.kdecl) : (string * fn) list =
  match d with
  | E.KFun (E.Fid f, params, result, body) -> [ (f, { params; result; body }) ]
  | E.KRec _ -> []

let post_of_row ((name : string), (e : Kanon_kernel.Erase.entry)) : (string * E.repr) list =
  match e with
  | Kanon_kernel.Erase.Postulate r -> [ (name, r) ]
  | Kanon_kernel.Erase.Dropped -> []
  | Kanon_kernel.Erase.Code _ -> []

let program_table (rows : (string * Kanon_kernel.Erase.entry) list) : prog =
  {
    funs =
      List.concat_map
        (fun ((_n : string), (e : Kanon_kernel.Erase.entry)) ->
          List.concat_map fn_of_decl (decls_of_entry e))
        rows;
    posts = List.concat_map post_of_row rows;
  }

(** The result repr of a primitive.  natEq and natLt answer the two leg
    sum of the unit type, which is what a boolean is at M0. *)
let prim_result (p : P.t) : E.repr =
  match p with
  | P.Nat_add -> E.RI31
  | P.Nat_sub -> E.RI31
  | P.Nat_mul -> E.RI31
  | P.Nat_eq -> E.RUnion (E.Tid "sum<unit|unit>")
  | P.Nat_lt -> E.RUnion (E.Tid "sum<unit|unit>")

let prim_params : E.repr list = [ E.RI31; E.RI31 ]

(** What a head of an application is.  A global with a known arity calls
    through its typed signature;  anything else is a closure value. *)
type headk =
  | HFun of string * fn
  | HPrim of P.t
  | HValue

let head_kind (p : prog) (h : E.ktm) : headk =
  match h with
  | E.KGlobal n ->
      List.assoc_opt n p.funs
      |> Option.fold
           ~none:
             (P.of_name n |> Option.fold ~none:HValue ~some:(fun (x : P.t) -> HPrim x))
           ~some:(fun (f : fn) -> HFun (n, f))
  | E.KVar _ | E.KLit _ | E.KErased | E.KLet _ | E.KClos _ | E.KApp _ | E.KTail _
  | E.KStruct _ | E.KProj _ | E.KTag _ | E.KCase _ | E.KDelay _ | E.KForce _ ->
      HValue

(* ---------- repr inference ---------- *)

let sum_legs (t : string) : (leg list, Err.t) result =
  let* f = parse_tid t in
  match f with
  | FSum ls -> Ok ls
  | FI31 | FUnit | FAny | FFields _ | FFn _ ->
      Error (Err.Mismatch ("a case scrutinee is not a sum:  " ^ t))

let fields_of (t : string) : (E.repr list, Err.t) result =
  let* f = parse_tid t in
  match f with
  | FFields rs -> Ok rs
  | FI31 | FUnit | FAny | FSum _ | FFn _ ->
      Error (Err.Mismatch ("a struct tid is not a pair or a tuple:  " ^ t))

let arity_of_fn (t : string) : (int, Err.t) result =
  let* f = parse_tid t in
  match f with
  | FFn n -> Ok n
  | FI31 | FUnit | FAny | FSum _ | FFields _ ->
      Error (Err.Mismatch ("a function repr is not fn<n>:  " ^ t))

let any_repr : E.repr = E.RUnion (E.Tid "any")

(** Construction, registration and the wrapper share the lifted
    function's capture signature, even when a capture expression is
    inferred as any after a generic call. *)
let capture_reprs (p : prog) (name : string) (count : int) :
    (E.repr list, Err.t) result =
  let* f = List.assoc_opt name p.funs
    |> Option.to_result ~none:(Err.Unbound ("no function named " ^ name)) in
  if count < 0 || count > List.length f.params then
    Error (Err.Mismatch ("invalid capture count for " ^ name))
  else Ok (List.filteri (fun (i : int) (_r : E.repr) -> i < count) f.params)

(** The binders a branch adds, innermost first.  A leg of an M0 sum
    carries one field or none (SD-D21), so a branch adds one repr or
    nothing. *)
let branch_binders (scrut : E.repr) (b : E.kbranch) : (E.repr list, Err.t) result =
  if Int.equal b.E.arity 0 then Ok []
  else
    tid_text scrut
    |> Option.fold
         ~none:(Error (Err.Mismatch "a case scrutinee has no tid"))
         ~some:(fun (t : string) ->
           let* ls = sum_legs t in
           nth_at ls b.E.tag
           |> Option.fold
                ~none:
                  (Error (Err.Wrong_leg (Printf.sprintf "leg %d of %s" b.E.tag t)))
                ~some:(fun (l : leg) ->
                  match l with
                  | LUnit -> Ok []
                  | LRepr r -> Ok [ r ]))

(** The generic steps of an application whose head is already a value.
    A head of a known arity calls its code directly (SD-D3);  anything
    else goes through the apply helper of SD-D4. *)
type step =
  | SCallRef of int
  | SApply of int

let rec steps_of (r : E.repr) (k : int) : (step list, Err.t) result =
  if Int.equal k 0 then Ok []
  else
    match r with
    | E.RFunc (E.Tid t) ->
        let* m = arity_of_fn t in
        if m > 0 && m <= k then
          Result.map (fun (rest : step list) -> SCallRef m :: rest) (steps_of any_repr (k - m))
        else Ok [ SApply k ]
    | E.RUnion _ -> Ok [ SApply k ]
    | E.RI31 | E.RStruct _ ->
        Error (Err.Mismatch "an application head is not a function")
    | E.RThunk _ -> Error (Err.Not_yet "KForce arrives at M2")

let rec steps_result (r : E.repr) (k : int) : (E.repr, Err.t) result =
  if Int.equal k 0 then Ok r
  else
    match r with
    | E.RFunc (E.Tid t) ->
        let* m = arity_of_fn t in
        (match () with
        | () when m > 0 && m <= k -> steps_result any_repr (k - m)
        | () when m > k -> Ok (E.RFunc (E.Tid (fn_key (m - k))))
        | () -> Ok any_repr)
    | E.RUnion _ -> Ok any_repr
    | E.RI31 | E.RStruct _ ->
        Error (Err.Mismatch "an application head is not a function")
    | E.RThunk _ -> Error (Err.Not_yet "KForce arrives at M2")

let rec infer (p : prog) (env : E.repr list) (tm : E.ktm) : (E.repr, Err.t) result =
  match tm with
  | E.KVar i ->
      nth_at env i
      |> Option.fold
           ~none:(Error (Err.Unbound (Printf.sprintf "KVar %d is out of scope" i)))
           ~some:(fun (r : E.repr) -> Ok r)
  | E.KLit _l -> Ok E.RI31
  | E.KGlobal n -> global_repr p n
  | E.KErased -> Ok any_repr
  | E.KLet (_x, v, b) ->
      let* vr = infer p env v in
      infer p (vr :: env) b
  | E.KClos (_f, n, _caps) -> Ok (E.RFunc (E.Tid (fn_key n)))
  | E.KApp (h, args) -> app_repr p env h args
  | E.KTail (h, args) -> app_repr p env h args
  | E.KStruct (t, _fs) -> Ok (E.RStruct t)
  | E.KProj (E.Tid t, k, _x) ->
      let* rs = fields_of t in
      nth_at rs k
      |> Option.fold
           ~none:(Error (Err.Wrong_leg (Printf.sprintf "field %d of %s" k t)))
           ~some:(fun (r : E.repr) -> Ok r)
  | E.KTag (t, _k, _ps) -> Ok (E.RUnion t)
  | E.KCase (tid, _s, bs) -> (
      match bs with
      | [] -> Ok any_repr
      | b :: _rest ->
          let* binders = branch_binders (E.RUnion tid) b in
          infer p (binders @ env) b.E.body)
  | E.KDelay (_f, _cs) -> Error (Err.Not_yet "KDelay arrives at M2")
  | E.KForce _x -> Error (Err.Not_yet "KForce arrives at M2")

and global_repr (p : prog) (n : string) : (E.repr, Err.t) result =
  match head_kind p (E.KGlobal n) with
  | HFun (_name, f) ->
      if Int.equal (List.length f.params) 0 then Ok f.result
      else Ok (E.RFunc (E.Tid (fn_key (List.length f.params))))
  | HPrim _pr -> Ok (E.RFunc (E.Tid (fn_key 2)))
  | HValue ->
      List.assoc_opt n p.posts
      |> Option.fold
           ~none:(Error (Err.Unbound ("no runtime declaration for " ^ n)))
           ~some:(fun (_r : E.repr) ->
             Error (Err.Unbound ("axiom " ^ n ^ " has no body")))

and app_repr (p : prog) (env : E.repr list) (h : E.ktm) (args : E.ktm list) :
    (E.repr, Err.t) result =
  let k : int = List.length args in
  if Int.equal k 0 then infer p env h
  else
    match head_kind p h with
    | HFun (_n, f) -> after_head (List.length f.params) f.result k
    | HPrim pr -> after_head 2 (prim_result pr) k
    | HValue ->
        let* hr = infer p env h in
        steps_result hr k

and after_head (m : int) (res : E.repr) (k : int) : (E.repr, Err.t) result =
  match () with
  | () when Int.equal k m -> Ok res
  | () when k > m -> steps_result res (k - m)
  | () -> steps_result (E.RFunc (E.Tid (fn_key m))) k

(* ---------- the keys the program needs ---------- *)

type tspec =
  | TSClos
  | TSFn of int
  | TSStruct of E.repr list
  | TSLeg of E.repr list
  | TSPap of int
  | TSSig of E.repr list * E.repr
  | TSApply of int
  | TSEntry

type fspec =
  | FSProg of string
  | FSWrap of string * int
  | FSApply of int
  | FSPapw of int * int
  | FSEntry

type keys = {
  tys : (string * tspec) list;
  fns : (string * fspec) list;
}

let no_keys : keys = { tys = []; fns = [] }
let merge (a : keys) (b : keys) : keys = { tys = a.tys @ b.tys; fns = a.fns @ b.fns }
let merge_all (xs : keys list) : keys = List.fold_left merge no_keys xs
let ty_key (k : string) (s : tspec) : keys = { tys = [ (k, s) ]; fns = [] }
let fn_key_of (k : string) (s : fspec) : keys = { tys = []; fns = [ (k, s) ] }
let clos_keys : keys = ty_key clos_key TSClos
let fnty_keys (n : int) : keys = merge clos_keys (ty_key (fn_key n) (TSFn n))

let rec need_repr (r : E.repr) : (keys, Err.t) result =
  match r with
  | E.RI31 -> Ok no_keys
  | E.RUnion _t -> Ok no_keys
  | E.RStruct (E.Tid t) -> need_struct t
  | E.RFunc (E.Tid t) ->
      let* n = arity_of_fn t in
      Ok (fnty_keys n)
  | E.RThunk _t -> Error (Err.Not_yet "RThunk arrives at M2")

and need_struct (t : string) : (keys, Err.t) result =
  let* rs = fields_of t in
  let* inner = seq (List.map need_repr rs) in
  Ok (merge (ty_key t (TSStruct rs)) (merge_all inner))

let need_sum (t : string) : (keys, Err.t) result =
  let* ls = sum_legs t in
  let* inner =
    seq
      (List.map
         (fun (l : leg) ->
           match l with
           | LUnit -> Ok no_keys
           | LRepr r ->
               let* k = need_repr r in
               Ok (merge k (ty_key (leg_key [ r ]) (TSLeg [ r ]))))
         ls)
  in
  Ok (merge_all inner)

let need_steps (ss : step list) : keys =
  merge_all
    (List.map
       (fun (s : step) ->
         match s with
         | SCallRef m -> fnty_keys m
         | SApply k ->
             merge_all
               [
                 clos_keys;
                 ty_key (apply_ty_key k) (TSApply k);
                 fn_key_of (apply_fkey k) (FSApply k);
               ])
       ss)

(** The wrapper a global needs when it is a value and not a call. *)
let need_wrap (p : prog) (n : string) : (keys, Err.t) result =
  match head_kind p (E.KGlobal n) with
  | HFun (_x, f) ->
      let m : int = List.length f.params in
      let* ps = seq (List.map need_repr f.params) in
      let* rr = need_repr f.result in
      Ok
        (merge_all
           [
             fnty_keys m;
             fn_key_of (wrap_fkey n 0) (FSWrap (n, 0));
             merge_all ps;
             rr;
           ])
  | HPrim _pr ->
      Ok (merge (fnty_keys 2) (fn_key_of (wrap_fkey n 0) (FSWrap (n, 0))))
  | HValue -> Result.map (fun (_r : E.repr) -> no_keys) (global_repr p n)

(** The walk that collects every key.  Lets use expression inference;
    captures use the lifted signature and cases use their retained tid. *)
let rec walk (p : prog) (env : E.repr list) (tm : E.ktm) : (keys, Err.t) result =
  match tm with
  | E.KVar _i -> Ok no_keys
  | E.KLit _l -> Ok no_keys
  | E.KErased -> Ok no_keys
  | E.KGlobal n -> (
      match head_kind p (E.KGlobal n) with
      | HFun (_x, f) ->
          if Int.equal (List.length f.params) 0 then Ok no_keys else need_wrap p n
      | HPrim _pr -> need_wrap p n
      | HValue -> Result.map (fun (_r : E.repr) -> no_keys) (global_repr p n))
  | E.KLet (_x, v, b) ->
      let* kv = walk p env v in
      let* vr = infer p env v in
      let* kr = need_repr vr in
      let* kb = walk p (vr :: env) b in
      Ok (merge_all [ kv; kr; kb ])
  | E.KClos (E.Fid f, n, caps) ->
      let* kc = seq (List.map (walk p env) caps) in
      let* crs = capture_reprs p f (List.length caps) in
      let* krs = seq (List.map need_repr crs) in
      let* kenv =
        if Int.equal (List.length crs) 0 then Ok no_keys else need_struct (env_tid crs)
      in
      Ok
        (merge_all
           [
             fnty_keys n;
             fn_key_of (wrap_fkey f (List.length caps)) (FSWrap (f, List.length caps));
             kenv;
             merge_all kc;
             merge_all krs;
           ])
  | E.KApp (h, args) -> walk_app p env h args
  | E.KTail (h, args) -> walk_app p env h args
  | E.KStruct (E.Tid t, fs) ->
      let* kt = need_struct t in
      let* kf = seq (List.map (walk p env) fs) in
      Ok (merge kt (merge_all kf))
  | E.KProj (E.Tid t, _k, x) ->
      let* kt = need_struct t in
      let* kx = walk p env x in
      Ok (merge kt kx)
  | E.KTag (E.Tid t, _k, ps) ->
      let* kt = need_sum t in
      let* kp = seq (List.map (walk p env) ps) in
      Ok (merge kt (merge_all kp))
  | E.KCase (E.Tid t, s, bs) ->
      let* ks = walk p env s in
      let sr = E.RUnion (E.Tid t) in
      let* ksum =
        match bs with
        | [] -> Ok no_keys
        | _b :: _rest -> need_sum t
      in
      let* rr = infer p env tm in
      let* krr = need_repr rr in
      let* kbs =
        seq
          (List.map
             (fun (b : E.kbranch) ->
               let* binders = branch_binders sr b in
               let* kb = walk p (binders @ env) b.E.body in
               let* kbind = seq (List.map need_repr binders) in
               Ok (merge kb (merge_all kbind)))
             bs)
      in
      Ok (merge_all [ ks; ksum; krr; merge_all kbs ])
  | E.KDelay (_f, _cs) -> Error (Err.Not_yet "KDelay arrives at M2")
  | E.KForce _x -> Error (Err.Not_yet "KForce arrives at M2")

and walk_app (p : prog) (env : E.repr list) (h : E.ktm) (args : E.ktm list) :
    (keys, Err.t) result =
  let k : int = List.length args in
  let* ka = seq (List.map (walk p env) args) in
  if Int.equal k 0 then
    let* kh = walk p env h in
    Ok (merge kh (merge_all ka))
  else
    let saturated (m : int) (res : E.repr) : (keys, Err.t) result =
      let* ss = steps_of res (k - m) in
      Ok (merge (merge_all ka) (need_steps ss))
    in
    let under (n : string) (m : int) : (keys, Err.t) result =
      let* kw = need_wrap p n in
      let* ss = steps_of (E.RFunc (E.Tid (fn_key m))) k in
      Ok (merge_all [ merge_all ka; kw; need_steps ss ])
    in
    match head_kind p h with
    | HFun (n, f) ->
        let m : int = List.length f.params in
        if k >= m then saturated m f.result else under n m
    | HPrim pr -> if k >= 2 then saturated 2 (prim_result pr) else under (P.name pr) 2
    | HValue ->
        let* kh = walk p env h in
        let* hr = infer p env h in
        let* ss = steps_of hr k in
        Ok (merge_all [ kh; merge_all ka; need_steps ss ])

let walk_fun (p : prog) (((name : string), (f : fn)) : string * fn) :
    (keys, Err.t) result =
  let* ps = seq (List.map need_repr f.params) in
  let* rr = need_repr f.result in
  let* kb = walk p (List.rev f.params) f.body in
  Ok
    (merge_all
       [
         ty_key (sig_key f.params f.result) (TSSig (f.params, f.result));
         fn_key_of (fun_fkey name) (FSProg name);
         merge_all ps;
         rr;
         kb;
       ])

(* ---------- the closure over the helper arities ---------- *)

let dedup_int (xs : int list) : int list =
  List.fold_left
    (fun (acc : int list) (x : int) -> if List.mem x acc then acc else acc @ [ x ])
    [] xs

let dedup_ty (xs : (string * tspec) list) : (string * tspec) list =
  List.fold_left
    (fun (acc : (string * tspec) list) (((k : string), (s : tspec)) : string * tspec) ->
      if List.mem_assoc k acc then acc else acc @ [ (k, s) ])
    [] xs

let dedup_fn (xs : (string * fspec) list) : (string * fspec) list =
  List.fold_left
    (fun (acc : (string * fspec) list) (((k : string), (s : fspec)) : string * fspec) ->
      if List.mem_assoc k acc then acc else acc @ [ (k, s) ])
    [] xs

(** One round of the fixpoint of SD-D4.  An apply of [k] arguments on a
    closure of arity [m] leaves [k - m] arguments for another apply when
    [m] is the smaller one, and builds a partial application of arity
    [m - k] when [k] is. *)
let step_once (a : int list) (k : int list) : int list * int list =
  ( dedup_int
      (a
      @ List.concat_map
          (fun (m : int) ->
            List.filter_map
              (fun (kk : int) -> if m > kk then Some (m - kk) else None)
              k)
          a),
    dedup_int
      (k
      @ List.concat_map
          (fun (kk : int) ->
            List.filter_map
              (fun (m : int) -> if kk > m && m > 0 then Some (kk - m) else None)
              a)
          k) )

let rec close_arities (a : int list) (k : int list) (fuel : int) : int list * int list =
  if fuel <= 0 then (a, k)
  else
    let a2, k2 = step_once a k in
    if
      Int.equal (List.length a2) (List.length a)
      && Int.equal (List.length k2) (List.length k)
    then (a, k)
    else close_arities a2 k2 (fuel - 1)

let helper_keys (a : int list) (k : int list) : keys =
  merge_all
    (List.map
       (fun (kk : int) ->
         merge
           (ty_key (apply_ty_key kk) (TSApply kk))
           (fn_key_of (apply_fkey kk) (FSApply kk)))
       k
    @ List.map (fun (m : int) -> ty_key (fn_key m) (TSFn m)) a
    @ List.concat_map
        (fun (m : int) ->
          List.filter_map
            (fun (kk : int) ->
              if m > kk then
                Some
                  (merge_all
                     [
                       ty_key (pap_key m kk) (TSPap kk);
                       fn_key_of (papw_fkey m kk) (FSPapw (m, kk));
                       ty_key (fn_key (m - kk)) (TSFn (m - kk));
                     ])
              else None)
            k)
        a)

(* ---------- the order of the sections ---------- *)

(** A composite type may name only an earlier one, so the ranks put the
    closure first, then the generic function types, then the struct tids
    by nesting depth, then the shapes built here. *)
let trank (s : tspec) : int =
  match s with
  | TSClos -> 0
  | TSFn _n -> 1
  | TSStruct _rs -> 2
  | TSLeg _rs -> 3
  | TSPap _k -> 4
  | TSSig (_ps, _r) -> 5
  | TSApply _k -> 6
  | TSEntry -> 7

let frank (s : fspec) : int =
  match s with
  | FSProg _n -> 0
  | FSWrap (_n, _c) -> 1
  | FSApply _k -> 2
  | FSPapw (_m, _k) -> 3
  | FSEntry -> 4

let depth (s : string) : int =
  String.fold_left
    (fun (n : int) (c : char) -> if Char.equal c '<' then n + 1 else n)
    0 s

let order_types (xs : (string * tspec) list) : (string * tspec) list =
  List.stable_sort
    (fun (((ka : string), (sa : tspec)) : string * tspec)
         (((kb : string), (sb : tspec)) : string * tspec) ->
      Stdlib.compare (trank sa, depth ka) (trank sb, depth kb))
    xs

let order_funcs (xs : (string * fspec) list) : (string * fspec) list =
  List.stable_sort
    (fun (((_ka : string), (sa : fspec)) : string * fspec)
         (((_kb : string), (sb : fspec)) : string * fspec) ->
      Int.compare (frank sa) (frank sb))
    xs

let indices (xs : (string * 'a) list) : (string * int) list =
  List.mapi (fun (i : int) (((k : string), (_s : 'a)) : string * 'a) -> (k, i)) xs

(* ---------- the answer ---------- *)

type t = {
  prog : prog;
  types : (string * tspec) list;
  tmap : (string * int) list;
  funcs : (string * fspec) list;
  fmap : (string * int) list;
  arities : int list;  (** every closure arity the module builds *)
  calls : int list;  (** every apply the module needs *)
  declared : int list;  (** the functions the module declares *)
}

let arity_keys (tys : (string * tspec) list) : int list =
  dedup_int
    (List.filter_map
       (fun (((_k : string), (s : tspec)) : string * tspec) ->
         match s with
         | TSFn n -> Some n
         | TSClos | TSStruct _ | TSLeg _ | TSPap _ | TSSig _ | TSApply _ | TSEntry ->
             None)
       tys)

let call_keys (tys : (string * tspec) list) : int list =
  dedup_int
    (List.filter_map
       (fun (((_k : string), (s : tspec)) : string * tspec) ->
         match s with
         | TSApply n -> Some n
         | TSClos | TSFn _ | TSStruct _ | TSLeg _ | TSPap _ | TSSig _ | TSEntry -> None)
       tys)

let build (rows : (string * Kanon_kernel.Erase.entry) list) : (t, Err.t) result =
  let p : prog = program_table rows in
  let* ks = seq (List.map (walk_fun p) p.funs) in
  let base : keys =
    merge (merge_all ks)
      (merge (ty_key entry_ty_key TSEntry) (fn_key_of entry_fkey FSEntry))
  in
  let tys0 : (string * tspec) list = dedup_ty base.tys in
  let fns0 : (string * fspec) list = dedup_fn base.fns in
  let a, k = close_arities (arity_keys tys0) (call_keys tys0) 64 in
  let extra : keys = helper_keys a k in
  let types : (string * tspec) list = order_types (dedup_ty (tys0 @ extra.tys)) in
  let funcs : (string * fspec) list = order_funcs (dedup_fn (fns0 @ extra.fns)) in
  let fmap : (string * int) list = indices funcs in
  Ok
    {
      prog = p;
      types;
      tmap = indices types;
      funcs;
      fmap;
      arities = a;
      calls = k;
      declared =
        List.filter_map
          (fun (((key : string), (s : fspec)) : string * fspec) ->
            match s with
            | FSWrap (_n, _c) -> List.assoc_opt key fmap
            | FSPapw (_m, _kk) -> List.assoc_opt key fmap
            | FSProg _ | FSApply _ | FSEntry -> None)
          funcs;
    }

let type_index (l : t) (key : string) : (int, Err.t) result =
  List.assoc_opt key l.tmap
  |> Option.fold
       ~none:(Error (Err.Unbound ("no type index for " ^ key)))
       ~some:(fun (i : int) -> Ok i)

let func_index (l : t) (key : string) : (int, Err.t) result =
  List.assoc_opt key l.fmap
  |> Option.fold
       ~none:(Error (Err.Unbound ("no function index for " ^ key)))
       ~some:(fun (i : int) -> Ok i)

(** The value type of a repr.  A function value is a closure struct and a
    sum value is an eq reference, so only a pair, a tuple and a tagged
    integer name a type index (SD-D6). *)
let valtype_of (l : t) (r : E.repr) : (G.valtype, Err.t) result =
  match r with
  | E.RI31 -> Ok (G.Ref G.HI31)
  | E.RUnion _t -> Ok (G.Ref G.HEq)
  | E.RStruct (E.Tid t) -> Result.map (fun (i : int) -> G.Ref (G.HType i)) (type_index l t)
  | E.RFunc _t -> Result.map (fun (i : int) -> G.Ref (G.HType i)) (type_index l clos_key)
  | E.RThunk _t -> Error (Err.Not_yet "RThunk arrives at M2")

let eqs (n : int) : G.valtype list = List.init n (fun (_i : int) -> G.Ref G.HEq)

(** Aggregate storage is uniform across type instantiations.  A pair of
    any values and a pair of naturals have identical final struct types,
    so an erased type argument cannot change their layout.  Reads cast
    each field to its checked repr; function signatures stay typed. *)
let comptype_of (l : t) (((_key : string), (s : tspec)) : string * tspec) :
    (G.comptype, Err.t) result =
  match s with
  | TSClos -> Ok (G.CStruct [ G.I32; G.Ref G.HFunc; G.Ref G.HEq ])
  | TSFn n -> Ok (G.CFunc (eqs (n + 1), [ G.Ref G.HEq ]))
  | TSStruct rs -> Ok (G.CStruct (eqs (List.length rs)))
  | TSLeg rs -> Ok (G.CStruct (G.Ref G.HI31 :: eqs (List.length rs)))
  | TSPap k -> Ok (G.CStruct (eqs (k + 1)))
  | TSSig (ps, r) ->
      let* vs = seq (List.map (valtype_of l) ps) in
      let* v = valtype_of l r in
      Ok (G.CFunc (vs, [ v ]))
  | TSApply k -> Ok (G.CFunc (eqs (k + 1), [ G.Ref G.HEq ]))
  | TSEntry -> Ok (G.CFunc ([], [ G.I32 ]))

let comptypes (l : t) : (G.comptype list, Err.t) result =
  seq (List.map (comptype_of l) l.types)
