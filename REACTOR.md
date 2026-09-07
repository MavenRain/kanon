# Reusable WebAssembly modules

`kanon build` checks, erases, and compiles an ordered set of Kanon source
files to one WebAssembly module. Each `--export` names an ordinary Kanon
definition. Source files share one declaration environment, and later
files may use earlier definitions. The compiler inserts a newline between
files; reported line numbers refer to their concatenation.

```sh
kanon build types.kan app.kan -o app.wasm \
  --export initialState --export updateState --export stateCount
```

`-o` must occur once, and at least one source and one export are required.
Repeated export names are rejected. A function can take zero or more
runtime arguments and return a natural or an aggregate. Exported values
are called with zero arguments. For a constructor, provide an ordinary
definition, for example:

```kanon
mu Bytes : Type 0 with
| bytesNil : Bytes
| bytesCons : Nat -> Bytes -> Bytes

def emptyBytes : Bytes := bytesNil
def consBytes : Nat -> Bytes -> Bytes :=
  fun (n : Nat) (tail : Bytes) => bytesCons n tail
```

The existing `emit` and `run` commands retain their original ABI and
output. `build` does not use an application-specific compiler adapter,
rewrite source outside the parser, add trusted kernel forms, or import
operating-system capabilities. The host performs I/O and calls ordinary
exported Kanon functions.

## Host values

The supported Nat boundary is an `i32` in `0..1073741823`. The exported
wrapper checks the incoming unsigned value before creating an i31. It
checks results after extracting the i31. Negative and larger i32 inputs
trap; a computed large Nat also traps at this boundary. Kanon arithmetic
inside the module continues to support arbitrary precision.

JavaScript's raw WebAssembly API coerces arguments to i32 before entering
the wrapper. A JavaScript host must first check `Number.isInteger(value)`
and `0 <= value && value <= 1073741823` if it needs to reject fractions,
NaN, strings, or integers that wrap modulo 2^32. The compiler cannot inspect
the original JavaScript value after this engine conversion.

Aggregates cross as opaque, immutable WasmGC struct references. The host
must preserve and pass these references without reading their payloads.
Even an empty sum has an opaque handle. Separate erased representations
receive distinct wrapper struct shapes. The WebAssembly function
signature and an explicit cast reject null, arbitrary JavaScript objects,
numbers, and handles of another representation before the typed payload
is read. A result is stored in its typed envelope. These are runtime
representation distinctions, not a nominal type or per-instance identity
guarantee across independently compiled modules. Host function and thunk
values are not supported.

```js
const { instance } = await WebAssembly.instantiate(wasmBytes);
const e = instance.exports;
const bytes = e.consBytes(65, e.emptyBytes());
```

## Byte literals

`b"text"` expands in the standard parser to ordinary calls of
`bytesCons BYTE TAIL`, ending in `bytesNil`. The program supplies those
names, so literals have the same checked semantics as handwritten
constructor applications. Source UTF-8 is preserved byte for byte.
Supported escapes are `\n`, `\r`, `\t`, `\0`, `\\`, `\"`, and exactly two
hexadecimal digits after `\x`. Literal source newlines, unknown escapes,
invalid hexadecimal escapes, and missing closing quotes are parse errors.
There is no new kernel type or primitive.

## Generic OS runtime

`runtime/reactor.mjs` exports `runReactor(wasmPath, argv)` for Node with
WebAssembly GC support. It drives a pure Kanon state machine using these
ordinary exports:

```text
emptyBytes, consBytes, bytesEmpty, bytesHead, bytesTail
emptyWords, consWords, wordsEmpty, wordsHead, wordsTail
init, resume, requestCode, requestArgs, requestBody, exitCode
```

`init` receives argv as a list of byte strings and returns opaque state.
Request accessors return an operation number, a list of byte strings, and
payload bytes. `resume(state, status, answer)` receives status 0 on success
or 1 with an error string and returns the next state. Operation 0 ends the
loop with `exitCode(state)`. The runtime never interprets application state.
Empty-list predicates return 1 for empty and 0 otherwise.

| Operation | Arguments | Result |
| --- | --- | --- |
| 1 | root, prefix | Create a private temporary directory; return its absolute path |
| 2 | path, offset, length | Read at most 65536 raw bytes |
| 3 | path; payload is content | Atomically replace a private file |
| 4 | stdout path, stderr path, cwd, timeout ms, executable, argv... | Execute directly with captured streams and wait |
| 5 | path | Return regular-file size in decimal |
| 6 | payload is content | Write stdout |
| 7 | payload is content | Write stderr |
| 8 | path | Resolve an existing path through realpath |
| 9 | base, path | Resolve a path relative to a base |

OS numeric arguments use decimal byte strings and must fit a JavaScript safe
integer. Timeouts additionally fit `0..2147483647`. A timeout of 0 sets no
deadline. OS string arguments must be valid UTF-8: a byte string that a UTF-8
round trip would change is rejected, never silently substituted. A rejected
argument ends the run with an error, not a resume. Operation 4
returns five NUL-separated fields: exit code, signal number, timeout flag,
interruption flag, and spawn error text. Flags use 0 or 1. Timeout exits use 124
and spawn failures use 127. The deadline governs the leading command only, so a
leader that exits first reports its own status. Commands inherit the environment
with closed stdin. On POSIX the runtime tracks a process group, escalates
termination after 250 ms, and waits at most 250 ms for the remaining group
members after the leader exits. It then kills the group, so no deadline leaves
the call waiting without end. Descendants that create another session are
outside that group. Process and filesystem failures are returned to the Kanon
state machine.

A SIGINT or SIGTERM during the run is latched. Operation 4 stops the command it
is running and sets the interruption flag of its response. That one report earns
the program a single further request, so it can write a summary or release what
it holds. The loop then stops and returns 128 plus the signal number. A signal
latched during any other operation stops the loop before the next request, with
the same status. The module also exports `spawns`, a counter of started processes
that the suite reads to observe that no command began.

The driver performs OS operations and byte marshalling only. Applications own
their argument parsing, paths, serialization, selection, and resource policies.
This is a host adapter, not an effect primitive or kernel extension.

## Validation

From the compiler repository root:

```sh
zsh dev/dune.sh build bin/kanon.exe test/main.exe test/wasm.exe test/sl_surface.exe
node dev/reactor-test.mjs
node --test dev/runtime-test.mjs
_build/default/test/main.exe
_build/default/test/wasm.exe
_build/default/test/sl_surface.exe
```

The gate battery runs both suites as its REACTOR and RUNTIME legs, after
AGREEMENT, so a break in the compiler surface or in the host runtime turns
the battery red.

The installed `dunecho` only accepts one mode argument, so
`dev/dunecho.sh build bin/kanon.exe` cannot express a scoped build. The
existing `dev/dune.sh` runner uses the same OCaml switch. `dunecho test`
builds the test executables, but the existing fixture suites need the
repository root as their working directory instead of Dune's sandbox.
The focused reactor suite builds its fixtures through the normal CLI,
checks the ABI in Node, rejects invalid arguments and literals, and
compares a legacy emitted module byte for byte with its checked-in
artifact. Its multi-file and negative fixtures live in
`test/fixtures/reactor/`, outside the legacy suite's flat golden set.
