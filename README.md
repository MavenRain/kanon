# kanon

Kan extensions are the sole type former: every type in kanon is a left or
a right Kan extension of a diagram along a shape.

Status: M0 Stage D.  The skeleton, the closed term grammar, the carried
kernel leaves, the R0 counts, the lexer, the parser, the surface printer,
the evaluator, conversion, the checker, the elaborator, erasure, the
totality entry point and WasmGC emission are built.  The `kanon run`
command arrives at Stage E.

## Checking a file

`kanon check FILE` parses the file, elaborates every declaration to the
kernel grammar and checks it against the declarations before it.  It
prints nothing and exits 0 when the whole file checks, and prints one
line on stderr and exits 1 when it does not, so a caller reads stdout as
the answer alone.  `kanon check --print FILE` adds the checked form of
every entry to stdout, one `def NAME : TYPE := BODY` or `axiom NAME :
TYPE` line per declaration, in kernel terms and in declaration order;
the golden files under test/golden hold exactly that text.  `kanon
axioms FILE` prints what the file postulates, one name per line in
declaration order, and prints nothing for a file that postulates
nothing, so the trust base of a checked file is one command away.  A
missing file, an unknown command and the command that a later stage
brings, `run`, all exit 64, which a caller tells from the exit 1 of a
file that does not check.

## Erasing a file

`kanon check --erased FILE` checks the file first and then prints the
erased program to stdout, in declaration order.  Erasure drops every
type, every proposition, every proof and every binder the checker
stamped `0`, so the printed program holds the runtime content alone.  A
declaration with no runtime content prints as `erased NAME`.  A
postulate with a runtime type prints as `axiom NAME : REPR`, which the
host must supply.  A definition prints as one `rec [TID; ..]` line, the
types it names, and then one `fun` line for each function it lifts and
one for its own function.  The golden files test/golden/NAME.erased
hold exactly that text, one beside every test/golden/NAME.checked, and
the ERASE group of the suite compares the two byte for byte.

## Emitting a module

`kanon emit FILE -o OUT.wasm --export NAME` checks the file, erases it
and writes one WasmGC module to OUT.wasm.  The argument order is fixed.
The named definition must be a `Nat` of arity zero:  the module exports
one function with no parameter and an i32 answer, which calls that
definition and reads the answer out of its i31.  The command prints
nothing and exits 0 on success.  A file that does not check exits 1, as
`kanon check` does.  A form the emitter refuses prints one
`kanon: emit: MESSAGE` line on stderr and exits 2;  the refusals are a
postulate with no body, a literal outside the range 0 to 1073741823, an
export that is not a `Nat` of arity zero, and the delayed forms that
arrive at M2.  A usage error and a directory that does not exist exit
64.

`node dev/run-node.mjs OUT.wasm NAME` runs the module with no import and
prints the answer in decimal.  It exits 0 with the answer, 1 with a
`trap: MESSAGE` line when the module traps, 2 with an `invalid: MESSAGE`
line when the engine refuses the module, and 64 on a usage error.  A
natural rides in an i31, so an answer above 1073741823 is a trap and not
a wrapped number.

```
_build/default/bin/kanon.exe emit test/fixtures/d01-lit-prims.kan \
  -o /tmp/d01.wasm --export main
node dev/run-node.mjs /tmp/d01.wasm main        # prints 17
_build/default/test/wasm.exe test               # the emission suite
zsh dev/encoder-subset.sh                       # the opcodes of SPEC.md
```

The emission suite reads every fixture that checks and defines `main`.
For each one it emits the module, assembles it with wasm-opt, compares
the text form with test/golden/NAME.wat byte for byte, takes the value
of `main` from the kernel alone and compares the answer of the node
runner with it.  It prints one `EMIT NAME OK` line per fixture, then
`WASM-OK P/T`, then `SUITE-WASM OK` or `SUITE-WASM FAIL`.  The modules
and their text forms land in `_build/wasm-suite`, or in the directory of
the second argument.

## The closure ABI

A function with a known name and a known arity is called through its own
typed signature, where each parameter and the answer keeps the runtime
type of its erased repr.  Every other head is a closure.  A closure is
one struct of three immutable fields:  the arity as an i32, the code as
a function reference, and the environment as an eq reference, which
holds a struct of the captures or a tagged zero when there is no
capture.  The code of a closure has the generic signature `fn<n>`, where
the environment, every argument and the answer are eq references, so one
wrapper joins the two conventions:  it reads the captures out of the
environment, casts each capture and argument to its typed form, and tail calls the
typed code.  A call whose arity the caller does not know goes through
the helper `apply<k>`, which reads the arity out of the closure:  an
equal arity is a tail call of the code, a smaller arity calls the code
and applies the arguments that are left to the answer, and a larger
arity builds a partial application that holds the closure and the
arguments so far.

Pairs, tuples and closure environments store their runtime fields as eq
references, and sum payloads use eq references too.  Field reads cast to
the checked type.  This keeps aggregate layouts compatible when an erased
type parameter is instantiated.  Cases retain their checked sum type,
so a sum returned through a generic call still has its branch information.

## Layout

```
dune-project        (lang dune 3.24) (name kanon)
PIN                 the vendored tot sha
SPEC.md             the closed grammar, the R0 counts, the sugar table
vendor/tot/         git submodule, checked out at PIN
lib/                library kanon_kernel
surface/            library kanon_surface
wasm/               library kanon_wasm: gc_encode.ml, link.ml, emit.ml
bin/kanon.ml        driver: check | emit | run | axioms | spec-count
test/               main.ml, wasm.ml, sys_io.ml, fixtures/*.kan,
                    golden/*.checked, golden/*.erased, golden/*.wat,
                    neg/*.kan
dev/                the runners, the gate scripts and the logs
```

## Build and test

The OCaml toolchain is in the zxcaml-p1 opam switch, which is not on the
default PATH.  Two runner scripts add it and set the root, so you can call
them from any directory:

```
zsh dev/dunecho.sh build          # build, warnings are errors
zsh dev/dune.sh clean             # remove _build
zsh dev/carry-check.sh            # the carried files match the pin
zsh dev/r0-count.sh               # spec-count agrees with SPEC.md
zsh dev/encoder-subset.sh         # the goldens hold no opcode past SPEC.md
zsh dev/house.sh                  # the house rules over lib, bin, test, wasm
_build/default/test/main.exe test               # the kernel suite
_build/default/test/wasm.exe test               # the emission suite
```

Each script finds the repository root from its own path, so a copy of the
tree builds and checks itself.

## Carried code

lib/level.ml, lib/level.mli, lib/quantity.ml, lib/literal.ml,
lib/global.ml, lib/budget.ml and lib/budget.mli come from tot at the sha
in PIN.  Each starts with a comment line that names its origin and its
delta.  dev/CARRIED.md holds the diff line count for each one, and
dev/carry-check.sh recomputes them.

## License

MIT OR Apache-2.0.  See LICENSE-MIT and LICENSE-APACHE.
