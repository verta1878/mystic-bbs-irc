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

FID="mystic/file_id.$T"
[ -f "$FID" ] || { echo "missing $FID (per-target DIZ template)"; exit 1; }
[ -d "$BIN" ] || { echo "no such bin dir: $BIN"; exit 1; }

# Release version string used in archive names: mystic-<VER>-<tag>-<mode>.zip
# Bump this when the fork's alpha changes (e.g. 1.10a40irc). Overridable via env.
VER="${VER:-1.10a38irc}"

# STAMP distinguishes an in-progress import (dated build) from a completed one.
# While still importing an alpha's fixes, leave STAMP as the date (default =
# today, MM-DD-YYYY e.g. 07-10-2026).  Once ALL of that alpha's fixes are
# imported, build with STAMP=FINAL to stamp the release as done:
#   in-progress -> mystic-1.10a38irc-win-full-07-10-2026.zip
#   completed   -> mystic-1.10a38irc-win-full-FINAL.zip
STAMP="${STAMP:-$(date +%m-%d-%Y)}"

# per-target output directory, named by platform tag
TARGDIR="$OUTROOT/$T"
mkdir -p "$TARGDIR"
TARGABS="$(cd "$TARGDIR" && pwd)"

# ---- helper: build one archive in a given mode ----
build_one () {
  local mode="$1" label zipname
  case "$mode" in
    full)    label="FULL";    zipname="mystic-${VER}-${T}-full-${STAMP}.zip" ;;
    upgrade) label="UPGRADE"; zipname="mystic-${VER}-${T}-update-${STAMP}.zip" ;;
  esac

  local STAGE; STAGE="$(mktemp -d)"
  cp -r "$BIN"/. "$STAGE"/
  # strip build intermediates - only runnable binaries + content ship
  find "$STAGE" \( -name '*.o' -o -name '*.ppu' -o -name '*.a' \
                   -o -name '*.s' -o -name '*.out' \) -delete 2>/dev/null || true

  # FILE_ID.DIZ: relabel the title's "<tag> BINARIES" -> "<tag> FULL/UPGRADE",
  # then RE-PAD the title line so the box interior stays a fixed width and the
  # right-hand border '|' remains aligned regardless of label length.
  # Interior width is taken from the top border line ('.---...---.').
  awk -v tag="$T" -v label="$label" -v stamp="$STAMP" '
    {
      line = $0
      sub(/\r$/, "", line)                                 # normalise CRLF FIRST
    }
    NR==1 { inner = length(line) - 2 }                     # width between the dots
    {
      if (line ~ ("\\| .*" tag " BINARIES \\|")) {
        # rebuild the title line at the exact interior width
        content = line
        sub(/^\| /, "", content); sub(/ \|$/, "", content)  # strip borders
        sub(tag " BINARIES", tag " " label, content)        # swap the label
        # pad or trim the content to (inner-2) so " " + content + " " == inner
        w = inner - 2
        while (length(content) < w) content = content " "
        content = substr(content, 1, w)
        line = "| " content " |"
      }
      printf "%s\r\n", line
    }
    END {
      # last line = release date (or FINAL when the alpha import is complete)
      printf " Released: %s\r\n", stamp
    }
  ' "$FID" > "$STAGE/FILE_ID.DIZ"

  # release docs (already CRLF in repo)
  for extra in whatsnew.txt upgrade.txt; do
    [ -f "mystic/$extra" ] && cp "mystic/$extra" "$STAGE"/
  done
  # per-version update notes: updatea40.txt (and any future updatea41.txt, ...)
  for u in mystic/update*.txt; do
    [ -f "$u" ] && cp "$u" "$STAGE"/
  done
  # payload only in FULL
  [ "$mode" = full ] && [ -f "mystic/install_data.mys" ] && \
    cp "mystic/install_data.mys" "$STAGE"/
  [ -f COPYING ] && cp COPYING "$STAGE"/

  # Package inside a top-level folder named after the archive, so extracting the
  # FULL and UPDATE archives side by side does NOT merge their loose files.
  local FOLDER="${zipname%.zip}"
  local ARC="$TARGABS/$zipname"
  rm -f "$ARC"
  local WRAP; WRAP="$(mktemp -d)"
  mkdir -p "$WRAP/$FOLDER"
  cp -r "$STAGE"/. "$WRAP/$FOLDER"/
  ( cd "$WRAP" && zip -qr "$ARC" "$FOLDER" )
  rm -rf "$STAGE" "$WRAP"
  echo "  $mode -> $TARGDIR/$zipname  (folder: $FOLDER/, DIZ \"$T $label\", payload=$([ $mode = full ] && echo yes || echo no))"
}

echo "Release: $T -> $TARGDIR/"
[ "$MODE" = both ] || [ "$MODE" = full ]    && build_one full
[ "$MODE" = both ] || [ "$MODE" = upgrade ] && build_one upgrade
