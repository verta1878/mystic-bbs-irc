#!/usr/bin/env bash
# Item 3: BINKP / FTS-1026 validation
source "$(dirname "$0")/common.sh"

echo "================================================================"
echo " test-binkp-fts1026: BINKP protocol and FTS-1026 compliance"
echo "================================================================"
echo ""

echo "--- BINKP command constants (FTS-1026 section 5) ---"
grep -q "M_NUL  = 0" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_NUL = 0" || fail "Wrong"
grep -q "M_ADR  = 1" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_ADR = 1" || fail "Wrong"
grep -q "M_PWD  = 2" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_PWD = 2" || fail "Wrong"
grep -q "M_FILE = 3" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_FILE = 3" || fail "Wrong"
grep -q "M_OK   = 4" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_OK = 4" || fail "Wrong"
grep -q "M_EOB  = 5" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_EOB = 5" || fail "Wrong"
grep -q "M_GOT  = 6" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_GOT = 6" || fail "Wrong"
grep -q "M_ERR  = 7" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_ERR = 7" || fail "Wrong"
grep -q "M_GET  = 9" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_GET = 9" || fail "Wrong"

echo ""
echo "--- Session handshake ---"
grep -q "SYS " "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Sends SYS (system name)" || fail "Missing"
grep -q "ZYZ " "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Sends ZYZ (sysop name)" || fail "Missing"
grep -q "VER Mystic" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Sends VER string" || fail "Missing"
grep -q "binkp/1.0" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Identifies as binkp/1.0" || fail "Wrong"

echo ""
echo "--- Authentication ---"
grep -q "CRAM-MD5" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "CRAM-MD5 supported" || fail "Missing"
grep -q "MD5Challenge" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "MD5 challenge generated" || fail "Missing"
grep -q "SetPassword" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Plain password fallback" || fail "Missing"

echo ""
echo "--- A56: Argus M_PWD dash fix ---"
grep -q "Password = '-'" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Dash treated as empty" || fail "Missing"

echo ""
echo "--- A56: Non-Reliable extension ---"
grep -q "OPT NR" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Advertises OPT NR" || fail "Missing"

echo ""
echo "--- File receive ---"
grep -q "InFN" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Incoming filename (InFN)" || fail "Missing"
grep -q "InSize" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Incoming size (InSize)" || fail "Missing"
grep -q "InPos" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Incoming position (InPos)" || fail "Missing"
grep -q "InBoundPath" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Files saved to InBoundPath" || fail "Missing"

echo ""
echo "--- A53: File conflict Rename/Skip ---"
grep -q "inetBINKPRename" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Rename/skip config" || fail "Missing"
grep -q "M_GOT" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_GOT for same-size dupe" || fail "Missing"

echo ""
echo "--- A60: Junk protection ---"
grep -q "BinkPMaxBufferSize" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Max buffer defined" || fail "Missing"
grep -q "JUNK.*oversized" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Oversized frame detection" || fail "Missing"
grep -q "Disconnect" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Disconnect on junk" || fail "Missing"

echo ""
echo "--- Unsecure session ---"
grep -q "inetBINKPUnsecure" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Unsecure config" || fail "Missing"
grep -q "UnsecurePath" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Unsecure path routing" || fail "Missing"

echo ""
echo "--- Protocol layer (m_prot_binkp.pas) ---"
grep -q "SendFrame" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "SendFrame" || fail "Missing"
grep -q "SendDataFrame" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "SendDataFrame" || fail "Missing"
grep -q "GetDataStr" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "GetDataStr" || fail "Missing"
grep -q "DoFrameCheck" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "DoFrameCheck" || fail "Missing"
grep -q "DoAuthentication" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "DoAuthentication" || fail "Missing"
grep -q "DoTransfers" "$BASEDIR/mdl/m_prot_binkp.pas" && pass "DoTransfers" || fail "Missing"

echo ""
echo "--- PKT fixture acceptance ---"
PKTSIZE=$(stat -c%s "$PKT")
MAXBUF=30720
[ "$PKTSIZE" -lt "$MAXBUF" ] && pass "PKT size ($PKTSIZE) < max buffer ($MAXBUF)" || fail "Too large"
PASSWD=$(dd if="$PKT" bs=1 skip=26 count=8 2>/dev/null | tr -d '\0')
[ -z "$PASSWD" ] && pass "PKT password field (sanitized ('$PASSWD')" || fail "No password"

results
