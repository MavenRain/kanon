# kanon M1 build log

This log follows the plan at kanon-m1/M1-PLAN.md.  dev/M0-BUILD-LOG.md is
closed at M0-EXIT (M1-PLAN.md:51) and no M1 stage writes to it again.

## Stage G (2026-09-06)

### Deliverables

The line counts are read on ROOT after the build of SG-G1.

| file | lines | note |
| --- | --- | --- |
| lib/positivity.ml | 153 | new;  strict positivity, the family record |
| lib/rules.ml | 1193 | the SMu pack replaces the refusal at the old :188 |
| lib/check.ml | 446 | the index telescope rules and the installation |
| lib/global.ml | 130 | the family table and its one accessor |
| lib/shape.ml | 60 | the three total views payload, point_dom, family |
| lib/term.ml | 92 | the ACtor rows of as_apt and as_aleg |
| lib/error.ml | 69 | Index_not_zero and Index_above_universe |
| lib/erase.ml | 1146 | the interim mu erasure word of 3.8 |
| SPEC.md | 470 | the moved R0 counts and the positivity rule text |
| dev/trusted-lines.sh | 74 | positivity.ml and global.ml join the list |
| surface/token.ml | 128 | the mu and and words |
| surface/lexer.ml | 140 | the two new words |
| surface/syntax.ml | 234 | the fam, fam_ctor and DMu rows |
| surface/parser.ml | 458 | the minimal mu production of C7 |
| surface/elab.ml | 811 | the DMu arm, elab_program_in and check_in |
| bin/kanon.ml | 308 | run_erased and module_bytes carry the globals |
| test/main.ml | 289 | the ERASE-NEG group and the moved KNEG row |

The fixtures of brief 3.9 and the interim erasure fixture of 3.8.

| file | lines |
| --- | --- |
| test/fixtures/mu-direct.kan | 8 |
| test/fixtures/mu-indexed.kan | 11 |
| test/fixtures/mu-mutual.kan | 9 |
| test/neg/mu-nonpositive.kan | 7 |
| test/neg/mu-nonpositive.err | 1 |
| test/neg/mu-index-runtime.kan | 10 |
| test/neg/mu-index-runtime.err | 1 |
| test/neg/mu-index-mismatch.kan | 14 |
| test/neg/mu-index-mismatch.err | 1 |
| test/erase-neg/mu-erase.kan | 11 |
| test/erase-neg/mu-erase.err | 1 |

The six golden files test/golden/mu-direct.checked, mu-direct.erased,
mu-indexed.checked, mu-indexed.erased, mu-mutual.checked and
mu-mutual.erased are empty, because the three positives declare families
and add no entry (SG-D22).

The minimal mu production of correction C7 is surface/parser.ml:411-453,
43 lines, with its doc comment at :396-410, the declaration arm at
:388-390 and the term position refusals at :303-306.  The sugar and the
spine additions stay at Stage L (M1-PLAN.md:230).

### Gates

The judge reran SG-G1 to SG-G7 on ROOT at 2026-09-06 04:21, after
`zsh dev/dune.sh clean`.  Each line below is the exact final line of the
command, with its exit code.

- SG-G1 BUILD.  `zsh dev/dune.sh clean` exit 0, then
  `zsh dev/dunecho.sh build` printed `OK build: 0 errors, 0 warnings`,
  exit 0.
- SG-G2 R0-AUDIT.  `zsh dev/r0-audit.sh` printed `R0-AUDIT OK`, exit 0.
- SG-G3 R0-COUNT.  The brief command `zsh dev/gates.sh --leg R0-COUNT`
  printed `gates: unknown leg R0-COUNT`, exit 64, because dev/gates.sh
  accepts only axioms, e2e, time, ratio, denominators and pin at :257-266
  (SG-D25, finding F1).  The leg body `zsh dev/r0-count.sh` printed
  `R0-COUNT OK`, exit 0, and the whole battery printed `PASS R0-COUNT`.
  `_build/default/bin/kanon.exe spec-count` printed
  `shapes admitted 3: SPi SColl SMu` and
  `no eta 3: Lan-SColl Ran-SMu Lan-SMu`, exit 0.
