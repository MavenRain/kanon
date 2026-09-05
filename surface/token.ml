(** Lexical tokens.  Every token carries the position of its first
    character;  [Eof] carries the position just past the source.

    Mirrors kan-lang-tot-pin/surface/token.ml:1-53 for the token record
    and kan-lang-tot-pin/surface/loc.ml:1-17 for the position type,
    which rides in this file because the M0 surface has no loc.ml of its
    own.  SA-D2 keeps every position out of the surface tree, so a
    position lives in the token list and in the error the parser
    returns, nowhere else. *)

type loc = {
  line : int;
  col : int;
}

let start : loc = { line = 1; col = 1 }
let next_col (l : loc) : loc = { l with col = l.col + 1 }

(** [n] columns forward, for the lexer's two-character and
    three-character tokens.  Mirrors
    kan-lang-tot-pin/surface/loc.ml:11-14. *)
let advance (l : loc) (n : int) : loc = { l with col = l.col + n }

let next_line (l : loc) : loc = { line = l.line + 1; col = 1 }

(** The token kinds of the M0 surface grammar, SPEC.md section 9.
    [Unit] is the two-character form "()", one token because the
    grammar reads it as one form.  [Dot1] and [Dot2] are the pair
    projections and [Dot] with a following [Nat] is the collection
    projection (SA-D16).  [KSum] and [KProd] are the two collection type
    words that Stage B adds (SB-D1).  [KMu] and [KNu] are reserved: the parser
    refuses both with their milestone name (SA-D3). *)
type kind =
  | LParen
  | RParen
  | Colon
  | ColonEq
  | Arrow
  | DArrow
  | Star
  | Comma
  | Dot
  | Dot1
  | Dot2
  | Pipe
  | Unit
  | KDef
  | KAxiom
  | KFun
  | KInj
  | KOf
  | KCase
  | KAs
  | KReturn
  | KWith
  | KTuple
  | KSum
  | KProd
  | KAbsurd
  | KProp
  | KType
  | KLet
  | KIn
  | KAuto
  | KMu
  | KNu
  | KNatAdd
  | KNatSub
  | KNatMul
  | KNatEq
  | KNatLt
  | Ident of string
  | Nat of int
  | Eof

type t = {
  kind : kind;
  loc : loc;
}

(* mirrors kan-lang-tot-pin/surface/token.ml:55-94 *)
let describe (k : kind) : string =
  match k with
  | LParen -> "'('"
  | RParen -> "')'"
  | Colon -> "':'"
  | ColonEq -> "':='"
  | Arrow -> "'->'"
  | DArrow -> "'=>'"
  | Star -> "'*'"
  | Comma -> "','"
  | Dot -> "'.'"
  | Dot1 -> "'.1'"
  | Dot2 -> "'.2'"
  | Pipe -> "'|'"
  | Unit -> "'()'"
  | KDef -> "'def'"
  | KAxiom -> "'axiom'"
  | KFun -> "'fun'"
  | KInj -> "'inj'"
  | KOf -> "'of'"
  | KCase -> "'case'"
  | KAs -> "'as'"
  | KReturn -> "'return'"
  | KWith -> "'with'"
  | KTuple -> "'tuple'"
  | KSum -> "'sum'"
  | KProd -> "'prod'"
  | KAbsurd -> "'absurd'"
  | KProp -> "'Prop'"
  | KType -> "'Type'"
  | KLet -> "'let'"
  | KIn -> "'in'"
  | KAuto -> "'auto'"
  | KMu -> "'mu'"
  | KNu -> "'nu'"
  | KNatAdd -> "'natAdd'"
  | KNatSub -> "'natSub'"
  | KNatMul -> "'natMul'"
  | KNatEq -> "'natEq'"
  | KNatLt -> "'natLt'"
  | Ident s -> Printf.sprintf "identifier %s" s
  | Nat n -> Printf.sprintf "number %d" n
  | Eof -> "end of input"
