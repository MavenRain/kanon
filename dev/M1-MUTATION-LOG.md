# kanon M1 mutation log

## Stage F

Four mutations, each on its own fresh copy of the package made with
`rsync -a --exclude .lake /Users/oobi/Documents/kanon-stage-f/meta/
SCRATCH/stageF/judge/jmN/`, then given a copy of meta/.lake/packages
with a second `rsync -a` so the copy builds with no remote.  Each copy
was built through the detached runner with
`/Users/oobi/.elan/bin/lake +leanprover/lean4:v4.33.0-rc1 --dir
SCRATCH/stageF/judge/jmN build`.  ROOT was never mutated:  `git -C ROOT
status --porcelain` lists the untracked meta/ directory and the two new
dev/M1 log files, and no other path, before and after.  The
judge reran all four at 2026-09-06 03:02.

### SF-M1 dropped hypothesis

- Site.  The copy's KanonMeta/BeckChevalley.lean:29, the right side of
  `bc_lan_spi`.
- Edit.  `Term.lan (Shape.SPi q x (subst sigma dom)) (subst (up sigma)
  A)` becomes `Term.lan (Shape.SPi q x (subst sigma dom)) (subst sigma
  A)`, so the lift under the one binder of the point diagram is gone.
- Killing line.  `error: KanonMeta/BeckChevalley.lean:29:70: unsolved
  goals`, then `error: build failed`, exit file `EXIT 1`.  The column
  names the mutated right side of `bc_lan_spi`.

### SF-M2 swapped side

- Site.  The copy's KanonMeta/BeckChevalley.lean:36, the right side of
  `bc_ran_spi`.
- Edit.  `Term.ran (Shape.SPi q x (subst sigma dom)) (subst (up sigma)
  A)` becomes `Term.ran (Shape.SPi q x dom) (subst (up sigma) A)`, so
  the shape payload is not carried through sigma, which is the error the
  design verdict names at :164-166.
- Killing line.  `error: KanonMeta/BeckChevalley.lean:36:61: unsolved
  goals`, then `error: build failed`, exit file `EXIT 1`.

### SF-M3 SColl n to SColl 0

- Site.  The copy's KanonMeta/BeckChevalley.lean:52, the right side of
  `bc_ran_scoll`.
- Edit.  `= Term.ran (Shape.SColl n) (subst sigma A)` becomes
  `= Term.ran (Shape.SColl 0) (subst sigma A)`, on the right side only.
- Killing line.  `error: KanonMeta/BeckChevalley.lean:52:52: unsolved
  goals`, then `error: build failed`, exit file `EXIT 1`.

### SF-M4 the SF-G2 control

- Site.  The copy's KanonMeta/BeckChevalley.lean:30, the proof body of
  `bc_lan_spi`.
- Edit.  `kan_rfl` becomes `sorry`.
- Killing line.  The sweep kills it, not the build, which is what the
  brief expects.  `rg -n -c "sorry" SCRATCH/stageF/judge/jm4` printed
  `SCRATCH/stageF/judge/jm4/KanonMeta/BeckChevalley.lean:1`, rg exit 0,
  so the SF-G2 sweep is not vacuous.  The build itself only warned,
  in these words, with the escape hatch name in backticks:
  warning: KanonMeta/BeckChevalley.lean:26:8: declaration uses `sorry`.
  The last build line is `Build completed successfully (40 jobs).` and
  the exit file holds `EXIT 0`.

### Stage F review mutations (2026-09-06)

Each mutation used a separate copy of the fixed package under
/private/tmp/kanon-stage-f-fixes, retaining cached dependencies.  Each
ran `/Users/oobi/.elan/bin/lake +leanprover/lean4:v4.33.0-rc1 --dir COPY
build`.  The unmutated package and its 16 regression checks built with
exit 0.  All four mutated builds exited 1 in the regression target.

- `binder-subst`: replace `subst (upN binders.length sigma) body` with
  `subst sigma body` in Subst.lean.  First killing line:
  `error: test/Regression.lean:21:43: unsolved goals`.
