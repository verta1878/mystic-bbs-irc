#!/usr/bin/env bash
# Item 5: FTS spec cross-reference and comprehensive validation
source "$(dirname "$0")/common.sh"

echo "================================================================"
echo " test-fts-compliance: FTS/FSC spec cross-reference"
echo "================================================================"
echo ""

CONTENT=$(strings "$PKT")

echo "--- FTS-0001 Type 2+ compliance ---"
VER=$(od -A n -t u2 -j 18 -N 2 "$PKT" | tr -d ' ')
[ "$VER" -eq 2 ] && pass "FTS-0001: PKT version = 2" || fail "Version $VER"

OZ1=$(od -A n -t u2 -j 34 -N 2 "$PKT" | tr -d ' ')
OZ2=$(od -A n -t u2 -j 46 -N 2 "$PKT" | tr -d ' ')
[ "$OZ1" -eq "$OZ2" ] && pass "FSC-0048: OrigZone ($OZ1) = OrigZone2 ($OZ2)" || fail "Mismatch"

DZ1=$(od -A n -t u2 -j 36 -N 2 "$PKT" | tr -d ' ')
DZ2=$(od -A n -t u2 -j 48 -N 2 "$PKT" | tr -d ' ')
[ "$DZ1" -eq "$DZ2" ] && pass "FSC-0048: DestZone ($DZ1) = DestZone2 ($DZ2)" || fail "Mismatch"

PKT_ON=$(od -A n -t u2 -j 0 -N 2 "$PKT" | tr -d ' ')
MSG_ON=$(od -A n -t u2 -j 60 -N 2 "$PKT" | tr -d ' ')
[ "$PKT_ON" -eq "$MSG_ON" ] && pass "FTS-0001: PKT OrigNode = Msg OrigNode ($PKT_ON)" || fail "Mismatch"

PKT_ONET=$(od -A n -t u2 -j 20 -N 2 "$PKT" | tr -d ' ')
MSG_ONET=$(od -A n -t u2 -j 64 -N 2 "$PKT" | tr -d ' ')
[ "$PKT_ONET" -eq "$MSG_ONET" ] && pass "FTS-0001: PKT OrigNet = Msg OrigNet ($PKT_ONET)" || fail "Mismatch"

PKT_DN=$(od -A n -t u2 -j 2 -N 2 "$PKT" | tr -d ' ')
MSG_DN=$(od -A n -t u2 -j 62 -N 2 "$PKT" | tr -d ' ')
[ "$PKT_DN" -eq "$MSG_DN" ] && pass "FTS-0001: PKT DestNode = Msg DestNode ($PKT_DN)" || fail "Mismatch"

PKT_DNET=$(od -A n -t u2 -j 22 -N 2 "$PKT" | tr -d ' ')
MSG_DNET=$(od -A n -t u2 -j 66 -N 2 "$PKT" | tr -d ' ')
[ "$PKT_DNET" -eq "$MSG_DNET" ] && pass "FTS-0001: PKT DestNet = Msg DestNet ($PKT_DNET)" || fail "Mismatch"

echo ""
echo "--- INTL kludge cross-check ---"
INTL_DEST=$(echo "$CONTENT" | grep "INTL" | awk '{print $2}')
INTL_ORIG=$(echo "$CONTENT" | grep "INTL" | awk '{print $3}')
[ "$INTL_DEST" = "1:267/800" ] && pass "INTL dest = 1:267/800" || fail "INTL dest = $INTL_DEST"
[ "$INTL_ORIG" = "1:267/158" ] && pass "INTL orig = 1:267/158" || fail "INTL orig = $INTL_ORIG"
grep -q "Str2Addr.*MsgDest" "$BASEDIR/mystic/mutil_echocore.pas" && pass "Code: INTL -> MsgDest (dest first per FTS)" || fail "Wrong"
grep -q "MSGID" "$BASEDIR/mystic/mutil_echocore.pas" && grep -q "MsgOrig" "$BASEDIR/mystic/mutil_echocore.pas" && pass "Code: MSGID parsed, MsgOrig set" || fail "Wrong"

echo ""
echo "--- MSGID cross-check ---"
MSGID_ADDR=$(echo "$CONTENT" | grep "MSGID:" | awk '{print $2}')
[ "$MSGID_ADDR" = "1:267/158" ] && pass "MSGID address = 1:267/158" || fail "MSGID = $MSGID_ADDR"
MSGID_SER=$(echo "$CONTENT" | grep "MSGID:" | awk '{print $3}')
[ -n "$MSGID_SER" ] && pass "MSGID serial: $MSGID_SER" || fail "No serial"

echo ""
echo "--- DateTime format (FTS-0001 section 2.1.2) ---"
DT=$(dd if="$PKT" bs=1 skip=72 count=19 2>/dev/null)
echo "$DT" | grep -qE "^[0-9]{2} [A-Z][a-z]{2} [0-9]{2}  [0-9]{2}:[0-9]{2}:[0-9]{2}$" && \
  pass "DateTime: 'DD Mon YY  HH:MM:SS'" || fail "Format wrong: '$DT'"

