(* carried from tot 8cf0b8b lib/global.ml, delta: header line, and the Ind, Ctor and Prim entries with their five views are dropped because they name modules that arrive at Stage B *)
(** Global environment. [add] is kernel-internal: the only sound ways to
    extend the environment are [Check.define], [Check.declare_ind] and
    [Check.define_ind], which typecheck first. The namespace is flat: an
    inductive's name and its constructor names live in the same map. *)

module StringMap = Map.Make (String)

(** Binder telescope, outermost first; each type is scoped under the
    binders before it. *)
type telescope = (Quantity.t * string * Term.t) list

(** An ordinary (possibly recursive) definition. *)
type def_entry = {
  ty : Term.t;  (** closed *)
  def : Term.t;  (** closed *)
  reducible : bool;
      (** opaque by default: evaluation unfolds only when this is set,
          and conversion never unfolds on its own *)
  rec_arg : int option;
      (** [Some k]: a rec def; evaluation unfolds it only when argument
          [k] is a canonical constructor value (guarded unfolding) *)
  partial : bool;
      (** M3 Stage C: [true] for a [def rec partial] that skipped
          [Totality.guard] (decision 10 of the M3 design verdict): its
          codomain is Div-headed and it is forced [reducible = false],
          [rec_arg = None]. Consulted only for record-keeping /
          tooling; runtime and conversion behavior are fully
          determined by [reducible] and [rec_arg] alone, exactly as
          for any other opaque non-rec-guarded def. *)
}

(** M4 Stage B: a postulated statement. An [Axiom] has no [def] and no
    [reducible], so conversion can never step into it, by the same
    argument SPEC section 3 makes for prims. [Check] additionally refuses
    it at quantity mode w, so an axiom can never reach erased output and
    [tot run] never meets one. *)
type axiom_entry = { ax_ty : Term.t }  (** closed *)

(** R-Q3: [Axiom] exists from Stage A, so the [kanon axioms] disclosure
    path has a target from the first commit. *)
type entry =
  | Def of def_entry
  | Axiom of axiom_entry  (** M4 Stage B *)

type t = entry StringMap.t

let empty : t = StringMap.empty
let find (name : string) (globals : t) : entry option = StringMap.find_opt name globals
let add (name : string) (entry : entry) (globals : t) : t = StringMap.add name entry globals

(** The closed type every entry kind stores. *)
let entry_ty (e : entry) : Term.t =
  match e with
  | Def d -> d.ty
  | Axiom a -> a.ax_ty

(** Payload views; Option-returning so callers stay total. *)
let def_of (e : entry) : def_entry option =
  match e with
  | Def d -> Some d
  | Axiom _ -> None

(** M4 Stage B: view onto the [Axiom] payload, beside the other one. *)
let axiom_of (e : entry) : axiom_entry option =
  match e with
  | Axiom a -> Some a
  | Def _ -> None

let find_def (name : string) (globals : t) : def_entry option =
  Option.bind (find name globals) def_of

let find_axiom (name : string) (globals : t) : axiom_entry option =
  Option.bind (find name globals) axiom_of
