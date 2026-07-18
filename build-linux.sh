#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out-linux/bin"; UNITS="$ROOT/out-linux/units"
mkdir -p "$BIN" "$UNITS"
FPC="${FPC:-/home/claude/fpc264irc/bin/ppc386}"
FPCROOT="${FPCROOT:-/home/claude/fpc264irc}"
XTOOLS="$FPCROOT/bin/tools/i386-linux"
XUNITS="$FPCROOT/bin/units/i386-linux"
FPCOPTS=(-Tlinux -Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl
         -FU"$UNITS" -FE"$BIN" -Fl/usr/lib/i386-linux-gnu
         -FD"$XTOOLS" -Fu"$XUNITS")
MARCOPTS=(-Tlinux -Mobjfpc -Fumystic -Fimystic
          -FU"$UNITS" -FE"$BIN" -Fl/usr/lib/i386-linux-gnu
          -FD"$XTOOLS" -Fu"$XUNITS")
PASS=0; FAIL=0
build () {
    local t="$1" mode="${2:-delphi}"
    local src="mystic/${t}.pas" log="out-linux/${t}.build.log"
    [ ! -f "$src" ] && { echo "  SKIP  $t (not found)"; return; }
    if [ "$mode" = "objfpc" ]; then
        "$FPC" "${MARCOPTS[@]}" "$src" >"$log" 2>&1
    else
        "$FPC" "${FPCOPTS[@]}" "$src" >"$log" 2>&1
    fi
    if [ $? -eq 0 ]; then
        echo "  OK    $t  -> out-linux/bin/$t"
        PASS=$((PASS+1))
    else
        err=$(grep "Fatal:" "$log" | head -1)
        echo "  FAIL  $t  ($err)"
        FAIL=$((FAIL+1))
    fi
}
echo "Mystic BBS Linux build ($(date))"
echo "Compiler: $FPC"
echo ""
chmod +x "$XTOOLS"/* "$FPC" 2>/dev/null
for t in mystic mis mutil mplc mide mbbsutil fidopoll nodespy \
         qwkpoll mystpack install install_make maketheme 109to110; do
    build "$t"
done
build marc objfpc
echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ $FAIL -eq 0 ] && echo "ALL LINUX BUILDS PASSED"
