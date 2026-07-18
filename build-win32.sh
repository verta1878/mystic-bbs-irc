#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 fork - Win32 cross-build from Linux
#  Produces real PE32 .exe files via i386-win32 cross-linker
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out-win32/bin"; UNITS="$ROOT/out-win32/units"
mkdir -p "$BIN" "$UNITS"
FPC="${FPC:-/home/claude/fpc264irc/bin/ppc386}"
FPCROOT="${FPCROOT:-/home/claude/fpc264irc}"
XTOOLS="$FPCROOT/bin/tools/i386-win32"
XUNITS="$FPCROOT/bin/units/i386-win32"
FPCOPTS=(-Twin32 -Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl
         -FU"$UNITS" -FE"$BIN"
         -XPi386-win32- -FD"$XTOOLS" -Fu"$XUNITS")
MARCOPTS=(-Twin32 -Mobjfpc -Fumystic -Fimystic
          -FU"$UNITS" -FE"$BIN"
          -XPi386-win32- -FD"$XTOOLS" -Fu"$XUNITS")
PASS=0; FAIL=0
build () {
    local t="$1" mode="${2:-delphi}"
    local src="mystic/${t}.pas" log="out-win32/${t}.build.log"
    [ ! -f "$src" ] && { echo "  SKIP  $t (not found)"; return; }
    if [ "$mode" = "objfpc" ]; then
        "$FPC" "${MARCOPTS[@]}" "$src" >"$log" 2>&1
    else
        "$FPC" "${FPCOPTS[@]}" "$src" >"$log" 2>&1
    fi
    if [ $? -eq 0 ]; then
        echo "  OK    $t  -> out-win32/bin/${t}.exe"
        PASS=$((PASS+1))
    else
        err=$(grep "Fatal:" "$log" | head -1)
        echo "  FAIL  $t  ($err)"
        FAIL=$((FAIL+1))
    fi
}
echo "Mystic BBS Win32 cross-build ($(date))"
echo "Compiler: $FPC"
echo "Tools:    $XTOOLS"
echo ""
# chmod tools
chmod +x "$XTOOLS"/* "$FPC" 2>/dev/null
for t in mystic mis mutil mplc mide mbbsutil fidopoll nodespy \
         qwkpoll mystpack install install_make maketheme 109to110; do
    build "$t"
done
build marc objfpc
echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ $FAIL -eq 0 ] && echo "ALL WIN32 BUILDS PASSED"
