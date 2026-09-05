# kanon M0 specification

Date: 2026-09-05.  Status: M0 Stage A.  This file pins the closed grammar
and the R0 counts.  The gate legs R0-COUNT and R0-AUDIT read it.

## 1 The claim

kanon has two type formers, Lan and Ran.  Every type comes from one of the
two, applied to a shape and a diagram.  There are four schema
constructors: In and Elim for Lan, Sec and Out for Ran.  There is one
dispatch point, lib/rules.ml, which maps a shape to its rule pack.  No
other module in the kernel reads a shape name.

Every surface form in section 8 is sugar for one kernel constructor.  No
surface form is a former.

## 2 The closed grammar

The shape sum, the term sum and the erased form are declared whole at
Stage A (D-M0-2).  A constructor past M0 is refused by the module named
in its row, with its milestone name in the message.  A later milestone is
then a loud edit to an exhaustive match, not a new constructor.

### 2.1 Shapes, lib/shape.ml

| constructor | milestone | refused by |
| --- | --- | --- |
| `SPi of Quantity.t * string * 'a` | M0 | admitted |
| `SColl of int` | M0 | admitted |
| `SPar of 'a * 'a` | M1 | rules.ml |
| `SMu of string * 'a list` | M1 | rules.ml |
| `SNu of string * 'a list` | M2 | rules.ml |

The type parameter is the kernel term.  lib/term.ml therefore spells no
shape name (SA-D5).

### 2.2 Terms, lib/term.ml

Thirteen constructors.  Two of them form types.

| constructor | milestone | refused by |
| --- | --- | --- |
| `Var of int` | M0 | admitted |
| `Univ of Level.t`.  Prop is `Univ zero` and `Type n` is `Univ (n + 1)` (SB-D2) | M0 | admitted |
| `Lan of t Shape.t * t` | M0 | rules.ml, per shape |
| `Ran of t Shape.t * t` | M0 | rules.ml, per shape |
| `In of t Shape.t * addr * t list` | M0 | rules.ml, per shape |
| `Elim of elim` | M0 | rules.ml, per shape |
| `Sec of t Shape.t * leg list` | M0 | rules.ml, per shape |
| `Out of t Shape.t * addr * t` | M0 | rules.ml, per shape |
| `Let of string * t * t * t` | M0 | admitted |
| `Ann of t * t` | M0 | admitted |
| `Global of string` | M0 | admitted |
| `Lit of Literal.t` | M0 | admitted |
| `Auto` | M2 | check.ml, "instances arrive at M2" |

Addresses.  `APt` is the point address and carries the argument.  `ALeg`
is the leg address.  `ACtor` is the constructor address of the two
recursive shapes, so it arrives at M1 and M2.

### 2.3 The erased form, lib/eterm.ml

| constructor | milestone | refused by |
| --- | --- | --- |
| `KVar KLit KGlobal KErased KLet` | M0 | admitted |
| `KClos KApp KTail` | M0 | admitted |
| `KStruct KProj KTag KCase` | M0 | admitted |
| `KDelay KForce` | M2 | emit.ml |
| `RI31 RStruct RUnion RFunc` | M0 | admitted |
| `RThunk` | M2 | emit.ml |
| `KFun KRec` | M0 | admitted |

`tid` and `fid` are symbolic names and never integers.  lib/link.ml
resolves them to indices in one pass, so the emitter never computes an
index.

## R0 counts

`kanon spec-count` prints this block.  dev/r0-count.sh diffs the two.  A
count that grows fails the R0-COUNT gate leg.

```
formers 2: Lan Ran
schema constructors 4: In Elim Sec Out
shapes declared 5: SPi SColl SPar SMu SNu
shapes admitted 2: SPi SColl
named rules declared 3: proof-irrelevance subsingleton-large-elimination literal-fast-path
named rules present 2: proof-irrelevance literal-fast-path
eta rows 3: Ran-SPi Lan-SPi Ran-SColl
no eta 1: Lan-SColl
```