- SG-G4 POSITIVITY.  The stage local command over the six fixtures of
  3.9, `kanon.exe check FILE`, printed:
  test/fixtures/mu-direct.kan, no output, exit 0;
  test/fixtures/mu-indexed.kan, no output, exit 0;
  test/fixtures/mu-mutual.kan, no output, exit 0;
  test/neg/mu-nonpositive.kan,
  `not yet: a family that is not strictly positive arrives at M2`,
  exit 1;
  test/neg/mu-index-runtime.kan, `index not zero: the index i of W is at
  quantity w and every index binder is at 0`, exit 1;
  test/neg/mu-index-mismatch.kan, `mismatch: the constructor vz of V
  gives the index (In SMu N [] (ACtor zero) []) and the type asks for (In
  SMu N [] (ACtor succ) [(In SMu N [] (ACtor zero) [])])`, exit 1.
  The interim erasure fixture of 3.8,
  `kanon.exe check --erased test/erase-neg/mu-erase.kan`, printed
  `not yet: an erasure at a mu shape arrives at M1 Stage J`, exit 1.
- SG-G5 SUITE-KERNEL.  The brief command `zsh dev/gates.sh --leg
  SUITE-KERNEL` printed `gates: unknown leg SUITE-KERNEL`, exit 64, for
  the reason of SG-G3 (SG-D25, finding F1).  The leg body
  `_build/default/test/main.exe test` printed `CHECK-OK 50/50`,
  `NEG-OK 14/14`, `ERASE-NEG-OK 1/1`, `KNEG-OK 2/2` and the final line
  `SUITE-KERNEL OK`.  The whole battery printed `PASS SUITE-KERNEL`.
- SG-G6 TRUSTED-LINES.  `zsh dev/trusted-lines.sh ROOT` printed
  `TRUSTED-LINES kernel=2995/3000 encoder=216/600 OK`, exit 0.  N is
  2995 over the ten believed files of 3.10, which hold lib/positivity.ml
  and lib/global.ml.
- SG-G7 HOUSE.  `zsh dev/house.sh ROOT` printed `HOUSE OK`, exit 0.
- SG-G8 LOGS.  dev/M1-BUILD-LOG.md holds `## Stage G (2026-09-06)` once
  and dev/M1-MUTATION-LOG.md holds `## Stage G` once.
  `git -C ROOT diff --stat -- dev/M0-BUILD-LOG.md dev/MUTATION-LOG.md`
  printed nothing, so both M0 logs are byte for byte unchanged.  The
  porcelain lists only Stage G paths.

### MEASURE table

The judge ran the whole battery `zsh dev/gates.sh` once on ROOT at
2026-09-06 04:21, at the load average 11.47 11.86 13.32.  The rows are
copied from that run.

```
MEASURE BUILD tier=SLOW elapsed_ms=65.823 exit=0
MEASURE CARRY tier=MED elapsed_ms=351.558 exit=1
MEASURE R0-COUNT tier=FAST elapsed_ms=43.445 exit=0
MEASURE R0-AUDIT tier=FAST elapsed_ms=23.733 exit=0
MEASURE SUITE-KERNEL tier=SUITE elapsed_ms=23.876 exit=0
MEASURE SUITE-WASM tier=SUITE elapsed_ms=1469.222 exit=0
MEASURE ENCODER-SUBSET tier=FAST elapsed_ms=44.198 exit=0
MEASURE AXIOMS tier=MED elapsed_ms=23.589 exit=0
MEASURE M0-E2E tier=SLOW elapsed_ms=441.148 exit=0
MEASURE M0-TIME tier=SLOW elapsed_ms=635.494 exit=0
MEASURE M0-RATIO tier=SLOW elapsed_ms=249.866 exit=0
MEASURE TRUSTED-LINES tier=FAST elapsed_ms=21.540 exit=0
MEASURE DENOMINATORS tier=MED elapsed_ms=37.169 exit=0
MEASURE HOUSE tier=MED elapsed_ms=72.436 exit=0
MEASURE PIN tier=FAST elapsed_ms=66.093 exit=0
MEASURE M0-RATIO kanon_ms=26.068 tot_ms=103.662 ratio=0.251
```

The timed leg.  The bound stays 150 ms and no agent moved it;
dev/gates.sh:48 still reads `M0_TIME_MS=150` (dev/M0-BUILD-LOG.md:999).
The battery reading was `PASS M0-TIME median_ms=93.984 bound_ms=150` at
the load average 11.47.  The judge then ran the leg three more times, at
2026-09-06 04:25, and reports every reading with its load average:

