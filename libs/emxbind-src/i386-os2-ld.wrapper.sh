#!/bin/bash
REALLD=/home/claude/os2tools/xbin/bin/i386-aout-ld
TXTBASE=0x10000
OUT="a.out"; i=0; ARGS=("$@")
while [ $i -lt ${#ARGS[@]} ]; do
  [ "${ARGS[$i]}" = "-o" ] && OUT="${ARGS[$((i+1))]}"
  i=$((i+1))
done
"$REALLD" --oformat a.out-emx -Ttext $TXTBASE "$@" 2>/dev/null
TS=$(od -An -t u4 -j 4 -N 4 "$OUT" 2>/dev/null | tr -d ' ')
if [ -n "$TS" ] && [ "$TS" -gt 0 ] 2>/dev/null; then
  DB=$(python3 -c "ts=$TS; tb=0x10000; print('0x%x' % ((((tb+ts)-1)&~0xffff)+0x10000))")
  exec "$REALLD" --oformat a.out-emx -Ttext $TXTBASE -Tdata $DB "$@"
else
  exec "$REALLD" --oformat a.out-emx -Ttext $TXTBASE "$@"
fi