Every number in the block is the length of the list printed after it.
lib/spec_count.ml reads the shape lists from Shape and the former and
schema lists from Term.

## 4 The eta table

The criterion is one test, from plan section 5: a shape gets an eta row
when it has a unique introduction address and its structural expansion
ends.  The table below is derived from that test, not declared.

| row | former and shape | expansion | present |
| --- | --- | --- | --- |
| Ran-SPi | Ran at SPi | `f` to `Sec [x => Out (APt x) f]` | yes |
| Lan-SPi | Lan at SPi | `p` to `In (APt p.1) [p.2]` | yes |
| Ran-SColl | Ran at SColl n | `t` to `Sec [Out (ALeg 0) t, .., Out (ALeg n-1) t]` | yes |
| Lan-SColl | Lan at SColl n | none | no |

Lan at SColl n has n introduction addresses, one per leg, so the
criterion fails and the row is absent.  Ran at SColl 0 holds, and it
gives Unit its eta.  conv.ml applies each row by expansion.

### 4.1 The rule pack, lib/rules.ml

`rules : 'a Shape.t -> (rule_pack, Error.t) result` is the one dispatch
point.  It gives a pack to the two admitted shapes.  It gives
`Error (Not_yet ..)` with the milestone word to the other three.  The
pack has these fields, as built.

| field | what it decides |
| --- | --- |
| `form_lan` | the level of `Lan s d`.  It reads the diagram and `expected : Level.t option` (SB-D6) |
| `form_ran` | the same for `Ran s d` |
| `intro_in` | checks `In` against an expected `Lan` |
| `elim_elim` | checks or infers `Elim`.  `expected : Value.t option` is the constant cocone of a motive free elimination |
| `intro_sec` | checks `Sec` against an expected `Ran` |
| `elim_out` | infers `Out` |
| `beta` | one reduction step at the shape.  The evaluator calls it |
| `eta` | the row of the eta table above, one flag per former |
| `diagram_arity` | how many binders the diagram opens.  Readback asks it, so no reader outside the pack knows (SB-D25) |
| `spine_ty` | one typed step along a neutral spine:  the type of the address argument and the type of the head after the step (SB-D25) |
| `expand_ran` | the eta expansion at the right former.  The SB-M1 site is on this field of the point pack |
| `expand_lan` | the eta expansion at the left former |
| `conv_diagram` | compares two diagrams at the shape |
| `ann_lvl_eq` | compares the carried universe of SB-D7.  Only the width zero collection reads it |
| `lan_lvl` | the level function of the left former |
| `ran_lvl` | the level function of the right former |

A rule reads the checker through an `ops` record, so rules.ml does not
depend on check.ml and no ref cell exists in lib/ (SB-D12).

## 5 The named rules ledger

These are the conversion rules that are not schema rules.  Three are
declared;  two are present at M0.

| rule | status | where |
| --- | --- | --- |
| proof-irrelevance | present at M0 | conv.ml, step one: two terms at a type in `Univ zero` are equal |
| subsingleton-large-elimination | M1 | arrives with the Prop-valued recursive shape.  The three-part criterion is tot's, at kan-lang-tot-pin/lib/check.ml:219 and :223 |
| literal-fast-path | present at M0 | conv.ml, step three: `Lit` compares by value and the five prims reduce on literal arguments |

M1 obligation, recorded here: the literal fast path needs an agreement
lemma against the unary recursive Nat.

Quantities are modes at M0.  The mark `One` is read by the surface and is
counted as `Many` by the checker (SB-D3).  The linear counter arrives at
M1.

## 6 The framework axiom

Level rules are functions per shape (R-Q6).  `ran_lvl` at SPi is
`imax l l'`.  The equation

    imax l zero = zero

is a framework axiom of kanon.  It gives Prop its impredicativity.  M0
uses closed levels only.  Level variables arrive at M2.

