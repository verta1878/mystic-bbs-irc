#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 A38 fork - OS/2 build  (FPC 2.6.2, i386-os2)
#  Usage:  ./build-os2.sh            compile every binary (compile-only)
#          LINK=1 ./build-os2.sh     compile + LINK to LX .exe (full build)
#          ./build-os2.sh mis        build a single target
#
#  TWO-STAGE BUILD:
#    1. COMPILE for i386-os2  - fully cross-platform, done anywhere.
#    2. LINK                  - ld then emxbind (emxbind converts the
#       intermediate a.out to an OS/2 LX .exe and binds the OS/2 DLL imports).
#
#  This link step NOW RUNS ON LINUX using the self-hosted emx cross-toolchain
#  (patched binutils with the a.out-emx target + emxbind Linux port + emxl.exe
#  + the i386-os2-ld data-alignment wrapper).  Build that toolchain from
#  libs/os2-linux-toolchain.zip and put its bin/ on PATH; then LINK=1 produces
#  runnable OS/2 LX .exe files on Linux.  Full details + reproduction recipe:
#  docs/os2-linux-toolchain/ (TECHNICAL-REFERENCE.md, BUILD-ON-UBUNTU-24.04.md).
#
#  Default (no LINK=1) is a COMPILE-ONLY pass (-s), so the script is safe on a
#  host without the toolchain and still proves the sources are OS/2-clean.
#  It also works natively on OS/2 (FPC 2.6.2 OS/2 release bundles emx).
#
#  Env:
#    FPC=/path/to/ppc386          the FPC 2.6.2 compiler
#    OS2UNITS="-Fu... -Fu..."     extra unit paths (cross RTL + packages for os2)
#    LINK=1                       do the real ld+emxbind link (Linux or OS/2)
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out/bin-os2"; UNITS="$ROOT/out/units-os2"
mkdir -p "$BIN" "$UNITS"

FPC="${FPC:-ppc386}"
OS2UNITS="${OS2UNITS:-}"

# -s = compile only, do not call the linker.
# Set LINK=1 to do the real ld+emxbind link.  This now works ON LINUX using the
# self-hosted emx cross-toolchain (patched i386-aout-ld with the a.out-emx
# target + i386-os2-ld wrapper + i386-os2-emxbind + emxl.exe), built from
# libs/os2-linux-toolchain.zip - see docs/os2-linux-toolchain/.  It also works
# natively on OS/2.  Default remains compile-only so the script is safe without
# the toolchain installed.
COMPILE_ONLY="-s"
[ "${LINK:-0}" = "1" ] && COMPILE_ONLY=""

# XP prefix points the compiler at the i386-os2- cross tools (as/ld/emxbind);
# on native OS/2 leave the tools as their plain names (FPC finds them).
XP="-XPi386-os2-"
[ "${LINK:-0}" = "1" ] && [ "$(uname -s 2>/dev/null)" = "OS/2" ] && XP=""

# shellcheck disable=SC2086
FPCOPTS="-Tos2 $XP -Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl \
  $OS2UNITS -FU$UNITS -FE$BIN $COMPILE_ONLY"

ALL="mystic mis mutil mplc mide mbbsutil fidopoll nodespy qwkpoll \
     mystpack install install_make maketheme 109to110"
TARGETS="$*"; [ -z "$TARGETS" ] && TARGETS="$ALL"

clean() { find . -name '*.ppu' -delete 2>/dev/null; find . -name '*.o' -delete 2>/dev/null; }

if [ -z "$COMPILE_ONLY" ]; then
  echo "OS/2 build: FULL (compile + link).  Requires emxbind + OS/2 import libs."
else
  echo "OS/2 build: COMPILE-ONLY (cross).  Link natively on OS/2 (see header)."
fi

rc=0
for t in $TARGETS; do
  clean
  # shellcheck disable=SC2086
  if "$FPC" $FPCOPTS "mystic/$t.pas" > "$ROOT/out/$t.os2.log" 2>&1; then
    printf "  OK    %-14s\n" "$t"
  else
    printf "  FAIL  %-14s (see out/%s.os2.log)\n" "$t" "$t"
    grep -iE '\bError\b|\bFatal\b' "$ROOT/out/$t.os2.log" | head -2 | sed 's/^/          /'
    rc=1
  fi
done
exit $rc
