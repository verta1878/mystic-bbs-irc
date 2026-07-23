#!/usr/bin/env bash
# TIC file tosser validation — FTS-5006.001 / FSC-0087.001
source "$(dirname "$0")/common.sh"

TIC="$PKTDIR/PX50650A.TIC"

echo "================================================================"
echo " test-tic-tosser: TIC file parsing and tosser verification"
echo " Fixture: PX50650A.TIC (NASA file echo, sanitized)"
echo "================================================================"
echo ""

# File integrity
echo "--- TIC file integrity ---"
[ -f "$TIC" ] && pass "TIC file exists" || fail "Missing"
[ "$(wc -l < "$TIC")" -gt 10 ] && pass "TIC has content ($(wc -l < "$TIC") lines)" || fail "Empty"
head -1 "$TIC" | grep -q "PXTIC" && pass "Created by PXTIC/Win" || fail "Unknown creator"

# FTS-5006.001 required fields
echo ""
echo "--- FTS-5006.001 required fields ---"
grep -q "^Area " "$TIC" && pass "Area field present" || fail "Missing"
grep -q "^Origin " "$TIC" && pass "Origin field present" || fail "Missing"
grep -q "^From " "$TIC" && pass "From field present" || fail "Missing"
grep -q "^File " "$TIC" && pass "File field present" || fail "Missing"
grep -q "^Crc " "$TIC" && pass "Crc field present" || fail "Missing"
grep -q "^Path " "$TIC" && pass "Path field present" || fail "Missing"
grep -q "^Pw " "$TIC" && pass "Pw field present" || fail "Missing"

# FTS-5006.001 optional fields
echo ""
echo "--- FTS-5006.001 optional fields ---"
grep -q "^To " "$TIC" && pass "To field present" || fail "Missing"
grep -q "^Desc " "$TIC" && pass "Desc field present" || fail "Missing"
grep -q "^Ldesc " "$TIC" && pass "Ldesc field present" || fail "Missing"
grep -q "^Replaces " "$TIC" && pass "Replaces field present" || fail "Missing"
grep -qi "^SeenBy " "$TIC" && pass "SeenBy field present" || fail "Missing"

# Field value verification
echo ""
echo "--- Field values ---"
AREA=$(grep "^Area " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$AREA" = "NASA" ] && pass "Area = NASA" || fail "Area = $AREA"

ORIGIN=$(grep "^Origin " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$ORIGIN" = "1:153/757" ] && pass "Origin = 1:153/757" || fail "Origin = $ORIGIN"

FROM=$(grep "^From " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$FROM" = "3:712/1321" ] && pass "From = 3:712/1321" || fail "From = $FROM"

FILENAME=$(grep "^File " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$FILENAME" = "AP260418.ZIP" ] && pass "File = AP260418.ZIP" || fail "File = $FILENAME"

REPLACES=$(grep "^Replaces " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$REPLACES" = "ap260418.zip" ] && pass "Replaces = ap260418.zip" || fail "Replaces = $REPLACES"

CRC=$(grep "^Crc " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$CRC" = "D78C3F4F" ] && pass "CRC = D78C3F4F" || fail "CRC = $CRC"

PW=$(grep "^Pw " "$TIC" | awk '{print $2}' | tr -d '\r')
[ "$PW" = "XXXXXXXX" ] && pass "Password sanitized" || fail "Password not sanitized: $PW"

# Address format validation
echo ""
echo "--- FTN address format ---"
echo "$ORIGIN" | grep -qE "^[0-9]+:[0-9]+/[0-9]+" && pass "Origin is valid FTN address" || fail "Bad format"
echo "$FROM" | grep -qE "^[0-9]+:[0-9]+/[0-9]+" && pass "From is valid FTN address" || fail "Bad format"

# Path routing verification
echo ""
echo "--- Path routing ---"
PATH_COUNT=$(grep -c "^Path " "$TIC")
[ "$PATH_COUNT" -ge 2 ] && pass "Multiple path entries ($PATH_COUNT hops)" || fail "Only $PATH_COUNT"
grep "^Path " "$TIC" | head -1 | grep -q "1:153/757" && pass "Path starts at origin (1:153/757)" || fail "Wrong start"
grep "^Path " "$TIC" | grep -q "3:712/1321" && pass "Path includes sender (3:712/1321)" || fail "Missing sender"

# SeenBy verification
echo ""
echo "--- SeenBy distribution ---"
SEENBY_COUNT=$(grep -ci "^SeenBy " "$TIC")
[ "$SEENBY_COUNT" -ge 10 ] && pass "SeenBy has $SEENBY_COUNT entries (wide distribution)" || fail "Only $SEENBY_COUNT"

# Check multi-zone distribution
grep -qi "^SeenBy 1:" "$TIC" && pass "SeenBy includes Zone 1" || fail "Missing Zone 1"
grep -qi "^SeenBy 2:" "$TIC" && pass "SeenBy includes Zone 2" || fail "Missing Zone 2"
grep -qi "^SeenBy 3:" "$TIC" && pass "SeenBy includes Zone 3" || fail "Missing Zone 3"

# Verify our TIC tosser code handles these fields
echo ""
echo "--- mutil_filetoss.pas verification ---"
[ -f "$BASEDIR/mystic/mutil_filetoss.pas" ] && pass "mutil_filetoss.pas exists" || fail "Missing"
grep -q "Area" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads Area field" || fail "Missing"
grep -q "Origin" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads Origin field" || fail "Missing"
grep -q "File " "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads File field" || fail "Missing"
grep -q "Crc\|CRC" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads CRC field" || fail "Missing"
grep -q "Desc" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads Desc field" || fail "Missing"
grep -q "Replaces\|Replace" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser handles Replaces" || fail "Missing"
grep -q "Path" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads Path" || fail "Missing"
grep -qi "SeenBy\|Seenby" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser reads SeenBy" || fail "Missing"
grep -q "Pw\|Password" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Tosser checks password" || fail "Missing"

# FTS-5006.001 spec references in code
echo ""
echo "--- FTS-5006.001 spec compliance ---"
grep -q "FTS-5006\|FTS.5006\|fts5006" "$BASEDIR/mystic/mutil_filetoss.pas" && \
  pass "FTS-5006 reference in code" || fail "No spec reference"
grep -q "fbases\|FBase\|RecFileBase" "$BASEDIR/mystic/mutil_filetoss.pas" && \
  pass "Tosser writes to file base" || fail "Missing"
grep -q "auto_create\|AutoCreate\|create.*base" "$BASEDIR/mystic/mutil_filetoss.pas" && \
  pass "Auto-create file base support" || fail "Missing"

results
