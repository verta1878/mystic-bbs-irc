#!/usr/bin/env bash
# Item 4: Record offset verification — maps every byte to record fields
source "$(dirname "$0")/common.sh"

echo "================================================================"
echo " test-record-offsets: Byte-level field mapping"
echo " Maps PKT bytes to RecPKTHeader / RecPKTMessageHdr"
echo "================================================================"
echo ""

echo "--- RecPKTHeader (58 bytes) ---"
VAL=$(od -A n -t u2 -j 0 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 158 ] && pass "Offset 0: OrigNode = 158" || fail "OrigNode = $VAL"

VAL=$(od -A n -t u2 -j 2 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 800 ] && pass "Offset 2: DestNode = 800" || fail "DestNode = $VAL"

VAL=$(od -A n -t u2 -j 16 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 0 ] && pass "Offset 16: Baud = 0" || fail "Baud = $VAL"

VAL=$(od -A n -t u2 -j 18 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 2 ] && pass "Offset 18: PKTType = 2" || fail "PKTType = $VAL"

VAL=$(od -A n -t u1 -j 24 -N 1 "$PKT" | tr -d ' ')
[ "$VAL" -eq 17 ] && pass "Offset 24: ProdCode = 17 (Byte)" || fail "ProdCode = $VAL"

VAL=$(od -A n -t u1 -j 25 -N 1 "$PKT" | tr -d ' ')
[ "$VAL" -eq 3 ] && pass "Offset 25: ProdRev = 3 (Byte)" || fail "ProdRev = $VAL"

VAL=$(od -A n -t u2 -j 34 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 1 ] && pass "Offset 34: OrigZone = 1" || fail "OrigZone = $VAL"

VAL=$(od -A n -t u2 -j 36 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 1 ] && pass "Offset 36: DestZone = 1" || fail "DestZone = $VAL"

VAL=$(od -A n -t u2 -j 46 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 1 ] && pass "Offset 46: OrigZone2 = 1" || fail "OrigZone2 = $VAL"

VAL=$(od -A n -t u2 -j 50 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 0 ] && pass "Offset 50: OrigPoint = 0" || fail "OrigPoint = $VAL"

VAL=$(od -A n -t u2 -j 52 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 0 ] && pass "Offset 52: DestPoint = 0" || fail "DestPoint = $VAL"

grep -q "RecPKTHeader = Record" "$BASEDIR/mystic/mutil_echocore.pas" && pass "RecPKTHeader defined" || fail "Missing"

echo ""
echo "--- RecPKTMessageHdr (starts at offset 58) ---"
VAL=$(od -A n -t u2 -j 58 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 2 ] && pass "Offset 58: MsgType = 2" || fail "MsgType = $VAL"

VAL=$(od -A n -t u2 -j 60 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 158 ] && pass "Offset 60: Msg OrigNode = 158" || fail "OrigNode = $VAL"

VAL=$(od -A n -t u2 -j 62 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 800 ] && pass "Offset 62: Msg DestNode = 800" || fail "DestNode = $VAL"

VAL=$(od -A n -t u2 -j 64 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 267 ] && pass "Offset 64: Msg OrigNet = 267" || fail "OrigNet = $VAL"

VAL=$(od -A n -t u2 -j 66 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 267 ] && pass "Offset 66: Msg DestNet = 267" || fail "DestNet = $VAL"

VAL=$(od -A n -t u2 -j 68 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 1 ] && pass "Offset 68: Attribute = 1 (Private)" || fail "Attribute = $VAL"

VAL=$(od -A n -t u2 -j 70 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 0 ] && pass "Offset 70: Cost = 0" || fail "Cost = $VAL"

DT=$(dd if="$PKT" bs=1 skip=72 count=20 2>/dev/null | tr -d '\0')
echo "$DT" | grep -q "20 Jun 26" && pass "Offset 72: DateTime '20 Jun 26'" || fail "DateTime = '$DT'"
echo "$DT" | grep -q "11:27:30" && pass "Offset 72: DateTime '11:27:30'" || fail "DateTime = '$DT'"

echo ""
echo "--- Null-terminated string fields ---"
TO=$(dd if="$PKT" bs=1 skip=92 count=8 2>/dev/null | tr -d '\0' | head -c7)
[ "$TO" = "Areafix" ] && pass "ToUser = 'Areafix' (offset 92)" || fail "ToUser = '$TO'"

FROM=$(dd if="$PKT" bs=1 skip=100 count=13 2>/dev/null | tr -d '\0' | head -c12)
[ "$FROM" = "Antonio Rico" ] && pass "FromUser = 'Antonio Rico' (offset 100)" || fail "FromUser = '$FROM'"

SUBJ=$(dd if="$PKT" bs=1 skip=113 count=7 2>/dev/null | tr -d '\0' | head -c6)
[ "$SUBJ" = "XXXXXX" ] && pass "Subject = 'XXXXXX' (offset 113)" || fail "Subject = '$SUBJ'"

ENDMARK=$(od -A n -t x1 -j 303 -N 2 "$PKT" | tr -d ' ')
[ "$ENDMARK" = "0000" ] && pass "Offset 303: End marker (0x0000)" || fail "End = $ENDMARK"

results
