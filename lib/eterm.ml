(** The erased intermediate form, plan section 7, declared whole at Stage A
    (D-M0-2).  Types only at Stage A;  erase.ml fills it at Stage C and
    emit.ml refuses the arms past M0 with their milestone name at Stage D.

    Repair one of the verdict: [tid] and [fid] are symbolic names and never
    integers, and link.ml resolves them to type and function indices in one
    pass, so the emitter never computes an index.

    Repair three: [KClos] carries its arity, so partial application and
    over-application never touch the closure body.

    [KDelay], [KForce] and [RThunk] are M2 and are refused by emit at M0. *)

type tid = Tid of string
type fid = Fid of string

type repr =
  | RI31
  | RStruct of tid
  | RUnion of tid
  | RFunc of tid
  | RThunk of tid

type ktm =
  | KVar of int
  | KLit of Literal.t
  | KGlobal of string
  | KErased
  | KLet of string * ktm * ktm
  | KClos of fid * int * ktm list
  | KApp of ktm * ktm list
  | KTail of ktm * ktm list
  | KStruct of tid * ktm list
  | KProj of tid * int * ktm
  | KTag of tid * int * ktm list
  | KCase of ktm * kbranch list
  | KDelay of fid * ktm list
  | KForce of ktm

and kbranch = {
  tag : int;
  arity : int;
  body : ktm;
}

(** Repair two: [KRec] is one rec group per definition group.  At M0 every
    declaration owns its group;  M1's mutual recursive shape shares one. *)
type kdecl =
  | KFun of fid * repr list * repr * ktm
  | KRec of tid list