As built, in lib/rules.ml under the comment `(* SB-M3 site *)`:

    let imax l l' = if Level.equal l' Level.zero then Level.zero
                    else Level.max l l'

`lan_lvl` at SPi is `Level.max`.  Both level functions at SColl n are the
maximum of the leg levels.  At n = 0 there is no leg, so the level comes
from the annotation and defaults to `Univ zero` (D-M0-6).

## 7 The sugar table

Every surface form maps to one kernel constructor.  Read the right-hand
column to confirm that no surface form is a former.

| surface form | kernel form | note |
| --- | --- | --- |
| `fun (q x : A) => b` | `Sec (SPi (q, x, A)) [x => b]` | sugar, not former |
| `(q x : A) -> B` | `Ran (SPi (q, x, A)) B` | sugar, not former |
| `A -> B` | `Ran (SPi (Many, "_", A)) B` | sugar, not former |
| `(q x : A) * B` | `Lan (SPi (q, x, A)) B` | sugar, not former |
| `A * B` | `Lan (SPi (Many, "_", A)) B` | sugar, not former |
| `f a` | `Out (SPi ..) (APt (q, a)) f` | sugar, not former.  SA-D1 |
| `(a, b)` | `In (SPi ..) (APt (q, a)) [b]` | sugar, not former |
| `p.1` | `Elim` at `Lan (SPi ..)`, leg `ALeg 0`, first branch binder, with the projection motive | sugar, not former.  D-M0-3 |
| `p.2` | `Elim` at `Lan (SPi ..)`, leg `ALeg 0`, second branch binder, with the projection motive | sugar, not former.  D-M0-3 |
| `inj k of n t` | `In (SColl n) (ALeg k) [t]` | sugar, not former |
| `case t as x return M with \| k xs => b` | `Elim` at `Lan (SColl n)` | sugar, not former |
| `tuple (t1, .., tn)` | `Sec (SColl n) [.. => t1; ..]` | sugar, not former |
| `sum (A1, .., An)` | `Lan (SColl n) (Sec (SColl n) [.. => A1; ..])` | sugar, not former.  SB-D1 |
| `prod (A1, .., An)` | `Ran (SColl n) (Sec (SColl n) [.. => A1; ..])` | sugar, not former.  SB-D1 |
| `t.k` | `Out (SColl n) (ALeg k) t` | sugar, not former |
| `()` | `Sec (SColl 0) []` | sugar, not former |
| `absurd t` | `Elim` at `Lan (SColl 0)` with no branches | sugar, not former |
| `Prop` | `Univ zero` | sugar, not former |
| `Type n` | `Univ (n + 1)` | sugar, not former.  SB-D2 |
| `let x : A := d in b` | `Let (x, A, d, b)` | sugar, not former |
| `(t : A)` | `Ann (t, A)` | sugar, not former |
| `auto` | `Auto` | sugar, not former.  SA-D3 |
| `mu` | none.  Reserved;  the parser refuses it with "mu arrives at M1" | SA-D3 |
| `nu` | none.  Reserved;  the parser refuses it with "nu arrives at M2" | SA-D3 |

SB-D1.  `sum` and `prod` are the two collection type words.  Both are
sugar rows and neither is a former:  the items are the legs of one
diagram, the diagram is a section at the collection shape, and the word
picks the left former or the right former over it.  The width zero forms
`sum ()` and `prod ()` are the empty and the unit type;  each takes its
universe from an annotation and sits at `Univ zero` without one (D-M0-6).

SB-D3.  The binder mark `1` reads as `Quantity.One`.  M0 counts `One`
with `Many` in every rule, so the mark changes no judgement at this
milestone;  it is read, carried and printed back, so a Stage C rule can
separate the two without a change of text.

SA-D1.  Application by juxtaposition is a surface production and a sugar
row.  Plan sections 4 and 8 leave it out, and `natAdd` cannot be applied
without it.  It binds tighter than the arrow and the star, and looser
than the postfix `.1`, `.2` and `.k`.  It is left associative.

