# kanon

Kan extensions are the sole type former: every type in kanon is a left or
a right Kan extension of a diagram along a shape.

Status: M0 Stage A.  The skeleton, the closed term grammar, the carried
kernel leaves, the R0 counts, the lexer, the parser and the surface
printer are built.  The checker, the evaluator, erasure and WasmGC
emission arrive at Stages B to E.

## Layout

```
dune-project        (lang dune 3.24) (name kanon)
PIN                 the vendored tot sha
SPEC.md             the closed grammar, the R0 counts, the sugar table
vendor/tot/         git submodule, checked out at PIN
lib/                library kanon_kernel
surface/            library kanon_surface
bin/kanon.ml        driver: check | emit | run | axioms | spec-count
test/               main.ml and fixtures/*.kan
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
_build/default/test/main.exe test/fixtures    # the parser round trip
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
