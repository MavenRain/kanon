#!/bin/zsh
set -eu
prep=${0:A:h}
work=${1:-"$prep/.."}
switch_lib=$(opam var --switch zxcaml-p1 lib 2>/dev/null || true)
[[ -d $switch_lib ]] || switch_lib=/Users/oobi/.opam/zxcaml-p1/lib
export PATH=${switch_lib:h}/bin:$PATH
# Zarith's bytecode stub lives in the same switch as the toplevel.
export CAML_LD_LIBRARY_PATH=$switch_lib/stublibs${CAML_LD_LIBRARY_PATH:+:$CAML_LD_LIBRARY_PATH}
exec ocaml \
  -I "$switch_lib/zarith" zarith.cma \
  -I "$work/_build/default/lib" \
  -I "$work/_build/default/lib/.kanon_kernel.objs/byte" kanon_kernel.cma \
  -I "$work/_build/default/surface" \
  -I "$work/_build/default/surface/.kanon_surface.objs/byte" kanon_surface.cma \
  "$prep/agreement-roundtrip.ml"