- `binder-ren`: replace `ren (upRenN binders.length rho) body` with
  `ren rho body`.  First killing line:
  `error: test/Regression.lean:25:43: unsolved goals`.
- `point-subst`: replace `Addr.apt q (subst sigma arg)` with
  `Addr.apt q arg`.  First killing line:
  `error: test/Regression.lean:75:51: unsolved goals`.
- `point-ren`: replace `Addr.apt q (ren rho arg)` with `Addr.apt q arg`.
  First killing line:
  `error: test/Regression.lean:79:51: unsolved goals`.

The four log and exit files use these names with `.log` and `.exit`
suffixes in the scratch directory.  No repository source was mutated.

## Stage G

Five mutations, each on its own fresh copy of the repository made with
`rsync -a --exclude _build --exclude .gatework`, built through the copy's
own dev/dunecho.sh, which printed `OK build: 0 errors, 0 warnings` and
exit 0 for all five (SG-D11).  ROOT was never mutated.  The judge reran
all five at 2026-09-06 04:23, on the copies judge-m1 to judge-m5 under
the session scratch directory.

### SG-M1 positivity

- Site.  The copy's lib/positivity.ml:129, the arrow domain of
  [positive], which asks [absent] for the left of an arrow (brief 3.2,
  D-M1-2).
- Edit.  `let* () = absent names dom in` becomes `let* () = Ok () in`, so
  an occurrence to the left of an arrow is admitted.
- Killing line.  `kanon.exe check test/neg/mu-nonpositive.kan` printed
  nothing and exit 0, where the sidecar promises the refusal, and the
  suite printed `NEG mu-nonpositive FAIL: the file checks and the
  negative expects it to fail`, `NEG-OK 13/14` and `SUITE-KERNEL FAIL`.
  The accepted line is the file itself, which declares a family whose
  constructor field puts the family to the left of an arrow.
  That line is test/neg/mu-nonpositive.kan:7, `| mk : (P -> P) -> P`.

### SG-M2 the counts

- Site.  The copy's SPEC.md:153 and :157, the two R0 rows the pack moves
  (brief 3.7, A3).
- Edit.  `shapes admitted 3: SPi SColl SMu` becomes `shapes admitted 2:
  SPi SColl` and `no eta 3: Lan-SColl Ran-SMu Lan-SMu` becomes `no eta 1:
  Lan-SColl`.  The pack stays in place.
- Killing line.  `zsh dev/r0-count.sh` printed the two differing rows and
  `R0-COUNT FAIL`, exit 1.  The rows are `4c4 < shapes admitted 2: SPi
  SColl > shapes admitted 3: SPi SColl SMu` and `8c8 < no eta 1:
  Lan-SColl > no eta 3: Lan-SColl Ran-SMu Lan-SMu`.

### SG-M3 the index rule of the introduction

- Site.  The copy's lib/rules.ml:1091, the last step of the mu
  introduction, which calls [mu_indices] (A14, M1-PLAN.md:79).
- Edit.  `mu_indices ops ctx n ct ixv env` becomes
  `let () = ignore (n, ct, ixv, env) in Ok ()`, so the constructor result
  indices are no longer unified with the indices of the expected type.
- Killing line.  `kanon.exe check test/neg/mu-index-mismatch.kan` printed
  nothing and exit 0, and the suite printed `NEG mu-index-mismatch FAIL:
  the file checks and the negative expects it to fail`, `NEG-OK 13/14`
  and `SUITE-KERNEL FAIL`.

### SG-M4 the index quantity

- Site.  The copy's lib/check.ml:337, the [Index_not_zero] refusal of
  brief 3.4 (A2, pin check.ml:1819).
- Edit.  `if Quantity.equal q Quantity.Zero then Ok ()` becomes
  `if Quantity.equal q q then Ok ()`, so the test is always true and an
  index binder at Many or at One is admitted.
- Killing line.  `kanon.exe check test/neg/mu-index-runtime.kan` printed
  nothing and exit 0, and the suite printed `NEG mu-index-runtime FAIL:
  the file checks and the negative expects it to fail`, `NEG-OK 13/14`
  and `SUITE-KERNEL FAIL`.

