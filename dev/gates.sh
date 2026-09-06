#!/bin/zsh
# dev/gates.sh
# The M0 gate battery:  every leg of plan section 9, in the order the
# plan writes them.  Example:
#   zsh /Users/oobi/Documents/kanon/dev/gates.sh
#
# Each leg prints one PASS or FAIL line.  A FAIL adds the leg's captured
# output under its line.  BUILD is the one leg that ends the run, because
# every later leg reads the build.  Every other leg runs even when an
# earlier one failed, so one run names every failing leg (SE-D7).  After
# the last leg the script prints the MEASURE block, one line per leg in
# the order above, then GATES-OK and exit 0, or GATES-FAIL and exit 1.
#
# SA-D7: the root comes from this script's own path, so a copy of the
# repository under a scratch directory gates itself.
#
# The script also runs one leg alone, which is how the watchdog wraps a
# leg whose body is a shell function:
#   zsh dev/gates.sh --leg e2e

set -u

# The user shell startup files add a chpwd hook that reads an unset
# parameter.  Under set -u that hook fails and cd inherits its non-zero
# status, so the hooks are cleared before any cd.
chpwd_functions=()
unfunction chpwd 2>/dev/null

# EPOCHREALTIME carries microseconds, which is the resolution gate_timed
# reports in milliseconds (SE-D6).
zmodload zsh/datetime

SELF=${0:A}
ROOT=${0:A:h}/..
ROOT=${ROOT:A}
DRIVER=$ROOT/_build/default/bin/kanon.exe
SPINE=$ROOT/examples/m0-spine.kan
WORK=$ROOT/.gatework/gates
MEASURE_FILE=$WORK/measure.txt

# The pin worktree is read, never written.  It sits beside the repository
# by default, and the caller may name another path.
PIN_WORKTREE=${KANON_PIN_WORKTREE:-/Users/oobi/Documents/kan-lang-tot-pin}

# The M0-TIME bound in milliseconds.  Plan section 9 names the bound and
# correction C1 ratifies it at 150, with the resolution in milliseconds.
# No agent moves this number.
M0_TIME_MS=150

# The watchdog.  GNU coreutils ships timeout as gtimeout on stock macOS.
watchdog=""
if command -v timeout > /dev/null 2>&1; then
  watchdog=timeout
elif command -v gtimeout > /dev/null 2>&1; then
  watchdog=gtimeout
fi

if [[ -z $watchdog ]]; then
  print -r -- "FAIL-WATCHDOG (no timeout or gtimeout on PATH)"
  print -r -- "GATES-FAIL"
  exit 1
fi

# The named tiers, in seconds.  A tier is a hang ceiling, not a budget:
# a leg that grows from one second to nine stays green at FAST and shows
# the growth in the MEASURE block.  These four lines hold every numeric
# watchdog literal in this file.
FAST=10
MED=30
SLOW=120
SUITE=300

# gate_timed TIER NAME CMD...
# Runs one leg under the named tier, records the elapsed wall time in
# milliseconds, and forwards the leg's output and exit code unchanged.
# It adds no policy:  a green leg stays green and a red leg stays red.
gate_timed () {
  local tier=$1
  local name=$2
  shift 2
  local seconds=${(P)tier}
  local t0=$EPOCHREALTIME
  local out
  out=$("$watchdog" "$seconds" "$@" 2>&1)
  local code=$?
  local t1=$EPOCHREALTIME
  printf 'MEASURE %s tier=%s elapsed_ms=%.3f exit=%d\n' \
    "$name" "$tier" "$(( (t1 - t0) * 1000 ))" "$code" >> $MEASURE_FILE
  print -r -- "$out"
  return $code
}

# --- the leg bodies that need more than one command -------------------
#
# Each one prints its own PASS or FAIL line, because its verdict line
# carries a value.  The battery below runs them through the watchdog as
# "zsh dev/gates.sh --leg NAME".

# AXIOMS.  b08 postulates one name and the spine postulates none, so the
# leg reads both ends of the disclosure (SE-D11).
leg_axioms () {
  local b08=$ROOT/test/fixtures/b08-axiom-disclosure.kan
  local out1 code1 out2 code2
  out1=$($DRIVER axioms $b08 2>&1)
  code1=$?
  out2=$($DRIVER axioms $SPINE 2>&1)
  code2=$?
  if [[ $code1 -eq 0 && $out1 == "Bit" && $code2 -eq 0 && -z $out2 ]]; then
    print -r -- "PASS AXIOMS"
    return 0
  fi
  print -r -- "b08 exit=$code1 out=[$out1]"
  print -r -- "spine exit=$code2 out=[$out2]"
  print -r -- "FAIL AXIOMS"
  return 1
}

