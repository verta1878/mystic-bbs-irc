#!/usr/bin/env bash
# ============================================================
#  make_all_releases.sh - build every platform's release directory.
#
#  Usage:  ./make_all_releases.sh [full|upgrade|both] [out-dir]
#          mode = both (default) | full | upgrade
#
#  Produces, under <out-dir> (default "release"), one directory per target:
#     release/lnx/  mysticlnxfull.zip  mysticlnxupd.zip
#     release/win/  mysticwinfull.zip  mysticwinupd.zip
#     release/mac/  mysticmacfull.zip  mysticmacupd.zip
#     release/os2/  mysticos2full.zip  mysticos2upd.zip
#
#  Compiled binaries land in (all gitignored):
#     Linux out/bin  Win32 out/bin-win  macOS out_darwin/bin  OS/2 out/bin-os2
#
#  macOS needs SDK=/path/to/MacOSX10.6.sdk ; OS/2 needs the emx toolchain on
#  PATH (see docs/os2-linux-toolchain/).
# ============================================================
set -u
cd "$(dirname "$0")"
MODE="${1:-both}"; OUT="${2:-release}"
FPC="${FPC:-ppc386}"
W="${WIN32RTL:-$HOME/fpc262/fpc-2.6.2/rtl/units/i386-win32}"

echo "=== building all releases (mode=$MODE) into $OUT/ ==="

echo "--- Linux ---"
FPC="$FPC" bash build.sh >/dev/null 2>&1 && \
  ./make_release.sh lnx out/bin "$MODE" "$OUT"

echo "--- Win32 ---"
mkdir -p out/bin-win
for t in mystic mis mutil mplc mide mbbsutil fidopoll nodespy qwkpoll \
         mystpack install install_make maketheme 109to110; do
  "$FPC" -Twin32 -Mdelphi -Fumdl -Fumystic -Fimdl -Fimystic -Fomdl \
    -Fu"$W" -FEout/bin-win "mystic/$t.pas" >/dev/null 2>&1
done
./make_release.sh win out/bin-win "$MODE" "$OUT"

if [ -n "${SDK:-}" ]; then
  echo "--- macOS ---"
  SDK="$SDK" bash build-darwin.sh >/dev/null 2>&1 && \
    ./make_release.sh mac out_darwin/bin "$MODE" "$OUT"
else
  echo "--- macOS: skipped (set SDK=/path/to/MacOSX10.6.sdk) ---"
fi

echo "--- OS/2 ---"
if LINK=1 OS2UNITS="${OS2UNITS:-}" bash build-os2.sh >/dev/null 2>&1; then
  ./make_release.sh os2 out/bin-os2 "$MODE" "$OUT"
else
  echo "  OS/2 link failed (emx toolchain on PATH? see docs/os2-linux-toolchain/)"
fi

echo ""
echo "=== $OUT/ tree ==="
find "$OUT" -name '*.zip' | sort | sed 's|^|  |'
