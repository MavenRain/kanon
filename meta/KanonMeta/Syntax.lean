/-
Copyright (c) 2026 Onyeka Obi.  All rights reserved.
Released under MIT OR Apache 2.0 license.

The object language of the kanon kernel, mirrored in Lean 4.

`Shape` carries the M0 shapes `SPi` and `SColl` and the M1 inductive
shape `SMu`, retaining its declaration name and index terms.  `SPar`
and `SNu` stay out.  This is raw syntax: its constructors do not assert
that every former and shape combination passes the kernel checker.

`Term` carries the twelve M0 constructors of lib/term.ml, in the order of
SPEC.md:26-42.  `Auto` stays out because check.ml refuses it until M2.
Variables are de Bruijn indices, as lib/term.ml holds `Var of int`
(SF-D5).  `Level.t` is an OCaml `int` at lib/level.ml:2, so `univ` holds
a `Nat`.

Shapes, addresses, legs and motives carry terms in one mutual family.
Legs retain their binder lists, and motives bind their indices followed
by their self variable, as in lib/term.ml.
-/

namespace KanonMeta

/-- The usage marks of the 0/1/omega fragment, from lib/quantity.ml:10-13. -/
inductive Quantity where
  | zero
  | one
  | many

mutual

/-- A point address retains its argument separately from the fibre or
function head.  Constructor addresses retain their declaration names. -/
inductive Addr where
  | apt (q : Quantity) (arg : Term)
  | aleg (k : Nat)
  | actor (name : String)

/-- A section leg or elimination branch with its explicit binders. -/
inductive Leg where
  | mk (binders : List (Quantity × String)) (body : Term)

/-- The motive body binds the indices and then the self variable. -/
inductive Motive where
  | mk (ind : Option String) (idx : List String) (self : String) (body : Term)

/-- The M0 shapes and the M1 inductive shape from lib/shape.ml. -/
inductive Shape where
  | SPi (q : Quantity) (name : String) (dom : Term)
  | SColl (n : Nat)
  | SMu (name : String) (indices : List Term)

/-- The raw kernel term with its admitted shape and address payloads. -/
inductive Term where
  | var (i : Nat)
  | univ (l : Nat)
  | lan (s : Shape) (body : Term)
  | ran (s : Shape) (body : Term)
  | intro (s : Shape) (a : Addr) (args : List Term)
  | elim (s : Shape) (scrut : Term) (q : Quantity)
      (motive : Option Motive) (branches : List (Addr × Leg))
  | sec (s : Shape) (legs : List Leg)
  | out (s : Shape) (a : Addr) (tm : Term)
  | letIn (name : String) (ty : Term) (val : Term) (body : Term)
  | ann (tm : Term) (ty : Term)
  | global (name : String)
  | lit (n : Nat)

end

end KanonMeta
