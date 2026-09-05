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