## 8 The encoder subset

wasm/gc_encode.ml encodes this subset and nothing else.  The gate leg
ENCODER-SUBSET fails when an opcode outside the table is emitted, so
growth is visible in a diff of this table.

| group | members |
| --- | --- |
| numbers | LEB128 unsigned, LEB128 signed |
| sections used | type, function, export, code |
| sections refused | table, memory, global, start, element, data |
| composite types | struct, array, func, in rec groups, final subtypes only |
| control | `block`, `loop`, `if`, `br`, `br_if`, `br_on_cast`, `return`, `unreachable` |
| calls | `call`, `return_call`, `call_ref`, `return_call_ref` |
| locals | `local.get`, `local.set`, `local.tee` |
| numeric | `i32.const`, and the i32 arithmetic and comparison ops that the five prims need |
| references | `ref.i31`, `i31.get_s`, `ref.cast`, `ref.null`, `ref.is_null` |
| structs | `struct.new`, `struct.get` |

M0 emits WasmGC core modules only (R-Q4).  There is no linear memory, no
tag, and no import beyond the gate's export.

## 9 The surface grammar

```
decl    ::= 'def' name ':' term ':=' term
          | 'axiom' name ':' term
term    ::= 'fun' binder+ '=>' term
          | binder '->' term  |  term '->' term
          | binder '*' term   |  term '*' term
          | term term                              (* SA-D1 *)
          | '(' term ',' term ')'  |  term '.1'  |  term '.2'
          | 'inj' nat 'of' nat term
          | 'case' term ['as' name 'return' term] 'with' ('|' nat binder* '=>' term)*
          | 'tuple' '(' (term (',' term)*)? ')'  |  term '.' nat
          | 'sum' '(' (term (',' term)*)? ')'       (* SB-D1 *)
          | 'prod' '(' (term (',' term)*)? ')'      (* SB-D1 *)
          | '()'  |  'absurd' term
          | 'Prop'  |  'Type' nat?  |  nat
          | 'natAdd' | 'natSub' | 'natMul' | 'natEq' | 'natLt'
          | 'let' name ':' term ':=' term 'in' term
          | 'auto'                                 (* SA-D3 *)
          | 'mu'  |  'nu'                          (* SA-D3, reserved *)
          | '(' term ':' term ')'  |  name  |  '(' term ')'
binder  ::= '(' ('0' | '1')? name ':' term ')'
```

Precedence, loosest first: the arrow and the star, then application, then
the postfix projections `.1`, `.2` and `.k`.  The arrow and the star are
right associative.  Application is left associative.

The binder mark is one of three:  `0` is `Quantity.Zero`, `1` is
`Quantity.One` and an absent mark is `Quantity.Many` (SB-D3).  The
printer writes `0 `, `1 ` and the empty text back, so a marked binder
round trips.

`sum`, `prod`, `mu` and `nu` are reserved words.  The parser accepts neither and returns
the milestone name for `mu` and `nu`, so a program that names a shape
past M0 fails at the first pass over the text and never reaches the
checker.  `sum` and `prod` have the two productions above, so neither
can be a definition name.

## 10 Obligations at M0

M0 leaves these four obligations.  Each one names the milestone that
closes it.

| obligation | milestone | note |
| --- | --- | --- |
| linear counting for `One` | M1 | the mark exists in quantity.ml and in the surface.  The M0 checker counts it as `Many` (SB-D3) |
| arbitrary precision Nat | M1 | M0 uses the host integer.  `natAdd` and `natMul` give `Error (Overflow ..)` at the boundary and `natSub` truncates at zero (SB-D4).  A bignum library is a dependency the user pins |
| the agreement lemma of the literal fast path | M1 | the fast path must agree with the unary recursive Nat of the M1 shape.  Section 5 records the same obligation |
| subsingleton large elimination | M1 | it arrives with the Prop valued recursive shape.  Section 5 records its criterion and its origin in tot |
