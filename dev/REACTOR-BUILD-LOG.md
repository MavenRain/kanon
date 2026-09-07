# Reactor application increment (2026-09-07)

This increment starts at e0a691a6909e38be414b248a2db541ca58989567, whose
compiler exports ordinary Kanon definitions and whose Node runtime drives
an OS request protocol.  The earlier runtime tests supplied JavaScript
mock exports; the compiler tests called Wasm exports directly.  Neither
test exercised a compiled Kanon state machine through the full runtime.

## Application and command

`runtime/reactor.kan` supplies the Bytes and Words families, ten ABI
constructors/accessors and `bytesAppend`.  `examples/reactor-realpath.kan`
uses those definitions to accept exactly one path, request operation 8,
consume the returned answer through `resume`, and write it with a newline
using operation 6 or 7.  It exits 0 on success, 1 on filesystem or output
failure, and 64 for a wrong argument count.  An output failure preserves
an already nonzero application result.

`node runtime/run.mjs MODULE.wasm [ARG ...]` loads an application, forwards
its arguments unchanged, and returns its runtime status.  Missing module
arguments use exit 64; loading or runtime exceptions use exit 2 and one
stderr diagnostic.  A sole `--help` prints usage with exit 0.  No compiler,
kernel, parser, trusted budget, gate bound or dependency revision changes.

## Interruption correction

After an interrupted operation 4, the runtime allows one shutdown request.
If that request was operation 0, the old branch returned the application's
exit code and could report success after SIGINT or SIGTERM.  A latched
signal now takes precedence in that branch, returning 130 or 143.

Two regression controls failed on the original runtime with actual 0
instead of 130 or 143.  Both pass after the fix.  Ordinary terminal exits
0 and 7 and the existing final shutdown write still pass.  The new tests
deliver interruption while capture opening yields, check the operation 4
interruption response, and verify that no child was started.

## Validation

Validation used the isolated source snapshot at
/Users/oobi/Documents/gpt4/kanon-reactor-followup/work and its copied
23 MiB compiler cache.  The existing compiler checked the shared Kanon
source and built the application through the normal multiple-file CLI.
The example module is 5,131 bytes and exports the sixteen required names.

| Check | Result |
| --- | --- |
| REACTOR command under the existing 30-second MED watchdog | 70 checks passed, exit 0, 0.880 seconds. |
| RUNTIME command under the existing 30-second MED watchdog | 20 tests passed, no failures or skips, exit 0, 4.289 seconds.  Fix round 1 added the argument-order test and measured this run. |
| Real CLI and OS integration | UTF-8 and flag-shaped path arguments, canonical-path output, missing-path errors, usage errors and runner diagnostics passed. |
| Compiled state transitions | Raw answer bytes including NUL and 255 survive `resume` and output preparation; output failure produces terminal status 1. |
| Existing reactor compiler coverage | Host ABI and literal refusals passed; the legacy emitted module still matches its tracked bytes. |
| HOUSE | Passed. |
| TRUSTED-LINES | Kernel 3997/4000, encoder 246/600, passed. |
| Documentation checks | Exact export list and all 21 gate names agree with source; M1 ratification remains open. |
| Independent source review | No further correctness or test-isolation defects found. |

These are the existing REACTOR and RUNTIME gate commands with their
unchanged watchdog and success oracles.  The full compiler, Lean,
arithmetic-agreement and performance batteries were not repeated for this
runtime/application increment.  No M1 exit ratification is claimed.

Evidence root: /Users/oobi/Documents/gpt4/kanon-reactor-followup/evidence.
`gate-checks.json`, `reactor-gate.log` and `runtime-gate.log` record the gate
commands and results.  `runtime/terminal-before.tap` records the failing
controls, with passing focused and full results beside it.  `example/`
holds the built application and direct/runtime observations.  `house.log`
and `trusted-lines.log` record the static checks.
