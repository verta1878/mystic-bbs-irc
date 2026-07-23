#!/usr/bin/env bash
# Common test functions for fidonet test suite
BASEDIR="$(cd "$(dirname "$0")/../.." && pwd)"
PKTDIR="$(cd "$(dirname "$0")" && pwd)"
PKT="$PKTDIR/05E46980.PKT"
TIC="$PKTDIR/PX50650A.TIC"

# Handle both: raw files or zipped
if [ ! -f "$PKT" ] && [ -f "$PKTDIR/05E46980.zip" ]; then
  unzip -q -o "$PKTDIR/05E46980.zip" -d "$PKTDIR/" 2>/dev/null
fi
if [ ! -f "$TIC" ] && [ -f "$PKTDIR/PX50650A.zip" ]; then
  unzip -q -o "$PKTDIR/PX50650A.zip" -d "$PKTDIR/" 2>/dev/null
fi

PASS=0; FAIL=0; TOTAL=0
pass () { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); echo "  PASS: $1"; }
fail () { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); echo "  FAIL: $1"; }

results () {
  echo ""
  echo "================================================================"
  echo " Results: $PASS passed, $FAIL failed out of $TOTAL tests"
  echo "================================================================"
  [ "$FAIL" -gt 0 ] && { echo "FAILED"; return 1; }
  echo "ALL TESTS PASSED"; return 0
}