```
run 1  load 14.34 13.34 13.57  PASS M0-TIME median_ms=91.806 bound_ms=150
run 2  load 14.34 13.34 13.57  PASS M0-TIME median_ms=92.000 bound_ms=150
run 3  load 14.34 13.34 13.57  PASS M0-TIME median_ms=98.854 bound_ms=150
```

The builder read `FAIL M0-TIME median_ms=182.209 bound_ms=150` at the
load average 12.77 (SG-D27).  Four judge readings under 100 ms, at a
higher load, confirm the load artefact and refute a regression.

### Decisions

SG-D1 to SG-D13 are pinned by the Stage G brief section 3.11.  SG-D13 to
SG-D27 are the builders'.  The number SG-D13 is used twice, because the
brief says the builders continue after SG-D12 but its own list ends at
SG-D13;  both texts are kept and the collision is reported as finding F4.

- SG-D1 The family record and its table live beside the Global table and
  Global.entry gains no constructor (R-Q3);  lib/global.ml joins the
  believed TRUSTED-LINES list and the budgets stay 3000 and 600.
- SG-D2 rules.ml reads the record through exactly one accessor, so no
  family lookup enters check.ml (r0-audit.sh:6-11).
- SG-D3 Positivity and self_rec are computed once at installation and
  stored, never recomputed at formation (A4).
- SG-D4 Ran (SMu ..) is refused inside the pack at ran_lvl and at the Ran
  intro and elim fields, never at the dispatch.
- SG-D5 The pack answers eta_ran false and eta_lan false, so no eta grows
  from 1 to 3 and the eta table stays at three rows.
- SG-D6 The SPar cell at SPEC.md:30 moves from M1 to M2 in this commit
  (open question 4, RATIFICATIONS.md:77).
- SG-D7 The interim erasure word is exactly `an erasure at a mu shape
  arrives at M1 Stage J` and the fixture pins it byte for byte.
- SG-D8 Formation checks the declared level with Level.le and never
  computes a max (A5).
- SG-D9 The elimination fields answer the Stage H word at this stage.
- SG-D10 SG-G8 LOGS is added by the brief on the form of SE-G12.
- SG-D11 Every mutation runs on a fresh copy under SCRATCH/stageG and
  ROOT is never mutated.
- SG-D12 positivity.ml joins the trusted list and the budgets do not
  move.
- SG-D13 (brief) The six fixtures of 3.9 enter as .kan files through the
  minimal mu production of C7;  test/main.ml is not the entry path.
- SG-D13 (builder 1) lib/positivity.ml walks a shape through the three
  total views of shape.ml and spells no shape name, so SG-G2 stays green.
- SG-D14 The family record type lives in lib/positivity.ml, not in
  global.ml, because global.ml reads Prim.catalog and prim.ml reads
  Rules.arrow;  the table and its one accessor stay beside the Global
  table at global.ml:61-79.
- SG-D15 The two level fields of the pack are retyped to read the mu
  level off the family record;  a combinator payload_lvl adapts the two
  M0 packs, so SPi and SColl keep their bodies.
- SG-D16 The diagram at the mu shape is the parameter section, one binder
  free leg per parameter.
- SG-D17 A Provisional family forms, so a field type may name the family
  while the constructors are installed;  only a Complete family whose
  stored verdict is false is refused.
- SG-D18 Three refactors keep the ten believed files at 2995 of 3000:
  inline refusal lambdas, one accessor that merges the lookup and the
  stored verdict, and one telescope walk shared by the binder.
- SG-D19 The words for the sidecars are `a family that is not strictly
  positive arrives at M2`, `a right former at a mu shape arrives at M2`
  and `an elimination at a mu shape arrives at M1 Stage H`;  the two new
  error heads print as `index not zero: ` and `index above universe: `.
- SG-D20 The erase entry path carries the globals:  elab gains
  elab_program_in and check_in, and bin/kanon.ml and test/main.ml pass
  those globals to Erase.program, so a checked mu file no longer erases
  in an empty family table.
- SG-D21 The interim erasure word is pinned by a new negative group,
  test/erase-neg, run by erase_negative and counted as ERASE-NEG-OK.
