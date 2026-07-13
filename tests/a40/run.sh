#!/usr/bin/env bash
# ==========================================================================
#  A40 import - deferred compile/verify tests
#
#  Run AFTER the A40 import is complete (kept out of the import loop to save
#  build resources).  Verifies the anchor is intact and the A40-touched units
#  compile clean.
#
#  Usage:
#    ./tests/a40/run.sh
#    FPC=/path/to/ppc386 ./tests/a40/run.sh
#
#  The compiler defaults to `ppc386` on PATH.  The 2.6.4irc compiler in
#  Default compiler: libs/fpc264irc.tar.gz r3 (unpack, point FPC= at bin/ppc386).
# ==========================================================================
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FPC="${FPC:-ppc386}"
TDIR="$ROOT/tests/a40"
OUT="$(mktemp -d)"
PASS=0; FAIL=0

hdr(){ echo ""; echo "=== $* ==="; }
ok(){  echo "  PASS: $*"; PASS=$((PASS+1)); }
no(){  echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

command -v "$FPC" >/dev/null 2>&1 || { echo "no compiler: $FPC (set FPC=)"; exit 2; }

CMN="-Tlinux -Mdelphi -Fu$ROOT/mdl -Fu$ROOT/mystic -Fi$ROOT/mdl -Fi$ROOT/mystic -FE$OUT"

# 1. anchor check (compiles + runs)
hdr "1. record anchors (SizeOf must be unchanged)"
if "$FPC" $CMN "$TDIR/check_anchors.pas" >"$OUT/anchor.log" 2>&1 && "$OUT/check_anchors"; then
  ok "anchors intact"
else
  no "anchor check failed (see $OUT/anchor.log)"; grep -iE "error|mismatch|fail" "$OUT/anchor.log" | head
fi

# 2. compile the A40-touched units (compile-only, -Cn)
hdr "2. A40-touched units compile"
for u in bbs_cfg_echomail mutil_echoexport bbs_database mutil_common mutil_echofix; do
  if "$FPC" $CMN -Cn "$ROOT/mystic/$u.pas" >"$OUT/$u.log" 2>&1 && [ -f "$OUT/$u.o" ]; then
    ok "$u.pas"
  else
    no "$u.pas (see $OUT/$u.log)"; grep -iE "error|fatal" "$OUT/$u.log" | grep -vi deprecated | head -3
  fi
done

# 3. logstamp format codes (A40 configurable log timestamp)
hdr "3. logstamp format codes (A40)"
if "$FPC" $CMN "$TDIR/check_logstamp.pas" >"$OUT/logstamp.log" 2>&1 && "$OUT/check_logstamp"; then
  ok "logstamp format codes render correctly"
else
  no "logstamp check failed (see $OUT/logstamp.log)"; grep -iE "error|mismatch|fail" "$OUT/logstamp.log" | head
fi

echo ""
echo "=== summary: $PASS passed, $FAIL failed ==="
echo "(logs in $OUT)"
[ "$FAIL" -eq 0 ]
