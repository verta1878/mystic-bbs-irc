#!/usr/bin/env bash
# Item 2: Echomail import code verification
source "$(dirname "$0")/common.sh"

echo "================================================================"
echo " test-echomail-import: TPKTReader and import pipeline"
echo "================================================================"
echo ""

echo "--- TPKTReader class ---"
grep -q "TPKTReader" "$BASEDIR/mystic/mutil_echocore.pas" && pass "TPKTReader class defined" || fail "Missing"
grep -q "Function.*Open.*FN.*String.*Boolean" "$BASEDIR/mystic/mutil_echocore.pas" && pass "Open method" || fail "Missing"
grep -q "Function.*GetMessage.*Boolean" "$BASEDIR/mystic/mutil_echocore.pas" && pass "GetMessage method" || fail "Missing"
grep -q "Procedure.*Close" "$BASEDIR/mystic/mutil_echocore.pas" && pass "Close method" || fail "Missing"
grep -q "Procedure.*DisposeText" "$BASEDIR/mystic/mutil_echocore.pas" && pass "DisposeText method" || fail "Missing"

echo ""
echo "--- PKT header field parsing ---"
grep -q "PKTHeader" "$BASEDIR/mystic/mutil_echocore.pas" && pass "PKTHeader record used" || fail "Missing"
grep -q "OrigNode" "$BASEDIR/mystic/mutil_echocore.pas" && pass "OrigNode parsed" || fail "Missing"
grep -q "DestNode" "$BASEDIR/mystic/mutil_echocore.pas" && pass "DestNode parsed" || fail "Missing"
grep -q "OrigNet" "$BASEDIR/mystic/mutil_echocore.pas" && pass "OrigNet parsed" || fail "Missing"
grep -q "DestNet" "$BASEDIR/mystic/mutil_echocore.pas" && pass "DestNet parsed" || fail "Missing"
grep -q "Password" "$BASEDIR/mystic/mutil_echocore.pas" && pass "Password parsed" || fail "Missing"

echo ""
echo "--- INTL kludge parsing ---"
grep -q "INTL" "$BASEDIR/mystic/mutil_echocore.pas" && pass "INTL kludge detected" || fail "Missing"
grep -q "Str2Addr.*MsgDest" "$BASEDIR/mystic/mutil_echocore.pas" && pass "INTL dest via Str2Addr" || fail "Missing"
grep -q "MSGID" "$BASEDIR/mystic/mutil_echocore.pas" && pass "MSGID kludge detected" || fail "Missing"
grep -q "Str2Addr.*MsgOrig" "$BASEDIR/mystic/mutil_echocore.pas" && pass "MSGID orig via Str2Addr" || fail "Missing"

echo ""
echo "--- AREA tag and message routing ---"
grep -q "AREA:" "$BASEDIR/mystic/mutil_echocore.pas" && pass "AREA: tag parsed" || fail "Missing"
grep -q "MsgArea" "$BASEDIR/mystic/mutil_echocore.pas" && pass "MsgArea set from AREA:" || fail "Missing"

echo ""
echo "--- PKT attribute flags ---"
grep -q "pktPrivate" "$BASEDIR/mystic/mutil_echocore.pas" && pass "pktPrivate defined" || fail "Missing"
grep -q "pktCrash" "$BASEDIR/mystic/mutil_echocore.pas" && pass "pktCrash defined" || fail "Missing"
grep -q "pktKillSent" "$BASEDIR/mystic/mutil_echocore.pas" && pass "pktKillSent defined" || fail "Missing"
grep -q "pktHold" "$BASEDIR/mystic/mutil_echocore.pas" && pass "pktHold defined" || fail "Missing"
grep -q "pktReceived" "$BASEDIR/mystic/mutil_echocore.pas" && pass "pktReceived defined" || fail "Missing"

echo ""
echo "--- Import flag application ---"
grep -q "SetPriv.*pktPrivate" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Private flag applied" || fail "Missing"
grep -q "SetCrash.*pktCrash" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Crash flag applied" || fail "Missing"
grep -q "SetKillSent.*pktKillSent" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "KillSent flag applied" || fail "Missing"
grep -q "SetHold.*pktHold" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Hold flag applied" || fail "Missing"

echo ""
echo "--- Kludge preservation (A59) ---"
grep -q "DoKludgeLn" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Kludge lines via DoKludgeLn" || fail "Missing"
grep -q "DoStringLn" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Non-kludge via DoStringLn" || fail "Missing"

echo ""
echo "--- Duplicate detection ---"
grep -q "TPKTDupe" "$BASEDIR/mystic/mutil_echocore.pas" && pass "TPKTDupe class" || fail "Missing"
grep -q "IsDuplicate" "$BASEDIR/mystic/mutil_echocore.pas" && pass "IsDuplicate method" || fail "Missing"
grep -q "AddDuplicate" "$BASEDIR/mystic/mutil_echocore.pas" && pass "AddDuplicate method" || fail "Missing"

results