# M0-E2E.  The spine goes through check, emit, wasm-opt, the kernel and
# the two hosts, and the three answers must agree with the promise line
# the spine writes at its top.
leg_e2e () {
  local dir=$WORK/e2e
  rm -rf $dir
  mkdir -p $dir
  local out code
  out=$($DRIVER check $SPINE 2>&1)
  code=$?
  if [[ $code -ne 0 ]]; then
    print -r -- "check exit=$code out=[$out]"
    print -r -- "FAIL M0-E2E"
    return 1
  fi
  out=$($DRIVER emit $SPINE -o $dir/m0-spine.wasm --export main 2>&1)
  code=$?
  if [[ $code -ne 0 ]]; then
    print -r -- "emit exit=$code out=[$out]"
    print -r -- "FAIL M0-E2E"
    return 1
  fi
  out=$(wasm-opt $dir/m0-spine.wasm -S -o $dir/m0-spine.wat \
    --enable-gc --enable-reference-types --enable-tail-call \
    --enable-exception-handling 2>&1)
  code=$?
  if [[ $code -ne 0 ]]; then
    print -r -- "wasm-opt exit=$code out=[$out]"
    print -r -- "FAIL M0-E2E"
    return 1
  fi
  local kernel kcode hosts hcode promise lines
  kernel=$($DRIVER run $SPINE --export main --host kernel 2>&1)
  kcode=$?
  hosts=$($DRIVER run $SPINE --export main --host both 2>&1)
  hcode=$?
  promise=$(rg -N -o -- '-- main is [0-9]+' $SPINE | head -1 | awk '{ print $4 }')
  lines=$(wc -l < $SPINE | tr -d ' ')
  if [[ $kcode -eq 0 && $hcode -eq 0 && -n $promise && $kernel == $hosts \
    && $kernel == $promise && $lines -ge 200 ]]; then
    print -r -- "PASS M0-E2E main=$kernel"
    return 0
  fi
  print -r -- "kernel exit=$kcode out=[$kernel]"
  print -r -- "hosts exit=$hcode out=[$hosts]"
  print -r -- "promise=[$promise] lines=$lines"
  print -r -- "FAIL M0-E2E"
  return 1
}

# M0-TIME.  bench.sh times the driver's whole run path, check, erase,
# emit, node and wasmtime.  wasm-opt is a step of M0-E2E and stays
# outside this measurement (SE-D9).
leg_time () {
  local bench code median verdict
  bench=$(zsh $ROOT/dev/bench.sh m0_e2e \
    "$DRIVER run $SPINE --export main --host both" 2>&1)
  code=$?
  print -r -- "$bench"
  if [[ $code -ne 0 ]]; then
    print -r -- "FAIL M0-TIME"
    return 1
  fi
  median=$(print -r -- "$bench" | awk '{ for (i = 1; i <= NF; i = i + 1) { if (index($i, "median_ms=") == 1) { print substr($i, 11) } } }')
  verdict=$(awk -v m="$median" -v b="$M0_TIME_MS" 'BEGIN { print (m + 0 <= b + 0) ? "PASS" : "FAIL" }')
  print -r -- "$verdict M0-TIME median_ms=$median bound_ms=$M0_TIME_MS"
  if [[ $verdict == PASS ]]; then
    return 0
  fi
  return 1
}

# M0-RATIO.  The numerator is the kernel suite of this tree and the
# denominator is tot's warm kernel suite, so both sides of the ratio are
# the same command on the two trees (SE-D10).  Correction C2 makes the
# ratio informational at M0:  only a bench error or an unreadable
# denominator fails this leg.
leg_ratio () {
  local bench code kanon tot tcode ratio
  bench=$(zsh $ROOT/dev/bench.sh m0_ratio \
    "$ROOT/_build/default/test/main.exe $ROOT/test" 2>&1)
  code=$?
  print -r -- "$bench"
  if [[ $code -ne 0 ]]; then
    print -r -- "FAIL M0-RATIO"
    return 1
  fi
  kanon=$(print -r -- "$bench" | awk '{ for (i = 1; i <= NF; i = i + 1) { if (index($i, "median_ms=") == 1) { print substr($i, 11) } } }')
  tot=$(/opt/homebrew/bin/python3 -P -c 'import json, sys; print("{0:.3f}".format(json.load(open(sys.argv[1]))["tot_suite_kernel_warm_ms"]["median"]))' $ROOT/dev/denominators.json 2>&1)
  tcode=$?
  if [[ $tcode -ne 0 ]]; then
    print -r -- "denominator exit=$tcode out=[$tot]"
    print -r -- "FAIL M0-RATIO"
    return 1
  fi
  ratio=$(awk -v k="$kanon" -v t="$tot" 'BEGIN { printf "%.3f\n", (t + 0 > 0) ? (k + 0) / (t + 0) : 0 }')
  print -r -- "MEASURE M0-RATIO kanon_ms=$kanon tot_ms=$tot ratio=$ratio"
  print -r -- "PASS M0-RATIO ratio=$ratio"
  return 0
}

# DENOMINATORS.  shasum reads the row of DENOMINATORS.sha256 relative to
# dev/, so the check runs inside that directory.
leg_denominators () {
  local out code
  out=$(cd $ROOT/dev && shasum -a 256 -c DENOMINATORS.sha256 2>&1)
  code=$?
  if [[ $code -eq 0 && $out == "denominators.json: OK" ]]; then
    print -r -- "$out"
    print -r -- "PASS DENOMINATORS"
    return 0
  fi
  print -r -- "shasum exit=$code out=[$out]"
  print -r -- "FAIL DENOMINATORS"
  return 1
}

