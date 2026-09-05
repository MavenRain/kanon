# kanon

Kan extensions are the sole type former: every type in kanon is a left or
a right Kan extension of a diagram along a shape.

Status: M0 Stage C.  The skeleton, the closed term grammar, the carried
kernel leaves, the R0 counts, the lexer, the parser, the surface printer,
the evaluator, conversion, the checker, the elaborator, erasure and the
totality entry point are built.  WasmGC emission arrives at Stages D
and E.

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
missing file, an unknown command and the two commands that later stages
bring, `emit` and `run`, all exit 64, which a caller tells from the exit
1 of a file that does not check.

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

## Layout

```
dune-project        (lang dune 3.24) (name kanon)
PIN                 the vendored tot sha
SPEC.md             the closed grammar, the R0 counts, the sugar table
vendor/tot/         git submodule, checked out at PIN
lib/                library kanon_kernel
surface/            library kanon_surface
bin/kanon.ml        driver: check | emit | run | axioms | spec-count
test/               main.ml, fixtures/*.kan, golden/*.checked,
                    golden/*.erased, neg/*.kan
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
_build/default/test/main.exe test               # the kernel suite
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
