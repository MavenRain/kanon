# M0 build log

## Stage 0 (2026-09-05)

### Deliverables

- /Users/oobi/Documents/kanon: a new git repository, `git init -b main`, branch main, zero commits, only `dev/` created.  Nothing was committed at any point.
- /Users/oobi/Documents/kanon/dev/bench.sh: the millisecond timer, mode 755.  It takes NAME and CMD, runs CMD once untimed as a warm-up, then RUNS timed runs (RUNS from the environment, default 5).  Each timed run is `/bin/zsh -f -c CMD` under `/opt/homebrew/bin/python3 -P` with `time.perf_counter_ns()` around `subprocess.run`, stdin, stdout and stderr on /dev/null, so interpreter start-up stays outside the measurement.  Success prints one line, `BENCH NAME median_ms=... min_ms=... max_ms=... runs=N`, three decimals.  A non-zero child exit prints `BENCH-ERROR NAME exit=N` and exits 1.
- /Users/oobi/Documents/kanon/dev/pin-dune.sh: the dune runner, mode 755.  It puts /Users/oobi/.opam/zxcaml-p1/bin first on PATH, clears the user chpwd hooks, cds into /Users/oobi/Documents/kan-lang-tot-pin and execs dune with the given arguments.  Every dune call at Stage 0 went through it.
- /Users/oobi/Documents/kanon/dev/denominators.json: the frozen speed denominators, all fields of brief section 3.4.
- /Users/oobi/Documents/kanon/dev/DENOMINATORS.sha256: `shasum -a 256 denominators.json` written from inside dev/, so the entry is the bare file name.
- /Users/oobi/Documents/kanon/dev/M0-BUILD-LOG.md and /Users/oobi/Documents/kanon/dev/MUTATION-LOG.md: these two judge logs.
- Stage 0a was already done: wasmtime 48.0.1 at /opt/homebrew/bin/wasmtime.  Stage 0d was not in scope.  No kernel code was written.

### Gates

Every gate below was rerun by the judge on 2026-09-05 from one runner script; the evidence is the printed line of that rerun, not the builder's line.

| id | result | evidence |
| --- | --- | --- |
| S0-G1 | pass | `BENCH true median_ms=19.265 min_ms=14.510 max_ms=49.839 runs=5`, exit 0; one BENCH line, median under 20.  Three further reruns printed medians 13.218, 12.426 and 11.973 |
| S0-G2 | pass | `BENCH sleep50 median_ms=71.703 min_ms=69.652 max_ms=73.314 runs=5`, exit 0; median inside 40 to 150 |
| S0-G3 | pass | `BENCH-ERROR bad exit=1` with shell exit 1 |
| S0-G4 | pass | `OK fields-present missing=[]`; `OK medians-positive nonpositive=[]`; `OK date date=2026-09-05`; `OK tot_pin tot_pin=8cf0b8b`; `OK lines lines=4969`; `OK lines-recounted recounted=4969`; `OK files-list n=19 match=true`; `OK sha256 stored=34a46d4c5d338a8cdbfc31c21d98e4e90e128d099a20fac258408ba6a9d1ef86 recomputed=34a46d4c5d338a8cdbfc31c21d98e4e90e128d099a20fac258408ba6a9d1ef86`; `S0-G4 PASS`, exit 0 |
| S0-G5 | pass | `denominators.json: OK`, exit 0 |
| S0-G6 | pass | `pin-head=8cf0b8b`; `pin-porcelain-lines=0`; `-r-xr-xr-x@ 1 oobi staff 2778488 Sep 5 00:37 /Users/oobi/Documents/kan-lang-tot-pin/_build/default/test/main.exe` |
| S0-G7 | pass | `branch=main`; `commits=0`; `status --porcelain -uall` = `?? dev/DENOMINATORS.sha256`, `?? dev/M0-BUILD-LOG.md`, `?? dev/MUTATION-LOG.md`, `?? dev/bench.sh`, `?? dev/denominators.json`, `?? dev/pin-dune.sh`; `outside-dev-count=0` |

### Frozen numbers