# PIN.  The PIN file, the vendored submodule and the pin worktree name
# one sha, and the worktree carries no change.  Every command reads;
# --no-optional-locks keeps git from writing an index in the worktree.
leg_pin () {
  local pinfile vendor worktree porcelain
  pinfile=$(cat $ROOT/PIN 2>&1 | tr -d ' \t\n')
  vendor=$(git -C $ROOT/vendor/tot --no-optional-locks rev-parse --short HEAD 2>&1)
  worktree=$(git -C $PIN_WORKTREE --no-optional-locks rev-parse --short HEAD 2>&1)
  porcelain=$(git -C $PIN_WORKTREE --no-optional-locks status --porcelain 2>&1)
  if [[ $pinfile == $vendor && $vendor == $worktree && -z $porcelain ]]; then
    print -r -- "PASS PIN sha=$pinfile"
    return 0
  fi
  print -r -- "PINfile=$pinfile vendor=$vendor worktree=$worktree"
  print -r -- "pin-porcelain=[$porcelain]"
  print -r -- "FAIL PIN"
  return 1
}

mkdir -p $WORK || exit 9

# One leg alone, which is how the watchdog reaches a leg body.
if [[ $# -ge 2 && $1 == "--leg" ]]; then
  case $2 in
    axioms) leg_axioms; exit $? ;;
    e2e) leg_e2e; exit $? ;;
    time) leg_time; exit $? ;;
    ratio) leg_ratio; exit $? ;;
    denominators) leg_denominators; exit $? ;;
    pin) leg_pin; exit $? ;;
    *) print -r -- "gates: unknown leg $2"; exit 64 ;;
  esac
fi

if [[ $# -ne 0 ]]; then
  print -r -- "usage: zsh dev/gates.sh [--leg NAME]"
  exit 64
fi

: > $MEASURE_FILE || exit 9
fail=0

# leg TIER NAME ORACLE CMD...
#   ORACLE is a ripgrep pattern that the leg's output must hold when the
#   leg exits 0.  The word SELF means the leg prints its own verdict
#   line, because that line carries a value, and its whole output
#   belongs on stdout.
leg () {
  local tier=$1
  local name=$2
  local oracle=$3
  shift 3
  local out code
  out=$(gate_timed $tier $name "$@")
  code=$?
  if [[ $oracle == "SELF" ]]; then
    print -r -- "$out"
    if [[ $code -eq 0 ]]; then
      return 0
    fi
    if ! print -r -- "$out" | rg -q -- "^FAIL $name"; then
      print -r -- "FAIL $name"
    fi
    fail=1
    return 1
  fi
  if [[ $code -eq 0 ]] && print -r -- "$out" | rg -q -- "$oracle"; then
    print -r -- "PASS $name"
    return 0
  fi
  print -r -- "FAIL $name"
  print -r -- "$out"
  fail=1
  return 1
}

# The legs, in the order of plan section 9.  BUILD ends the run when it
# fails, because every later leg reads the build it makes.
if ! leg SLOW BUILD '0 errors, 0 warnings' zsh $ROOT/dev/dunecho.sh build; then
  print -r -- ""
  cat $MEASURE_FILE
  print -r -- ""
  print -r -- "GATES-FAIL"
  exit 1
fi

leg MED CARRY '^CARRY-OK$' zsh $ROOT/dev/carry-check.sh
leg FAST R0-COUNT '^R0-COUNT OK$' zsh $ROOT/dev/r0-count.sh
leg FAST R0-AUDIT '^R0-AUDIT OK$' zsh $ROOT/dev/r0-audit.sh
leg SUITE SUITE-KERNEL '^SUITE-KERNEL OK$' \
  $ROOT/_build/default/test/main.exe $ROOT/test
leg SUITE SUITE-WASM '^SUITE-WASM OK$' \
  $ROOT/_build/default/test/wasm.exe $ROOT/test
leg FAST ENCODER-SUBSET '^ENCODER-SUBSET OK$' \
  zsh $ROOT/dev/encoder-subset.sh $ROOT
leg MED AXIOMS SELF zsh $SELF --leg axioms
leg SLOW M0-E2E SELF zsh $SELF --leg e2e
leg SLOW M0-TIME SELF zsh $SELF --leg time
leg SLOW M0-RATIO SELF zsh $SELF --leg ratio
leg FAST TRUSTED-LINES '^TRUSTED-LINES kernel=[0-9]+/[0-9]+ encoder=[0-9]+/[0-9]+ OK$' \
  zsh $ROOT/dev/trusted-lines.sh $ROOT
leg MED DENOMINATORS SELF zsh $SELF --leg denominators
leg MED HOUSE '^HOUSE OK$' zsh $ROOT/dev/house.sh $ROOT
leg FAST PIN SELF zsh $SELF --leg pin

print -r -- ""
cat $MEASURE_FILE
print -r -- ""

if [[ $fail -eq 0 ]]; then
  print -r -- "GATES-OK"
  exit 0
fi

print -r -- "GATES-FAIL"
exit 1