- SG-D22 The three positives declare families and add no entry, so the
  six golden files are empty;  CHECK and ERASE grow from 47 to 50.
- SG-D23 The KNEG row smu moves from the left former to the right former
  at a mu shape, so KNEG keeps two rows and pins mu_ran_word.
- SG-D24 The constructor lookup of the elaborator reads the public
  Global.StringMap fold over the family table and adds no accessor to
  lib/global.ml, because the kernel budget stands at 2995 of 3000.
- SG-D25 dev/gates.sh --leg accepts only axioms, e2e, time, ratio,
  denominators and pin, so the two brief commands of SG-G3 and SG-G5 exit
  64;  both legs were read from the whole battery and from the leg bodies.
- SG-D26 The whole battery FAILs on CARRY, because Stage G grows
  lib/global.ml and the carried expectation at dev/CARRIED.md:14 still
  reads 164.  That file is out of the brief's scope, so it was left
  untouched and the user rules.
- SG-D27 The battery M0-TIME FAIL the builder saw is a load artefact and
  not a regression;  the bound was not moved.

### Findings

- F1, info, closed as a brief erratum.  The SG-G3 and SG-G5 commands of
  the brief do not exist:  `zsh dev/gates.sh --leg R0-COUNT` and
  `--leg SUITE-KERNEL` both print `gates: unknown leg NAME`, exit 64
  (dev/gates.sh:257-266).  The judge reproduced both and read the two
  legs from the whole battery and from the leg bodies instead.  A later
  stage cites `zsh dev/r0-count.sh` and `_build/default/test/main.exe
  test`, or Stage L adds the two leg names.
- F2, medium, open for the user.  The whole battery ends in `GATES-FAIL`,
  exit 1, on the row `CARRY lib/global.ml diff=196 expected=164
  header=OK FAIL`.  The growth is the family table this stage adds, so
  the code is right and the expectation is stale.  dev/CARRIED.md:14 is
  outside the brief's deliverables, so no agent moved it.  The user
  rules:  move the count at dev/CARRIED.md:14 from 164 to 196 and extend
  the paragraph at :26-29 with the family table, in the Stage G commit,
  or defer the row to Stage L.  The tree does not pass its own battery
  until that ruling lands.
- F3, info, closed.  The builder read `FAIL M0-TIME median_ms=182.209
  bound_ms=150` at the load average 12.77.  The judge read
  `PASS M0-TIME median_ms=93.984 bound_ms=150` in the battery and three
  more PASS readings of 91.806, 92.000 and 98.854 ms at the load average
  14.34.  The reading is a load artefact.  The bound stays 150.
- F4, low, reported.  The number SG-D13 names two decisions:  the brief's
  own last bullet at 3.11 and builder 1's first.  The brief text says the
  builders continue after SG-D12 while its list ends at SG-D13.  Both
  texts are kept above.  A later brief starts its builder range one
  number above the last bullet it writes.

### Hand-off notes for Stage H

Stage H brings the fibered Elim branch and motive rules and the
subsingleton criterion (M1-PLAN.md:198).  It reads three things this
stage leaves ready.

- The elimination fields of the SMu pack.  lib/rules.ml:1113 holds
  `elim_elim`, :1097 holds the BElim beta arm and both answer
  `Error (Error.Not_yet mu_elim_word)`, with the word at rules.ml:957,
  `an elimination at a mu shape arrives at M1 Stage H` (SG-D9, SG-D19).
  Stage H replaces those two sites and no other.  `elim_sec` at :1115,
  `elim_out` at :1116, `form_ran` at :1111 and `ran_lvl` at :1133 keep
  the M2 word `a right former at a mu shape arrives at M2`, because a
  coinductive section is SNu's job (SG-D4).
- The family record accessor.  lib/rules.ml:967 holds `mu_family`, the
  one accessor of brief 3.3, which answers the record of
  lib/positivity.ml:47-55 and refuses a Complete family whose stored
  positivity verdict is false (SG-D2, SG-D17).  The motive rules read
  `f_params`, `f_indices`, `f_level` and `f_ctors` through it, and
  `Positivity.ctor_of` at positivity.ml:59 reads one constructor.  A
  second reader would put a family lookup in check.ml and turn SG-G2 red.
