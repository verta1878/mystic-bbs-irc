#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 A38 fork - OS/2 build  (FPC 2.6.2, i386-os2)
#  Usage:  ./build-os2.sh          build every binary
#          ./build-os2.sh mis      build a single target
#
#  TWO-STAGE BUILD (this is how FPC has always built OS/2):
#    1. COMPILE for i386-os2  - fully cross-platform, done anywhere.
#    2. LINK                  - NATIVE step on OS/2 / eComStation / ArcaOS.
#       FPC's os2 linker is  ld  then  emxbind  (emxbind converts the
#       intermediate a.out to an OS/2 LX .exe and binds the OS/2 DLL
#       imports).  emxbind runs on OS/2 (or DOS), so the final .exe is
#       produced there, not on a Linux host.
#
#  So on a NON-OS/2 host this script does a COMPILE-ONLY pass (-s) to
#  prove the sources are OS/2-clean (14/14).  Run WITHOUT -s on real
#  OS/2 (with the FPC 2.6.2 OS/2 release, which bundles emx + the import
#  libraries) to get runnable .exe files.  See docs/DECISIONS.md
#  (OS/2 target, 2026-07-08) and INSTALL.
#
#  Env:
#    FPC=/path/to/ppc386          the FPC 2.6.2 compiler
#    OS2UNITS="-Fu... -Fu..."     extra unit paths (the cross RTL + packages
#                                 built for os2, if not on the default path)
#    LINK=1                       attempt the real link (only on OS/2, or if
#                                 you have emxbind + import libs on PATH)
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
BIN="$ROOT/out/bin-os2"; UNITS="$ROOT/out/units-os2"
mkdir -p "$BIN" "$UNITS"

FPC="${FPC:-ppc386}"
OS2UNITS="${OS2UNITS:-}"

# -s = compile only, do not call the linker (the default off-OS/2 mode).
# Set LINK=1 to attempt the real ld+emxbind link (native OS/2).
COMPILE_ONLY="-s"
[ "${LINK:-0}" = "1" ] && COMPILE_ONLY=""

# XP prefix points the compiler at the i386-os2- cross tools (as/ld); on
# native OS/2 leave the tools as their plain names (FPC finds them).
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
