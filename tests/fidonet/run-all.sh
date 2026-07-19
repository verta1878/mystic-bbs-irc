#!/usr/bin/env bash
# Run all FidoNet test suites
DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0; TOTAL_FAIL=0; TOTAL=0

for test in test-pkt-header test-echomail-import test-binkp-fts1026 test-record-offsets test-fts-compliance test-tic-tosser; do
  echo ""
  bash "$DIR/${test}.sh"
  RC=$?
  if [ $RC -ne 0 ]; then
    TOTAL_FAIL=$((TOTAL_FAIL+1))
  else
    TOTAL_PASS=$((TOTAL_PASS+1))
  fi
  TOTAL=$((TOTAL+1))
done

echo ""
echo "================================================================"
echo " FidoNet Test Summary: $TOTAL_PASS/$TOTAL suites passed"
echo "================================================================"
[ "$TOTAL_FAIL" -gt 0 ] && { echo "SOME SUITES FAILED"; exit 1; }
echo "ALL FIDONET TESTS PASSED"; exit 0