echo ""
echo "--- Attribute flags (FTS-0001 section 2.1.3) ---"
ATTR=$(od -A n -t u2 -j 68 -N 2 "$PKT" | tr -d ' ')
[ $((ATTR & 1)) -eq 1 ] && pass "Bit 0: Private (Areafix netmail)" || fail "Not private"
[ $((ATTR & 2)) -eq 0 ] && pass "Bit 1: not Crash" || fail "Crash set"
[ $((ATTR & 16)) -eq 0 ] && pass "Bit 4: not FileAttach" || fail "FileAttach set"
[ $((ATTR & 32)) -eq 0 ] && pass "Bit 5: not InTransit" || fail "InTransit set"
grep -q "pktPrivate.*0001" "$BASEDIR/mystic/mutil_echocore.pas" && \
  pass "pktPrivate = 0x0001 (FTS bit 0)" || fail "Wrong constant"

echo ""
echo "--- FLAGS kludge (FSC-0053) ---"
echo "$CONTENT" | grep -q "FLAGS DIR" && pass "FLAGS DIR: direct delivery" || fail "Missing"
echo "$CONTENT" | grep -q "FLAGS.*IMM" && pass "FLAGS IMM: immediate" || fail "Missing"

echo ""
echo "--- TZUTC kludge (FSC-0064) ---"
TZUTC=$(echo "$CONTENT" | grep "TZUTC:" | awk '{print $2}')
[ "$TZUTC" = "-0400" ] && pass "TZUTC = -0400 (Eastern)" || fail "TZUTC = $TZUTC"
TZ_NUM=$(echo "$TZUTC" | sed 's/[^0-9]//g')
[ -n "$TZ_NUM" ] && [ "$TZ_NUM" -le 1200 ] && pass "TZUTC in valid range ($TZ_NUM)" || fail "Out of range"

echo ""
echo "--- PKT password / BINKP cross-check ---"
PASSWD=$(dd if="$PKT" bs=1 skip=26 count=8 2>/dev/null | tr -d '\0')
[ ${#PASSWD} -eq 0 ] && pass "Password zeroed (sanitized)" || fail "Empty"
[ ${#PASSWD} -le 8 ] && pass "Password <= 8 chars (FTS limit)" || fail "Too long"
grep -q "binkPass" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "BINKP validates against binkPass" || fail "Missing"

echo ""
echo "--- Full FTN address reconstruction ---"
ZONE=$(od -A n -t u2 -j 34 -N 2 "$PKT" | tr -d ' ')
NET=$(od -A n -t u2 -j 20 -N 2 "$PKT" | tr -d ' ')
NODE=$(od -A n -t u2 -j 0 -N 2 "$PKT" | tr -d ' ')
POINT=$(od -A n -t u2 -j 50 -N 2 "$PKT" | tr -d ' ')
FULL="${ZONE}:${NET}/${NODE}"
[ "$POINT" -gt 0 ] && FULL="${FULL}.${POINT}"
[ "$FULL" = "1:267/158" ] && pass "Reconstructed orig: $FULL" || fail "Got: $FULL"

DZONE=$(od -A n -t u2 -j 36 -N 2 "$PKT" | tr -d ' ')
DNET=$(od -A n -t u2 -j 22 -N 2 "$PKT" | tr -d ' ')
DNODE=$(od -A n -t u2 -j 2 -N 2 "$PKT" | tr -d ' ')
DPOINT=$(od -A n -t u2 -j 52 -N 2 "$PKT" | tr -d ' ')
DFULL="${DZONE}:${DNET}/${DNODE}"
[ "$DPOINT" -gt 0 ] && DFULL="${DFULL}.${DPOINT}"
[ "$DFULL" = "1:267/800" ] && pass "Reconstructed dest: $DFULL" || fail "Got: $DFULL"

echo ""
echo "--- Message body integrity ---"
BODY=$(dd if="$PKT" bs=1 skip=120 count=183 2>/dev/null | tr -cd '[:print:]')
echo "$BODY" | grep -q "%HELP" && pass "Body: %HELP command" || fail "Missing"
echo "$BODY" | grep -q "Mystic BBS" && pass "Body: tearline" || fail "Missing"
BEFORE_END=$(od -A n -t x1 -j 302 -N 1 "$PKT" | tr -d ' ')
[ "$BEFORE_END" = "00" ] && pass "Message null-terminated" || fail "Byte: $BEFORE_END"

echo ""
echo "--- Mystic address parsing ---"
grep -rq "Function Str2Addr" "$BASEDIR/mystic/"*.pas 2>/dev/null && pass "Str2Addr available" || fail "Missing"
grep -rq "Addr2Str\|strAddr2Str" "$BASEDIR/mystic/"*.pas "$BASEDIR/mdl/"*.pas 2>/dev/null && pass "Addr2Str available" || fail "Missing"

echo ""
echo "--- Export INTL order ---"
grep -q "GetDestAddr.*GetOrigAddr" "$BASEDIR/mystic/mutil_echoexport.pas" && \
  pass "Export: INTL dest then orig (FTS compliant)" || fail "Wrong order"

results