### SG-M5 the erasure word

- Site.  The copy's lib/erase.ml:447, the interim word of brief 3.8 that
  the four SMu arms at :585, :744, :818 and :890 read (A6, SG-D7).
- Edit.  `let mu_erase_word : string = "an erasure at a mu shape arrives
  at M1 Stage J"` becomes `let mu_erase_word : string = "an erasure at a
  shape past M0"`, so erasure answers the generic word of erase.ml:440
  for a checked mu term.
- Killing line.  `kanon.exe check --erased test/erase-neg/mu-erase.kan`
  printed `not yet: an erasure at a shape past M0`, exit 1, and the suite
  printed `ERASE-NEG mu-erase FAIL: the message is "an erasure at a shape
  past M0"`, `ERASE-NEG-OK 0/1` and `SUITE-KERNEL FAIL`.

### Stage G review mutations (2026-09-06)

Each mutation used a separate fixed-source copy under /private/tmp.
The command was `zsh COPY/dev/dunecho.sh build` followed by
`COPY/_build/default/test/main.exe COPY/test`.  All four builds exited
0 with no errors or warnings.  All four suites exited 1.  The unmutated
source passed the full gate battery.  No repository file was mutated.
Logs and exit files are under /private/tmp/kanon-g-mutation-logs-nzj9i441.

- `freshness`: disable the existing-family refusal in declare_family.
  Killing line: `NEG mu-redeclared FAIL: the file checks and the negative
  expects it to fail`.  The duplicate mutual member also fails its
  expected diagnostic, reaching the constructor-installation guard.
- `universe`: compare each field level with itself instead of the family
  level.  Killing line: `NEG mu-field-universe FAIL: the file checks and
  the negative expects it to fail`.
- `indices`: replace the result index telescope and argument lists by
  empty lists at the declaration check.  Killing lines:
  `NEG mu-result-index-type FAIL: the file checks and the negative
  expects it to fail` and `NEG mu-result-index-unbound FAIL: the file
  checks and the negative expects it to fail`.
- `parameters`: make the per-parameter identity check always true.
  Killing lines: `NEG mu-result-parameter FAIL: the file checks and the
  negative expects it to fail` and `NEG mu-result-parameter-order FAIL:
  the file checks and the negative expects it to fail`.

## Stage H

Six mutations, each on its own fresh copy of the repository made with
`rsync -a --exclude _build --exclude .gatework`, built through the copy's
own dev/dunecho.sh, which printed `OK build: 0 errors, 0 warnings` and
exit 0 for all six (SH-D13).  ROOT was never mutated.  The judge reran
all six at 2026-09-06 06:56, on the copies judge-m1 to judge-m6 under the
session scratch directory.  Each copy ran its own
`_build/default/test/main.exe test` and the stage local ELIM-SUITE leg
of brief 3.10.  SH-M6 is the plan's `SH-M1b` at M1-PLAN.md:200, carried
under one form of the id (SH-D14).  The line numbers below are the ones
of the copy, which are the ROOT numbers before the edit.

### SH-M1 part three of the criterion

- Site.  The copy's lib/rules.ml:1010-1011, the part three arm of
  `mu_zero_eliminable`, the port of pin check.ml:232.
- Edit.  `ct.Positivity.c_args` followed by
  `&& not ct.Positivity.c_self_rec)` becomes `ct.Positivity.c_args)`, so
  a self recursive constructor still passes the criterion.
- Killing line.  The copy's suite printed `NEG mu-large-elim-selfrec
  FAIL: the file checks and the negative expects it to fail`,
  `NEG-OK 25/26` and `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed
  `ELIM-SUITE NEG mu-large-elim-selfrec exit=0 SIDECAR-MISMATCH line=`,
  the empty line being the acceptance where the sidecar promises
  `a large elimination out of a proposition needs a subsingleton family
  at Acc`.

### SH-M2 the branch completeness check

- Site.  Two sites, the copy's lib/rules.ml:1258 `mu_cover` and its
  :1309-1312, the `~none` arm of the `List.find_opt` of `mu_branch`.
  Both are needed, which is finding SH-F-LOW-1.
