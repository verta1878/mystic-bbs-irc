#!/usr/bin/env bash
# ====================================================================
#  MARC test suite - built-in ZIP archiver + media-tag reader
# ====================================================================
#  Proves marc works end-to-end for the three jobs Mystic needs it for:
#  FidoNet bundling, QWK packets, and FILE_ID.DIZ extraction - plus the
#  media-tag view. Each job is just "pack then unpack and compare", so
#  we never need a live 4MB packet: we synthesise small controlled
#  fixtures and verify the round-trip byte-for-byte.
#
#  Usage:
#    MARC=/path/to/marc ./tests/marc/run.sh
#    (defaults to ./marc or marc on PATH)
#
#  Exit 0 = all pass, non-zero = a test failed.
# ====================================================================
set -u

MARC="${MARC:-}"
if [ -z "$MARC" ]; then
  if   [ -x ./marc ];        then MARC=./marc
  elif command -v marc >/dev/null 2>&1; then MARC=marc
  else echo "FAIL: no marc binary (set MARC=/path/to/marc)"; exit 2; fi
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0

ok()   { echo "  ok   - $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL - $1"; FAIL=$((FAIL+1)); }

echo "MARC test suite (binary: $MARC)"
echo "workdir: $WORK"
echo

# --------------------------------------------------------------------
# 1. ZIP round-trip: pack a file, unpack it, compare
# --------------------------------------------------------------------
echo "[1] ZIP pack/unpack round-trip"
echo "the quick brown fox jumps over the lazy dog" > "$WORK/a.txt"
head -c 20000 /dev/urandom > "$WORK/b.bin" 2>/dev/null || \
  dd if=/dev/zero bs=1000 count=20 2>/dev/null | tr '\0' 'X' > "$WORK/b.bin"

( cd "$WORK" && "$MARC" a pack.zip a.txt b.bin >/dev/null )
[ -f "$WORK/pack.zip" ] && ok "archive created" || bad "archive not created"

mkdir -p "$WORK/out"
( cd "$WORK" && "$MARC" x pack.zip out >/dev/null )
if cmp -s "$WORK/a.txt" "$WORK/out/a.txt"; then ok "a.txt round-trips"; else bad "a.txt differs"; fi
if cmp -s "$WORK/b.bin" "$WORK/out/b.bin"; then ok "b.bin round-trips"; else bad "b.bin differs"; fi

# --------------------------------------------------------------------
# 2. LIST shows the entries
# --------------------------------------------------------------------
echo "[2] ZIP list"
LIST="$( cd "$WORK" && "$MARC" l pack.zip )"
echo "$LIST" | grep -q "a.txt" && ok "list shows a.txt" || bad "list missing a.txt"
echo "$LIST" | grep -q "b.bin" && ok "list shows b.bin" || bad "list missing b.bin"

# --------------------------------------------------------------------
# 3. FILE_ID.DIZ extraction (the exact ExecuteArchive mode-2 use)
# --------------------------------------------------------------------
echo "[3] FILE_ID.DIZ extraction"
printf 'My cool file\nline two of the diz\n' > "$WORK/FILE_ID.DIZ"
( cd "$WORK" && "$MARC" a upload.zip FILE_ID.DIZ a.txt >/dev/null )
mkdir -p "$WORK/diz"
( cd "$WORK" && "$MARC" x upload.zip diz >/dev/null )
if cmp -s "$WORK/FILE_ID.DIZ" "$WORK/diz/FILE_ID.DIZ"; then
  ok "FILE_ID.DIZ extracted intact"
else bad "FILE_ID.DIZ extraction failed"; fi

# --------------------------------------------------------------------
# 4. FidoNet-style bundle: pack a fake .pkt, unpack, compare
#    (marc only compresses; the .pkt itself stays FTS-0001)
# --------------------------------------------------------------------
echo "[4] FidoNet bundle round-trip (.pkt in a ZIP bundle)"
# minimal fake type-2 packet header (58 bytes) + body - content is opaque to marc
dd if=/dev/zero bs=1 count=58 2>/dev/null > "$WORK/0001abcd.pkt"
printf 'PKTBODY-echomail-goes-here' >> "$WORK/0001abcd.pkt"
( cd "$WORK" && "$MARC" a 0001abcd.mo0 0001abcd.pkt >/dev/null )
[ -f "$WORK/0001abcd.mo0" ] && ok "bundle .mo0 created" || bad "bundle not created"
mkdir -p "$WORK/inbound"
( cd "$WORK" && "$MARC" x 0001abcd.mo0 inbound >/dev/null )
if cmp -s "$WORK/0001abcd.pkt" "$WORK/inbound/0001abcd.pkt"; then
  ok ".pkt survives bundle round-trip"
else bad ".pkt corrupted by bundle round-trip"; fi

# --------------------------------------------------------------------
# 5. QWK packet round-trip (.qwk is a ZIP by standard)
# --------------------------------------------------------------------
echo "[5] QWK packet round-trip"
printf 'Producer: MYSTIC\n' > "$WORK/CONTROL.DAT"
dd if=/dev/zero bs=128 count=4 2>/dev/null > "$WORK/MESSAGES.DAT"
( cd "$WORK" && "$MARC" a MYSTIC.QWK CONTROL.DAT MESSAGES.DAT >/dev/null )
mkdir -p "$WORK/qwk"
( cd "$WORK" && "$MARC" x MYSTIC.QWK qwk >/dev/null )
if cmp -s "$WORK/CONTROL.DAT" "$WORK/qwk/CONTROL.DAT" && \
   cmp -s "$WORK/MESSAGES.DAT" "$WORK/qwk/MESSAGES.DAT"; then
  ok "QWK packet round-trips"
else bad "QWK packet round-trip failed"; fi

# --------------------------------------------------------------------
# 6. Media tags (only if a sample is provided; skipped otherwise)
# --------------------------------------------------------------------
echo "[6] media tag view (optional)"
if [ -n "${MARC_MP3:-}" ] && [ -f "${MARC_MP3:-}" ]; then
  OUT="$("$MARC" m "$MARC_MP3")"
  echo "$OUT" | grep -qiE "MP3" && ok "MP3 recognised" || bad "MP3 not recognised"
else
  echo "  skip - set MARC_MP3=/path/to/file.mp3 to test media tags"
fi

# --------------------------------------------------------------------
echo
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
