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
