#!/usr/bin/env bash
# Item 1: PKT header fields and file integrity
source "$(dirname "$0")/common.sh"

echo "================================================================"
echo " test-pkt-header: PKT Type 2+ header parsing"
echo " Fixture: 05E46980.PKT (305 bytes, Areafix netmail)"
echo "================================================================"
echo ""

echo "--- File integrity ---"
[ -f "$PKT" ] && pass "PKT file exists" || fail "PKT file missing"
[ "$(stat -c%s "$PKT")" -eq 305 ] && pass "PKT size is 305 bytes" || fail "Wrong size"

echo ""
echo "--- PKT header (Type 2+) ---"
VAL=$(od -A n -t u2 -j 0 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 158 ] && pass "Orig node = 158" || fail "Orig node = $VAL"

VAL=$(od -A n -t u2 -j 2 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 800 ] && pass "Dest node = 800" || fail "Dest node = $VAL"

VAL=$(od -A n -t u2 -j 4 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 2026 ] && pass "Year = 2026" || fail "Year = $VAL"

VAL=$(od -A n -t u2 -j 6 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 5 ] && pass "Month = 5 (June, 0-based)" || fail "Month = $VAL"

VAL=$(od -A n -t u2 -j 8 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 20 ] && pass "Day = 20" || fail "Day = $VAL"

VAL=$(od -A n -t u2 -j 10 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 11 ] && pass "Hour = 11" || fail "Hour = $VAL"

VAL=$(od -A n -t u2 -j 12 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 27 ] && pass "Minute = 27" || fail "Minute = $VAL"

VAL=$(od -A n -t u2 -j 14 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 42 ] && pass "Second = 42" || fail "Second = $VAL"

VAL=$(od -A n -t u2 -j 18 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 2 ] && pass "PKT version = 2 (Type 2+)" || fail "PKT version = $VAL"

VAL=$(od -A n -t u2 -j 20 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 267 ] && pass "Orig net = 267" || fail "Orig net = $VAL"

VAL=$(od -A n -t u2 -j 22 -N 2 "$PKT" | tr -d ' ')
[ "$VAL" -eq 267 ] && pass "Dest net = 267" || fail "Dest net = $VAL"

PASSWD=$(dd if="$PKT" bs=1 skip=26 count=8 2>/dev/null | tr -d '\0' | tr -cd '[:print:]')
[ "$PASSWD" = "" ] && pass "Password zeroed (sanitized)" || fail "Password = '$PASSWD'"

echo ""
echo "--- Message content ---"
CONTENT=$(strings "$PKT")
echo "$CONTENT" | grep -q "Areafix" && pass "To: Areafix" || fail "Missing"
echo "$CONTENT" | grep -q "Antonio Rico" && pass "From: Antonio Rico" || fail "Missing"
echo "$CONTENT" | grep -q "INTL 1:267/800 1:267/158" && pass "INTL kludge correct" || fail "Wrong"
echo "$CONTENT" | grep -q "MSGID: 1:267/158" && pass "MSGID present" || fail "Missing"
echo "$CONTENT" | grep -q "FLAGS DIR IMM" && pass "FLAGS DIR IMM" || fail "Missing"
echo "$CONTENT" | grep -q "TZUTC: -0400" && pass "TZUTC: -0400" || fail "Missing"
echo "$CONTENT" | grep -q "%HELP" && pass "Body: %HELP command" || fail "Missing"
echo "$CONTENT" | grep -q "Mystic BBS" && pass "Tearline: Mystic BBS" || fail "Missing"

grep -q "pktPrivate" "$BASEDIR/mystic/mutil_echocore.pas" && pass "PKT types in mutil_echocore.pas" || fail "Missing"

LAST2=$(od -A n -t x1 -j 303 -N 2 "$PKT" | tr -d ' ')
[ "$LAST2" = "0000" ] && pass "PKT ends with 0x0000" || fail "End = $LAST2"

results