- Edit.  `mu_cover` answers `Ok ()` at once and its old body is kept
  beside it as `mu_cover_off`;  the `Option.to_result ~none:(...
  Missing_branch ...)` of `mu_branch` becomes an `Option.fold` whose
  `~none` gives an empty branch at `Term.Univ Level.zero`.
- Killing line.  The copy's suite printed `NEG mu-missing-branch FAIL:
  the file checks and the negative expects it to fail`, `NEG-OK 25/26`
  and `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed
  `ELIM-SUITE NEG mu-missing-branch exit=0 SIDECAR-MISMATCH line=`,
  where the sidecar promises `the elimination of Two has no branch at
  cb`.

### SH-M3 the motive instantiation

- Site.  The copy's lib/rules.ml:1197, the body of `mu_result`.
- Edit.  `(self :: List.rev_append idx (ops.o_env ctx))` becomes
  `(self :: ops.o_env ctx)` with `let _ = idx in` above it, which is the
  plan's motive applied to the scrutinee alone.
- Killing line.  The copy's suite printed `CHECK mu-indexed FAIL:
  unbound: de Bruijn index 1 is outside the environment`, `CHECK-OK
  52/53`, the same row under ERASE with `ERASE-OK 52/53` and
  `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed `ELIM-SUITE POS
  mu-indexed exit=1 GOLDEN-MISMATCH` with `got: unbound: de Bruijn index
  1 is outside the environment`.  The killer is the definition
  `read_index` at test/fixtures/mu-indexed.kan:22, which the fix round
  added;  before it the same mutation left `SUITE-KERNEL OK`, which was
  finding SH-F-HIGH-1.

### SH-M4 the required motive

- Site.  The copy's lib/rules.ml:1164-1166, the `Option.to_result
  ~none:(Error.Cannot_infer mu_motive_word)` of `mu_motive_of`.
- Edit.  A `None` motive is accepted with a made up one, `m_ind = Some
  n`, one `"_"` per family index, `m_self = "_"` and `m_body =
  Term.Univ Level.zero`.
- Killing line.  The copy's suite printed `NEG mu-no-motive FAIL: the
  message is "the term has type Type 1 and the expected type is Type 0"`,
  `NEG-OK 25/26` and `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed
  `ELIM-SUITE NEG mu-no-motive exit=1 SIDECAR-MISMATCH line=the term has
  type Type 1 and the expected type is Type 0`.  The fixture is still
  refused, but at the universe of the made up motive and not at the
  missing one, so the sidecar line `an elimination at a mu shape needs a
  motive` is carried by the checked rule alone.

### SH-M5 the m_ind equality

- Site.  The copy's lib/rules.ml:1175-1178, the first guard arm of
  `mu_motive_of`.
- Edit.  The arm `| () when not (String.equal mn n) -> Error (...)` is
  removed, so a motive built for a sibling family is not compared with
  the scrutinee family.
- Killing line.  The copy's suite printed `NEG mu-motive-wrong-family
  FAIL: the file checks and the negative expects it to fail`,
  `NEG-OK 25/26` and `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed
  `ELIM-SUITE NEG mu-motive-wrong-family exit=0 SIDECAR-MISMATCH line=`,
  where the sidecar promises `the motive is built for Beta and the
  scrutinee is at Alpha`.

### SH-M6 part two of the criterion

- Site.  The copy's lib/rules.ml:1005-1009, the part two arm of
  `mu_zero_eliminable`, the port of pin check.ml:231.  This is the
  plan's `SH-M1b` (SH-D14).
- Edit.  The `List.for_all` over `ct.Positivity.c_args` is dropped and
  the arm reads `(not ct.Positivity.c_self_rec)`, so a field at quantity
  `Many` still passes the criterion.