- tot_corpus: 19 files (lib/*.ml plus lib/*.mli of the pin), 4969 lines, sha256 34a46d4c5d338a8cdbfc31c21d98e4e90e128d099a20fac258408ba6a9d1ef86.  The judge recomputed the file list, the line count and the hash from the pin; all three matched the stored values.
- tot_suite_kernel_warm_ms: median 103.662, min 97.081, max 112.818, runs 5.
- ocamlopt_ms_per_kloc: value 1641.599, median_ms 8157.104, min_ms 5949.238, max_ms 14355.273, runs 5, lines 4969.
- ocamlopt_ms_per_kloc_parallel: value 712.803, median_ms 3541.920, min_ms 2136.219, max_ms 6056.087, runs 5, lines 4969.  Informational.
- runner_overhead_ms: median 40.038, min 37.939, max 48.199, runs 5.  Informational.
- Host: arm64, 12 cpus, macOS 26.4, sysctl denied in sandbox.  ocamlopt 5.2.1, dune 3.24.2.
- denominators.json sha256: ded67f3a1fb58d6bb175a45242941ae903c6699a4c5ae5b245506afb275e752b.

### Findings and how each was resolved

1. Brief section 2 says lib/ holds 18 .ml files and 2 .mli files.  The pin holds 17 .ml files and 2 .mli files, 19 files together.  The line count in the brief is right: `wc -l` over the sorted list prints `4969 total`.  Resolved by listing the corpus as measured, 19 files, and keeping lines at 4969.  The judge recounted from the pin and printed `n=19` and `recounted=4969`.
2. The first bench build put S0-G1 at `median_ms=19.157` against a 20 ms bar, because `zsh -c` reads the user .zshenv on every child.  Resolved by timing `/bin/zsh -f -c CMD`, which reads no rc file.  S0-G1 then printed 12.415 ms.  This is a disclosed deviation from the literal `zsh -c CMD` of brief section 3.2; the one-string contract of CMD is unchanged, and every gate and both mutants were rerun against the shipped script.
3. S0-G1 sits close to its bar under load.  The judge's first rerun printed `median_ms=19.265` with `max_ms=49.839`, and three later reruns printed medians 13.218, 12.426 and 11.973; a RUNS=9 probe printed 15.905.  Every median stayed under 20, so the gate passes on the first honest attempt, but the margin is the thinnest of the seven gates and a loaded host can push one run high.  Recorded, not worked around.
4. The user .zshenv installs the chpwd hook `_telcoin_shared_target`, which reads $CARGO_TARGET_DIR unguarded.  Under `set -u` the hook aborts the shell, so the runner printed `_telcoin_shared_target:7: CARGO_TARGET_DIR: parameter not set` and exited 1 with no dune output, and the first runner_overhead bench printed `BENCH-ERROR runner_overhead exit=1`.  Resolved by clearing `chpwd_functions` and any `chpwd` function in pin-dune.sh before the cd.  The runner then printed `3.24.2`.
5. The build timings are noisy on this host: serial min 5949.238 against max 14355.273, a ratio near 2.4, and parallel min 2136.219 against max 6056.087.  The median is the frozen figure and min and max are stored beside it, so later stages can see the spread.
6. Per brief section 3.4 the timed unit for ocamlopt_ms_per_kloc is `dune clean` followed by `dune build -j 1 ./lib`, so the clean is inside the measured interval.  The exact string is stored in the `command` field and named in `method`, so the denominator is reproducible.

### Decisions taken during the build

- The child shell is `/bin/zsh -f -c` rather than `zsh -c`: same one-string contract, no user rc files, honest timing.
- pin-dune.sh clears the user chpwd hooks before the cd; no hook runs inside a timed call.
- RUNS stayed at the default 5 for every frozen measurement, because a `RUNS=` prefix on an agent Bash call is banned.  The judge's RUNS=9 run was a stability probe only; no frozen number came from it.
- main.exe was timed from /Users/oobi/Documents/kan-lang-tot-pin/_build/default/test, the first cwd tried; it exited 0 there and also from the pin root.
- Corpus paths are relative to the pin root, sorted by `sort`, and the sha256 is the hash of `cat` over that order.
- After the measurements a full `zsh /Users/oobi/Documents/kanon/dev/pin-dune.sh build` restored main.exe; the pin stayed at 8cf0b8b with porcelain 0, and no pin source was touched.
- Nothing was committed.  Every file lives under /Users/oobi/Documents/kanon/dev/.
