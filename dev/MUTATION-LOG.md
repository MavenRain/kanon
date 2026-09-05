# M0 mutation log

## Stage 0

Both checks were rerun by the judge on 2026-09-05 on copies under /private/tmp/claude-501/-Users-oobi-Documents-claude4/3017512c-b634-4681-9bd6-97118fdb85ef/scratchpad/stage0.  No repository file was mutated; `git -C /Users/oobi/Documents/kanon status --porcelain -uall` still lists only paths under dev/.

### S0-M1 timer resolution

Mutation: copy dev/bench.sh to the scratch dir, then replace the nanosecond clock with a whole-second one.

Commands:

```
cp /Users/oobi/Documents/kanon/dev/bench.sh <scratch>/stage0/bench-m1.sh
sd 'time\.perf_counter_ns\(\)' 'int(time.time()) * 1000000000' <scratch>/stage0/bench-m1.sh
rg -c 'int\(time\.time\(\)\) \* 1000000000' <scratch>/stage0/bench-m1.sh
zsh <scratch>/stage0/bench-m1.sh sleep50 'sleep 0.05'
```

Both call sites were rewritten; `rg -c` printed `2`, and the only remaining mention of the old clock is the header comment.  The mutant printed `BENCH sleep50 median_ms=0.000 min_ms=0.000 max_ms=0.000 runs=5`.  The S0-G2 band is 40 to 150 ms, so the band check on the mutant is false while the same check on the real script passes with `median_ms=71.703`.

Result: killed.

### S0-M2 hash

Mutation: copy dev/denominators.json and dev/DENOMINATORS.sha256 to a scratch directory, then flip one byte in the JSON copy.  The judge flipped a different byte from the builder's run: the last character of the pin short hash.

Commands:

```
cp /Users/oobi/Documents/kanon/dev/denominators.json <scratch>/stage0/m2/denominators.json
cp /Users/oobi/Documents/kanon/dev/DENOMINATORS.sha256 <scratch>/stage0/m2/DENOMINATORS.sha256
sd '"tot_pin": "8cf0b8b"' '"tot_pin": "8cf0b8c"' <scratch>/stage0/m2/denominators.json
cmp -l /Users/oobi/Documents/kanon/dev/denominators.json <scratch>/stage0/m2/denominators.json
zsh -c "cd <scratch>/stage0/m2 && shasum -c DENOMINATORS.sha256"
```

`cmp -l` printed exactly one differing byte.  The check printed `denominators.json: FAILED` and `shasum: WARNING: 1 computed checksum did NOT match`, and exited 1, while the same check on the real pair prints `denominators.json: OK` and exits 0.

Result: killed.

## Stage A

Copies live under SCRATCH/stageA, one fresh copy per mutation, made with `rsync -a --exclude _build /Users/oobi/Documents/kanon/ SCRATCH/stageA/mN/`.  SCRATCH is /private/tmp/claude-501/-Users-oobi-Documents-claude4/3017512c-b634-4681-9bd6-97118fdb85ef/scratchpad.  The repository itself was never mutated.  The judge reran all three checks after the fix round.

### SA-M1 closed grammar

Mutation: a fixture that uses the reserved word `mu`, in a scratch fixtures directory of its own, so the repository's own ten fixtures stay untouched.

Commands:

```
printf 'def bad : Type := mu\n' > SCRATCH/stageA/fx/mu.kan
/Users/oobi/Documents/kanon/_build/default/test/main.exe SCRATCH/stageA/fx
```

The suite printed `PARSE mu FAIL: mu arrives at M1` then `PARSE-FAIL 0/1` and exited 1.

Result: killed.  Caught by the PARSE leg, through the parser's refusal of the reserved word (SA-D3).

### SA-M2 carry

Mutation: one line appended to lib/level.ml in a copy of the tree.

Commands:

```
rsync -a --exclude _build /Users/oobi/Documents/kanon/ SCRATCH/stageA/m2/
printf '\n(* mutation *)\n' >> SCRATCH/stageA/m2/lib/level.ml
zsh SCRATCH/stageA/m2/dev/carry-check.sh
```

The copy's own check printed `CARRY lib/level.ml diff=5 expected=2 header=OK FAIL`, then the other six OK rows, then `CARRY-FAIL`, and exited 1.  The copy ran its own script and read its own tree, which is what SA-D7 buys.

Result: killed.  Caught by the CARRY leg.

### SA-M3 R0 growth

Mutation: a sixth name added to `Shape.declared` in a second copy.

Commands:

```
rsync -a --exclude _build /Users/oobi/Documents/kanon/ SCRATCH/stageA/m3/
sd '"SNu" \]' '"SNu"; "SXx" ]' SCRATCH/stageA/m3/lib/shape.ml
zsh SCRATCH/stageA/m3/dev/dune.sh clean
zsh SCRATCH/stageA/m3/dev/dunecho.sh build
zsh SCRATCH/stageA/m3/dev/r0-count.sh
```

The copy built clean, `OK build: 0 errors, 0 warnings`, exit 0, so the mutant is a live program and not a compile error.  Its R0 check printed `3c3`, `< shapes declared 5: SPi SColl SPar SMu SNu`, `> shapes declared 6: SPi SColl SPar SMu SNu SXx`, then `R0-COUNT FAIL`, and exited 1.

Result: killed.  Caught by the R0-COUNT leg, because spec_count.ml counts with `List.length` over the very list that grew (a literal integer there would have let the mutant live).

## Stage B

Four mutations, brief section 5.  A fresh copy per mutation under SCRATCH/stageB, made with `rsync -a --exclude _build --exclude .gatework /Users/oobi/Documents/kanon/ SCRATCH/stageB/mN/`, never the repository itself.  Each copy builds with `zsh COPY/dev/dune.sh build` and runs with `COPY/_build/default/test/main.exe COPY/test`.  Each site carries a `(* SB-Mk site *)` comment, so `rg -n 'SB-Mk site' COPY/lib` finds it.

### SB-M1 function eta

Mutation: `expand_ran = Some spi_eta_ran` becomes `expand_ran = None` at the SB-M1 site of lib/rules.ml, so conv falls through to the head comparison at the right former of the point shape.

The copy built clean, `OK build: 0 errors, 0 warnings`, so the mutant is a live program.  Its suite printed `CHECK b01-function-eta FAIL: mismatch: the term has type (Out SPi 0 g (Ran SPi w _ A A) (APt 0 f) F) and the expected type is (Out SPi 0 g (Ran SPi w _ A A) (APt 0 (Sec SPi w x A [x => (Out SPi w _ A (APt w x) f)])) F)`, then `CHECK-OK 17/18`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the CHECK leg on b01-function-eta.

### SB-M2 proof irrelevance

Mutation: the arm `| () when is_prop ops ctx ty -> Ok true` is dropped at the SB-M2 site of lib/conv.ml, so conversion starts at the eta step.

The copy built clean.  Its suite printed `CHECK b05-proof-irrelevance FAIL: mismatch: the term has type (Out SPi 0 z P (APt 0 p1) G) and the expected type is (Out SPi 0 z P (APt 0 p2) G)`, then `CHECK-OK 17/18`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the CHECK leg on b05-proof-irrelevance.

### SB-M3 imax

Mutation: the body of `imax` at the SB-M3 site of lib/rules.ml becomes `Level.max l l'`, which drops the framework axiom of R-Q6.

The copy built clean.  Its suite printed `CHECK b06-impredicativity FAIL: universe: the former lives at 1 and the expected universe is 0`, then `CHECK-OK 17/18`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the CHECK leg on b06-impredicativity, which declares an arrow out of `Type 0` at `Prop`.

### SB-M4 closed shapes

Mutation: the SMu arm of `rules` at the SB-M4 site of lib/rules.ml answers `Ok (coll_pack ())` instead of `Error (Not_yet smu_word)`, so a shape M0 declares and does not admit gets the collection pack.

The site comment matters here:  the text `| Shape.SMu (_, _) -> Error (Error.Not_yet smu_word)` appears twice in rules.ml, at the shape equality and at `rules`, and only the second is the site.  A first attempt that edited the earlier occurrence did not build, `Error: Unbound value "coll_pack"`, and a dead mutant proves nothing, so the copy was made again and the anchored site was edited.

The second copy built clean.  Its suite printed `KNEG smu FAIL: the message is "the rule pack does not match the shape of the term"`, then `KNEG-OK 0/1`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the KNEG leg.  The mutant does not admit SMu quietly:  it gets a pack whose shape does not match, which the suite reads as the wrong message and refuses.

### Judge rerun of the four mutations (2026-09-05)

The judge remade one copy per mutation after the fix round, with `rsync -a --exclude _build --exclude .gatework /Users/oobi/Documents/kanon/ SCRATCH/judgeB/stageB/mN/`, and edited each site through an anchored replacement that first counts the anchor and stops when the count is not one.  This is the guard the SB-M4 trap of the first run needs:  the anchor holds the `(* SB-Mk site *)` comment line and the line under it, so the earlier identical arm of the shape equality cannot be edited by mistake.  The counts below are the counts of the fixed suite, 22 checked positives and 11 negatives, so they read one higher than the counts of the first run.