- Killing line.  The copy's suite printed `NEG mu-large-elim-nonsub
  FAIL: the file checks and the negative expects it to fail`,
  `NEG-OK 25/26` and `SUITE-KERNEL FAIL`, exit 1.  ELIM-SUITE printed
  `ELIM-SUITE NEG mu-large-elim-nonsub exit=0 SIDECAR-MISMATCH line=`,
  where the sidecar promises `a large elimination out of a proposition
  needs a subsingleton family at Box`.

## Stage I

Three mutations, each on its own fresh copy of the repository made with
`rsync -a --exclude _build --exclude .gatework`, built through the copy's
own dev/dunecho.sh, which printed `OK build: 0 errors, 0 warnings` and
exit 0 for all three (SI-D16).  ROOT was never mutated.  The judge reran
all three at 2026-09-06 12:02, on the copies judge-m1, judge-m2 and
judge-m3 under the session scratch directory.  Each copy ran its own
`_build/default/test/main.exe test` and the stage local checks of
brief 3.8 and 3.11 through the copy's own
`_build/default/bin/kanon.exe check`.  The line numbers below are the
ones of the copy, which are the ROOT numbers before the edit.

### SI-M1 the call order of brief 3.7

- Site.  The copy's surface/elab.ml:1003-1009, the `let* cert =` row
  that calls `Totality.guard_group`, with :1023 and :1047, the branch
  that hands the certificate to `Order.translate`.
- Edit.  `let* cert =` becomes `let cert : Order.t option =` with
  `|> Result.value ~default:None` appended, so the refusal of the guard
  is discarded;  `guarded` is renamed `_guarded` and the dispatch at
  :1047 becomes `(fun (_c : Order.t option) -> plain) cert`, so no
  certificate ever reaches the translation and the guard gates nothing.
- Killing line.  The copy's suite printed `NEG mu-nonstructural FAIL:
  the message is "spin"`, with `NEG mu-rec-guard-order FAIL: the message
  is "grow"`, `NEG-OK 27/31`, `ERASE-NEG-OK 1/4` and `SUITE-KERNEL FAIL`,
  exit 1.  The direct run
  `kanon.exe check test/neg/mu-nonstructural.kan` printed
  `unbound: spin`, exit 1, where the sidecar promises `recursive
  definition spin failed the structural termination guard`, so the
  fixture fails to fail with its own line and SI-G6 and SI-G7 both go
  red.

### SI-M2 the strictness of the order

- Site.  The copy's lib/order.ml:282-288, the `smaller_at` helper of
  `passes`, the port of the status read at
  kan-lang-tot-pin/lib/totality.ml:82-88.
- Edit.  The arm `| Principal | Other -> false` becomes
  `| Principal -> true` and `| Other -> false`, so a self call at an
  argument equal to the scrutinee, which stands at status Principal, is
  read as Smaller and passes.
- Killing line.  The copy's suite printed `NEG mu-rec-nondecreasing
  FAIL: the file checks and the negative expects it to fail`, with
  `NEG-OK 28/31` and `SUITE-KERNEL FAIL`, exit 1.  The direct run
  `kanon.exe check test/neg/mu-rec-nondecreasing.kan` printed no output
  and exit 0, which is the acceptance the sidecar refuses, so SI-G7 goes
  red.

### SI-M3 the mutual rule of brief 3.2

- Site.  The copy's lib/order.ml:482-491, the `rows_at` helper of
  `certify`, which asks every member of the group to pass at the one
  shared position `k` (SI-D7, SI-D24).
- Edit.  `passes ~rule ~group k formals inner` becomes a search
  `try_pos 0` that walks every position of that member and answers the
  first that passes, so each member takes its own decreasing position
  and a sibling call at another argument position is allowed.
- Killing line.  The copy's suite printed `NEG mu-rec-sibling-position
  FAIL: the message is "a structurally recursive definition eliminates
  its recursive argument at the head of its body"`, with
  `ERASE-NEG mu-rec-indexed FAIL: mismatch: a structurally recursive
  definition eliminates its recursive argument at the head of its body`,
  `NEG-OK 30/31`, `ERASE-NEG-OK 3/4` and `SUITE-KERNEL FAIL`, exit 1.
  The guard admits the group the sidecar refuses, and the refusal that
  is printed is the mismatch of `Order.translate`, not the termination
  line of SI-D6, so SI-G7 goes red.  The mutation also breaks the
  indexed positive, which the honest order accepts.
