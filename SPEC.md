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
| `Univ of Level.t` | M0 | admitted |
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

## 6 The framework axiom

Level rules are functions per shape (R-Q6).  `ran_lvl` at SPi is
`imax l l'`.  The equation

    imax l zero = zero

is a framework axiom of kanon.  It gives Prop its impredicativity.  M0
uses closed levels only.  Level variables arrive at M2.

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
| `p.1` and `p.2` | `Elim` at `Lan (SPi ..)` with the projection motive | sugar, not former |
| `inj k of n t` | `In (SColl n) (ALeg k) [t]` | sugar, not former |
| `case t as x return M with \| k xs => b` | `Elim` at `Lan (SColl n)` | sugar, not former |
| `tuple (t1, .., tn)` | `Sec (SColl n) [.. => t1; ..]` | sugar, not former |
| `t.k` | `Out (SColl n) (ALeg k) t` | sugar, not former |
| `()` | `Sec (SColl 0) []` | sugar, not former |
| `absurd t` | `Elim` at `Lan (SColl 0)` with no branches | sugar, not former |
| `Prop` | `Univ zero` | sugar, not former |
| `Type n` | `Univ n` | sugar, not former |
| `let x : A := d in b` | `Let (x, A, d, b)` | sugar, not former |
| `(t : A)` | `Ann (t, A)` | sugar, not former |
| `auto` | `Auto` | sugar, not former.  SA-D3 |
| `mu` | none.  Reserved;  the parser refuses it with "mu arrives at M1" | SA-D3 |
| `nu` | none.  Reserved;  the parser refuses it with "nu arrives at M2" | SA-D3 |

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

`mu` and `nu` are reserved words.  The parser accepts neither and returns
the milestone name, so a program that names a shape past M0 fails at the
first pass over the text and never reaches the checker.
