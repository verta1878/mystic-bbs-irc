#!/usr/bin/env bash
# ============================================================
#  make_release.sh - build a PER-TARGET release into its platform directory.
#
#  Usage:  ./make_release.sh <tag> <bin-dir> [full|upgrade|both] [out-dir]
#          tag  = win | lnx | os2 | mac | dos    (the target platform)
#          mode = both (default) | full | upgrade
#
#  LAYOUT - each target gets its own directory under <out-dir> (default
#  "release"), named by the platform tag, holding its FULL install and its
#  UPGRADE bundle:
#
#     release/<tag>/mystic<tag>full.zip   FULL  - install + install_data.mys + docs
#     release/<tag>/mystic<tag>upd.zip   UPGRADE - binaries + docs, no payload
#
#     e.g. release/os2/mysticos2full.zip + release/os2/mysticos2upd.zip
#
#  FULL     : all 14 binaries + install_data.mys + docs + FILE_ID.DIZ "<tag> FULL"
#  UPGRADE  : all 14 binaries + docs + FILE_ID.DIZ "<tag> UPGRADE" (no payload) -
#             a drop-in over an existing install.
#
#  FILE_ID.DIZ is generated from file_id.<tag> with the title's "<tag> BINARIES"
#  replaced by "<tag> FULL"/"<tag> UPGRADE", written CRLF (BBS/DOS convention).
#
#  Examples:
#     ./make_release.sh os2 out/bin-os2            # both -> release/os2/
#     ./make_release.sh win out/bin-win full       # FULL only -> release/win/
#     ./make_release.sh mac out_darwin/bin both dist
# ============================================================
set -e
cd "$(dirname "$0")"

T="$1"; BIN="$2"; MODE="${3:-both}"; OUTROOT="${4:-release}"
[ -z "$T" ] || [ -z "$BIN" ] && {
  echo "usage: $0 <win|lnx|os2|mac|dos> <bin-dir> [full|upgrade|both] [out-dir]"; exit 1; }
case "$MODE" in full|upgrade|both) ;; *) echo "mode = full|upgrade|both"; exit 1;; esac

FID="file_id.$T"
[ -f "$FID" ] || { echo "missing $FID (per-target DIZ template)"; exit 1; }
[ -d "$BIN" ] || { echo "no such bin dir: $BIN"; exit 1; }

# per-target output directory, named by platform tag
TARGDIR="$OUTROOT/$T"
mkdir -p "$TARGDIR"
TARGABS="$(cd "$TARGDIR" && pwd)"

# ---- helper: build one archive in a given mode ----
build_one () {
  local mode="$1" label zipname
  case "$mode" in
    full)    label="FULL";    zipname="mystic${T}full.zip" ;;
    upgrade) label="UPGRADE"; zipname="mystic${T}upd.zip" ;;
  esac

  local STAGE; STAGE="$(mktemp -d)"
  cp -r "$BIN"/. "$STAGE"/
  # strip build intermediates - only runnable binaries + content ship
  find "$STAGE" \( -name '*.o' -o -name '*.ppu' -o -name '*.a' \
                   -o -name '*.s' -o -name '*.out' \) -delete 2>/dev/null || true

  # FILE_ID.DIZ: relabel + force CRLF
  sed "s/$T BINARIES/$T $label/" "$FID" \
    | sed 's/\r$//' | sed 's/$/\r/' > "$STAGE/FILE_ID.DIZ"

  # release docs (already CRLF in repo)
  for extra in whatsnew.txt upgrade.txt; do
    [ -f "mystic/$extra" ] && cp "mystic/$extra" "$STAGE"/
  done
  # payload only in FULL
  [ "$mode" = full ] && [ -f "mystic/install_data.mys" ] && \
    cp "mystic/install_data.mys" "$STAGE"/
  [ -f COPYING ] && cp COPYING "$STAGE"/

  local ARC="$TARGABS/$zipname"
  rm -f "$ARC"
  ( cd "$STAGE" && zip -qr "$ARC" . )
  rm -rf "$STAGE"
  echo "  $mode -> $TARGDIR/$zipname  (DIZ \"$T $label\", payload=$([ $mode = full ] && echo yes || echo no))"
}

echo "Release: $T -> $TARGDIR/"
[ "$MODE" = both ] || [ "$MODE" = full ]    && build_one full
[ "$MODE" = both ] || [ "$MODE" = upgrade ] && build_one upgrade
