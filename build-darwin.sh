#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 A38 fork - Darwin / macOS build  (FPC 2.6.2, i386)
#  Usage:  ./build-darwin.sh            build every binary
#          ./build-darwin.sh mis        build a single target
#  Linux/Unix: build.sh   Windows: build-win32.bat
# ------------------------------------------------------------
#  NOTE ON LINKING:
#    Compilation to Mach-O objects works cross-platform (FPC's
#    internal Mach-O assembler, -Amacho - no Xcode needed).  The
#    final LINK step needs a Mach-O linker (Apple's ld64/cctools)
#    and the macOS system libraries.  On a real Mac (or with a
#    cctools-port cross toolchain) this script links a full binary.
#    On a plain Linux box WITHOUT a Mach-O linker, use COMPILE_ONLY=1
#    to stop after producing verified Mach-O objects.
# ------------------------------------------------------------
#    COMPILE_ONLY=1 ./build-darwin.sh     objects only (no link)
#    FPC=/path/to/ppc386 ./build-darwin.sh
#    DARWINUNITS=/path/to/i386-darwin ./build-darwin.sh
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out_darwin/bin"; UNITS="$ROOT/out_darwin/units"
mkdir -p "$BIN" "$UNITS"

FPC="${FPC:-ppc386}"                    # FPC compiler (i386 -> Darwin)
DARWINUNITS="${DARWINUNITS:-}"          # path to the i386-darwin RTL units
COMPILE_ONLY="${COMPILE_ONLY:-0}"       # 1 = stop after Mach-O objects (no link)

# -Amacho forces FPC's INTERNAL Mach-O writer (works without an external
# i386-darwin-as assembler).  -Cn = compile only, do not call the linker.
FPCOPTS=(-Tdarwin -Amacho -Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl
         -FU"$UNITS" -FE"$BIN")
[ -n "$DARWINUNITS" ] && FPCOPTS+=(-Fu"$DARWINUNITS")
[ "$COMPILE_ONLY" = "1" ] && FPCOPTS+=(-Cn)

ALL=(mystic mis mutil mplc mide mbbsutil fidopoll nodespy qwkpoll \
     mystpack install install_make maketheme 109to110)
TARGETS=("$@"); [ ${#TARGETS[@]} -eq 0 ] && TARGETS=("${ALL[@]}")

clean() { find . -name '*.ppu' -delete 2>/dev/null; find . -name '*.o' -delete 2>/dev/null; }

echo "Darwin build (COMPILE_ONLY=$COMPILE_ONLY)"
rc=0
for t in "${TARGETS[@]}"; do
  clean
  if "$FPC" "${FPCOPTS[@]}" "mystic/$t.pas" > "$ROOT/out_darwin/$t.build.log" 2>&1; then
    printf "  OK    %-14s\n" "$t"
  else
    # a link-stage failure on a non-Mac is expected; flag it distinctly
    if grep -qiE "i386-darwin-ld not found|switching to external linking" "$ROOT/out_darwin/$t.build.log"; then
      printf "  COMPILED (no link) %-14s  - Mach-O objects in out_darwin/units\n" "$t"
    else
      printf "  FAIL  %-14s (see out_darwin/%s.build.log)\n" "$t" "$t"
      grep -iE '\bError\b|\bFatal\b' "$ROOT/out_darwin/$t.build.log" | head -2 | sed 's/^/          /'
      rc=1
    fi
  fi
done
exit $rc
