#!/usr/bin/env bash
# ============================================================
#  make_release.sh - build a PER-TARGET release archive.
#  Usage:  ./make_release.sh <tag> <bin-dir> [out-dir]
#          tag = win | lnx | os2 | mac | dos
#
#  There are 6 per-target DIZ files in the repo root, each with its
#  target name already in the "xxx BINARIES" slot:
#    file_id.win  file_id.lnx  file_id.os2
#    file_id.mac  file_id.dos
#
#  This script copies file_id.<tag> into the archive RENAMED to
#  FILE_ID.DIZ - the name a Mystic file base reads.
#
#  Per sysop: one archive PER TARGET (never a combined file); each
#  archive carries only its own target's DIZ.
#
#  Example:
#    ./build-os2.sh                      # produces out/bin-os2/*
#    ./make_release.sh os2 out/bin-os2   # -> release/mystic-a38-os2.zip
# ============================================================
set -e
cd "$(dirname "$0")"

T="$1"; BIN="$2"; OUT="${3:-release}"
[ -z "$T" ] || [ -z "$BIN" ] && { echo "usage: $0 <win|lnx|os2|mac|dos> <bin-dir> [out-dir]"; exit 1; }

FID="file_id.$T"
[ -f "$FID" ] || { echo "missing $FID (per-target DIZ)"; exit 1; }
[ -d "$BIN" ] || { echo "no such bin dir: $BIN"; exit 1; }

mkdir -p "$OUT"
STAGE="$(mktemp -d)"
cp -r "$BIN"/. "$STAGE"/
cp "$FID" "$STAGE/FILE_ID.DIZ"          # file_id.<tag> -> FILE_ID.DIZ

# Installer content + release docs that ship with every target (see the
# release layout: install.exe, install_data.mys, file_id.diz, whatsnew.txt,
# upgrade.txt).  These live in mystic/ and travel with all targets.
for extra in install_data.mys whatsnew.txt upgrade.txt; do
  [ -f "mystic/$extra" ] && cp "mystic/$extra" "$STAGE"/
done

[ -f COPYING ] && cp COPYING "$STAGE"/  # GPL text travels with binaries

ARCABS="$(cd "$OUT" && pwd)/mystic-a38-$T.zip"
rm -f "$ARCABS"
( cd "$STAGE" && zip -qr "$ARCABS" . )
rm -rf "$STAGE"

echo "Release: $ARCABS"
echo "  (FILE_ID.DIZ from $FID)"
unzip -l "$ARCABS" | awk 'NR>3 && $4 {print "  "$4}' | grep -v '^  ----' | head