- SB-M1 function eta.  `expand_ran = Some spi_eta_ran;` becomes `expand_ran = None;` at lib/rules.ml.  The copy built clean, `m1-BUILD-EXIT=0`, and its suite printed `CHECK b01-function-eta FAIL: mismatch: the term has type (Out SPi 0 g (Ran SPi w _ A A) (APt 0 f) F) and the expected type is (Out SPi 0 g (Ran SPi w _ A A) (APt 0 (Sec SPi w x A [x => (Out SPi w _ A (APt w x) f)])) F)`, then `CHECK-OK 21/22`, `SUITE-KERNEL FAIL`, exit 1.  Killed.
- SB-M2 proof irrelevance.  The guard at lib/conv.ml becomes `| () when false && is_prop ops ctx ty -> Ok true`, so the step never fires and conversion starts at eta.  The copy built clean and its suite printed `CHECK b05-proof-irrelevance FAIL: mismatch: the term has type (Out SPi 0 z P (APt 0 p1) G) and the expected type is (Out SPi 0 z P (APt 0 p2) G)`, then `CHECK-OK 21/22`, `SUITE-KERNEL FAIL`, exit 1.  Killed.
- SB-M3 imax.  The body of `imax` at lib/rules.ml becomes `Level.max l l'`.  The copy built clean and its suite printed `CHECK b06-impredicativity FAIL: universe: the former lives at 1 and the expected universe is 0`, then `CHECK-OK 21/22`, `SUITE-KERNEL FAIL`, exit 1.  Killed.
- SB-M4 closed shapes.  The SMu arm of `rules` at lib/rules.ml answers `Ok (coll_pack ())`.  The copy built clean and its suite printed `KNEG smu FAIL: the message is "the rule pack does not match the shape of the term"`, then `KNEG-OK 0/1`, `SUITE-KERNEL FAIL`, exit 1.  Killed.

Four mutants of four are killed, each by the leg brief section 5 names.

## Stage C

Three mutations, brief section 5.  A fresh copy per mutation under SCRATCH/stageC, made with `rsync -a --exclude _build --exclude .gatework /Users/oobi/Documents/kanon/ SCRATCH/stageC/fmN/`, never the repository itself.  Each copy builds with `zsh COPY/dev/dune.sh build` and runs with `COPY/_build/default/test/main.exe COPY/test`.  Each site carries a `(* SC-Mk site *)` comment, so `rg -n 'SC-Mk site' COPY/lib` finds it:  lib/erase.ml:97 for SC-M1, lib/erase.ml:170 for SC-M2 and lib/totality.ml:51 for SC-M3.  The three runs below are the fix round's own (SC-D43).

### SC-M1 binder erasure

Mutation: `not (Quantity.equal q Quantity.Zero)` becomes `Quantity.equal q Quantity.Zero && false` at the SC-M1 site of lib/erase.ml, so `quantity_runtime` answers false for `One` and for `Many` as it does for `Zero`, and a runtime parameter is dropped.

The copy built clean, `fm1-BUILD-EXIT=0`, so the mutant is a live program.  Its suite printed `CHECK-OK 27/27`, then `ERASE c02-zero-binder FAIL: the erased form is not the golden text` with sixteen other ERASE FAIL lines, then `ERASE-OK 10/27`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the ERASE leg on c02-zero-binder, the line brief section 5 names.

### SC-M2 proof kept

Mutation: `Ok (not (Level.equal l Level.zero))` becomes `Ok (Level.equal l Level.zero || true)` at the SC-M2 site of lib/erase.ml, so `proof_free` answers true at a proposition type and a proof at a runtime position stays runtime instead of `KErased`.

The copy built clean, `fm2-BUILD-EXIT=0`.  Its suite printed `CHECK-OK 27/27`, then `ERASE c01-prop-argument FAIL: the erased form is not the golden text` with six other ERASE FAIL lines, b01, b02, b03, b04, b05 and b07, then `ERASE-OK 20/27`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the ERASE leg on c01-prop-argument, the line brief section 5 names.

### SC-M3 totality

Mutation: `if String.equal n name then Error (Error.Not_yet word) else Ok ()` becomes `if String.equal n name && false then Error (Error.Not_yet word) else Ok ()` at the SC-M3 site of lib/totality.ml, so `guard` answers `Ok None` whatever the body holds.

The copy built clean, `fm3-BUILD-EXIT=0`.  Its suite printed `CHECK-OK 27/27`, `ERASE-OK 27/27`, `NEG-OK 11/11`, then `KNEG self FAIL: the self reference is admitted at M0`, `KNEG-OK 1/2`, `SUITE-KERNEL FAIL`, exit 1.

Result: killed.  Caught by the KNEG leg on self, the line brief section 5 names.

Three mutants of three are killed, each by the leg brief section 5 names.