- The SPEC.md status cell.  The named rule row moved with the file, from
  the brief's :208 to SPEC.md:218 today, and still reads the milestone
  M1.  Stage H turns that cell to present and moves
  `named rules present 2: proof-irrelevance literal-fast-path` at
  SPEC.md:155 to three, in the same commit as the criterion, so R0-COUNT
  is never red on a committed tree.  The M1 obligation row at SPEC.md:468
  moves with it.
- `Positivity.self_rec` at positivity.ml:152 stores the flag part one of
  the criterion asks for (A1), so Stage H reads it and never recomputes.

### Addendum, ruling round 2026-09-06 (c)

Applied after the judge verdict CHECK, on the user ruling of 2026-09-06
recorded in RATIFICATIONS.md, round (c).  It resolves finding F2.

- SG-D28 The CARRY row for lib/global.ml moves from 164 to 196 in this
  commit (dev/CARRIED.md:14, paragraph at :26-31), because Stage G adds
  the family record and the families table at lib/global.ml:61-79.  The
  row moves in the form of the quantity.ml row of Stage B.
- D-M1-7 amended once by the user: kernel_bound moves from 3000 to 4000
  at dev/trusted-lines.sh:31, encoder_bound stays 600, the believed list
  stays the ten files of SG-G6.  No stage moves a bound again.
- Reruns after the two edits, load average 11.77 14.46 14.22:
  `CARRY lib/global.ml diff=196 expected=196 OK` and `CARRY-OK`
  `TRUSTED-LINES kernel=2995/4000 encoder=216/600 OK`
  `GATES-OK` with every leg line: PASS BUILD, PASS CARRY, PASS R0-COUNT,
  PASS R0-AUDIT, PASS SUITE-KERNEL, PASS SUITE-WASM, PASS ENCODER-SUBSET,
  PASS AXIOMS, PASS M0-E2E main=521, PASS M0-TIME median_ms=94.423
  bound_ms=150, PASS M0-RATIO ratio=0.243, PASS TRUSTED-LINES,
  PASS DENOMINATORS, PASS HOUSE, PASS PIN sha=8cf0b8b
- dev/M1-MUTATION-LOG.md is unchanged by this addendum.

### Stage G review fixes (2026-09-06)

Four declaration checks now run before a family is installed.  A family
name must be fresh, every field must obey the declared universe bound,
the result parameters must be the original parameter variables in
order, and each result index must check against the dependent index
telescope under the parameters and fields.  The elaborator retains the
result parameters in `Check.ctor_decl` so the kernel can check them.
Constructor installation also refuses a family that is already complete
or builtin.  These checks correct the initial declaration-validation
claims above; introduction still checks result-index conversion.

Seven negative fixtures cover family redeclaration, duplicate mutual
members, oversized fields, ill-typed and unbound indices, and changed
or reordered parameters.  The positive `mu-constructor-scopes` fixture
covers parameter variables under fields, a parameter-dependent index,
dependent result indices, and a field at its allowed universe bound.

Validation ran on the fixed source copy at
/private/tmp/kanon-stage-g-fixes-dx26e5r5.  Its vendor/tot link reads the
existing pinned checkout; it writes no vendor file.  The initial run
lacked that link and failed CARRY and PIN.  With the link present, the
full unmodified `zsh dev/gates.sh` battery exited 0 with 15 PASS lines
and `GATES-OK`.  The log is /private/tmp/kanon-stage-g-fixes-gates.log.

- BUILD: `OK build: 0 errors, 0 warnings`.
- Kernel suite: `PARSE-OK 73/73`, `CHECK-OK 51/51`, `ERASE-OK 51/51`,
  `NEG-OK 21/21`, `ERASE-NEG-OK 1/1`, `KNEG-OK 2/2`, `SUITE-KERNEL OK`.
- WebAssembly suite: `WASM-OK 15/15`, `SUITE-WASM OK`.
- `TRUSTED-LINES kernel=3051/4000 encoder=216/600 OK`.
- Four independent mutations built successfully and then failed the
  kernel suite at the corresponding new negative fixtures.  Their
  exact failures are recorded in M1-MUTATION-LOG.md.

The bounds and existing gate implementations are unchanged by these
fixes.  Source, fixtures and logs are staged for the user to commit.
