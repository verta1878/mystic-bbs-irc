#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 A38 fork - Linux/Unix build  (FPC 2.6.2, i386)
#  Usage:  ./build.sh            build every binary
#          ./build.sh mis        build a single target
#  Windows builds: use build-win32.bat (this is bash-only).
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out/bin"; UNITS="$ROOT/out/units"
mkdir -p "$BIN" "$UNITS"

FPC="${FPC:-fpc}"     # override with FPC=/path/to/ppc386 if needed
# fcl-net (cnetdb) is needed by the MIS socket resolver; a full FPC install
# has it on the unit path automatically. Add -Fu paths here if yours doesn't.
FPCOPTS=(-Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl -FU"$UNITS" -FE"$BIN")

ALL=(mystic mis mutil mplc mide mbbsutil fidopoll nodespy qwkpoll \
     mystpack install install_make maketheme 109to110)
TARGETS=("$@"); [ ${#TARGETS[@]} -eq 0 ] && TARGETS=("${ALL[@]}")

clean() { find . -name '*.ppu' -delete 2>/dev/null; find . -name '*.o' -delete 2>/dev/null; }

rc=0
for t in "${TARGETS[@]}"; do
  clean
  if "$FPC" "${FPCOPTS[@]}" "mystic/$t.pas" > "$ROOT/out/$t.build.log" 2>&1; then
    printf "  OK    %-14s -> out/bin/%s\n" "$t" "$t"
  else
    printf "  FAIL  %-14s (see out/%s.build.log)\n" "$t" "$t"
    grep -iE '\bError\b|\bFatal\b' "$ROOT/out/$t.build.log" | head -2 | sed 's/^/          /'
    rc=1
  fi
done
exit $rc
