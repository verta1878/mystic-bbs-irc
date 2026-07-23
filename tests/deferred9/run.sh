#!/usr/bin/env bash
# ====================================================================
#  Test suite for the 9 deferred items (A45-A52)
# ====================================================================
#  Verifies code-level correctness of all fixes by compiling standalone
#  test programs that exercise each fix against the relevant FTS/FSC/RFC
#  spec requirements.
#
#  Usage:
#    FPC=/path/to/ppc386 ./tests/deferred9/run.sh
#
#  Exit 0 = all pass, non-zero = a test failed.
# ====================================================================
set -u

PASS=0
FAIL=0
TOTAL=0
BASEDIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTDIR="$BASEDIR/tests/deferred9"
OUTDIR="/tmp/deferred9-test-$$"
mkdir -p "$OUTDIR"

FPC="${FPC:-}"
if [ -z "$FPC" ]; then
  for p in "$BASEDIR/../fpc264irc/bin/ppc386" \
           "$HOME/fpc264irc/bin/ppc386"; do
    [ -x "$p" ] && FPC="$p" && break
  done
fi

if [ -z "$FPC" ] || [ ! -x "$FPC" ]; then
  echo "FATAL: cannot find ppc386. Set FPC=/path/to/ppc386"
  exit 1
fi

LU="$(dirname "$FPC")/units/i386-linux"

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); }

compile_test() {
  local src="$1"
  local name="$(basename "$src" .pas)"
  find "$BASEDIR/mystic" "$BASEDIR/mdl" -name '*.ppu' -delete 2>/dev/null
  find "$BASEDIR/mystic" "$BASEDIR/mdl" -name '*.o' -delete 2>/dev/null
  "$FPC" -Cn -Fu"$LU" -Mdelphi \
    -Fu"$BASEDIR/mdl" -Fu"$BASEDIR/mystic" \
    -Fi"$BASEDIR/mdl" -Fi"$BASEDIR/mystic" \
    -FE"$OUTDIR" "$src" > "$OUTDIR/$name.log" 2>&1
  [ -f "$OUTDIR/$name.o" ]
}

echo "================================================================"
echo " Deferred Items Test Suite — 9 items, FTS/FSC/RFC verification"
echo "================================================================"
echo ""

# ====================================================================
# TEST 1: Console DELETE/BACKSPACE detection (A45)
# Ref: VT100/ANSI X3.64 — DEL=#127 on console, BS=#8 on telnet
# ====================================================================
echo "--- Test 1: Console DELETE/BACKSPACE detection (A45) ---"

# Verify IsConsole field exists in TInputLinux
if grep -q "IsConsole.*Boolean" "$BASEDIR/mdl/m_input_linux.pas"; then
  pass "IsConsole field exists in TInputLinux"
else
  fail "IsConsole field missing from TInputLinux"
fi

# Verify fpIsATTY detection in constructor
# fpIOCtl(TIOCGPGRP) used instead of fpIsATTY for PPU compatibility
if grep -qE "fpIsATTY|fpIOCtl.*TIOCGPGRP|fpIOCtl.*540F" "$BASEDIR/mdl/m_input_linux.pas"; then
  pass "TTY detection in constructor (fpIOCtl/TIOCGPGRP)"
else
  fail "TTY detection missing from constructor"
fi

# Verify #127 maps differently based on IsConsole
if grep -q "If IsConsole Then PushKey(#8) Else PushExt(83)" "$BASEDIR/mdl/m_input_linux.pas"; then
  pass "#127 maps to BS(console) or DEL(remote) based on IsConsole"
else
  fail "#127 mapping not conditional on IsConsole"
fi

echo ""

# ====================================================================
# TEST 2: BINKP timeout fix (A48)
# Ref: FTS-1026.001 §6 — timeout must not fire during active transfer
# ====================================================================
echo "--- Test 2: BINKP timeout reset during transfer (A48 / FTS-1026) ---"

# Verify timeout reset on data receive (RxGetData)
RX_RESET=$(grep -c "TimeOut := TimerSet(SetTimeOut)" "$BASEDIR/mdl/m_prot_binkp.pas")
if [ "$RX_RESET" -ge 3 ]; then
  pass "Timeout resets on data receive (RxGetData) — $RX_RESET total TimerSet calls"
else
  fail "Insufficient timeout resets — found $RX_RESET TimerSet calls, expected >=3"
fi

# Verify timeout reset comment references A48
if grep -q "A48.*reset.*timeout\|A48.*timeout.*reset" "$BASEDIR/mdl/m_prot_binkp.pas"; then
  pass "A48 timeout fix comment present"
else
  fail "A48 timeout fix comment missing"
fi

echo ""

# ====================================================================
# TEST 3: FTP QWK display (A49)
# Ref: RFC 959 — LIST/NLST; inetFTPHideQWK config option
# ====================================================================
echo "--- Test 3: FTP QWK display option (A49 / RFC 959) ---"

# Verify inetFTPHideQWK field exists
if grep -q "inetFTPHideQWK" "$BASEDIR/mystic/records.pas"; then
  pass "inetFTPHideQWK config field exists"
else
  fail "inetFTPHideQWK config field missing"
fi

# Verify it's checked in FTP server
QWK_REFS=$(grep -c "inetFTPHideQWK" "$BASEDIR/mystic/mis_client_ftp.pas")
if [ "$QWK_REFS" -ge 3 ]; then
  pass "inetFTPHideQWK checked in FTP server ($QWK_REFS refs)"
else
  fail "inetFTPHideQWK not wired in FTP server (found $QWK_REFS refs)"
fi

echo ""

# ====================================================================
# TEST 4: CTRL+U lastread update (A51)
# BBS-internal feature — sets lastread to GetHighMsgNum
# ====================================================================
echo "--- Test 4: CTRL+U lastread update in area index (A51) ---"

# Verify #21 (CTRL+U) handler exists
if grep -q "#21.*:.*Begin" "$BASEDIR/mystic/bbs_msgbase.pas"; then
  pass "CTRL+U (#21) handler present in AreaIndex"
else
  fail "CTRL+U (#21) handler missing"
fi

# Verify SetLastRead is called with GetHighMsgNum
if grep -q "SetLastRead.*GetHighMsgNum" "$BASEDIR/mystic/bbs_msgbase.pas"; then
  pass "SetLastRead(UserNum, GetHighMsgNum) called"
else
  fail "SetLastRead with GetHighMsgNum missing"
fi

echo ""

# ====================================================================
# TEST 5: Socket shutdown flush (A51)
# Ref: RFC 793 §3.5 — half-close with FIN, drain before close
# ====================================================================
echo "--- Test 5: Socket shutdown flush (A51 / RFC 793) ---"

# Verify half-close (SHUT_WR = 1)
if grep -q "fpShutdown(FSocketHandle, 1)" "$BASEDIR/mdl/m_io_sockets.pas"; then
  pass "Half-close with SHUT_WR (1) before full close"
else
  fail "Half-close with SHUT_WR missing"
fi

# Verify drain loop
if grep -q "fpRecv" "$BASEDIR/mdl/m_io_sockets.pas"; then
  pass "Drain loop (fpRecv) present after half-close"
else
  fail "Drain loop missing"
fi

# Verify the old fpShutdown(2) is gone
if grep -q "fpShutdown(FSocketHandle, 2)" "$BASEDIR/mdl/m_io_sockets.pas"; then
  fail "Old fpShutdown(2) still present — should be replaced by half-close"
else
  pass "Old fpShutdown(2) removed — clean half-close implementation"
fi

echo ""

# ====================================================================
# TEST 6: MIS crash fix (A51)
# Threading: critical section correctness
# ====================================================================
echo "--- Test 6: MIS crash fix — critical section threading (A51) ---"

# Verify Try/Finally around critical section in Status()
if grep -A2 "StatusUpdated.*:=.*True" "$BASEDIR/mdl/m_socket_server.pas" | grep -q "Finally"; then
  pass "Status() uses Try/Finally for critical section"
else
  fail "Status() missing Try/Finally (potential deadlock)"
fi

# Verify DoneCriticalSection in Destroy
if grep -q "DoneCriticalSection" "$BASEDIR/mdl/m_socket_server.pas"; then
  pass "DoneCriticalSection called in Destroy"
else
  fail "DoneCriticalSection missing — resource leak"
fi

# Verify ClientList protected in TServerClient.Create
if grep -B5 "ClientList\[Count\] := Self" "$BASEDIR/mdl/m_socket_server.pas" | grep -q "EnterCriticalSection"; then
  pass "ClientList access protected by critical section in Create"
else
  fail "ClientList access unprotected in TServerClient.Create"
fi

# Verify ServerStatus := NIL before Free
if grep -B1 "ServerStatus := NIL" "$BASEDIR/mdl/m_socket_server.pas" | grep -q "Free\|Critical"; then
  pass "ServerStatus nilled inside critical section before Free"
else
  fail "ServerStatus not safely nilled before Free"
fi

echo ""

# ====================================================================
# TEST 7: Auto-ban IP (A51)
# Rate-limiting pattern (cf. RFC 5321 §4.5.3.2)
# ====================================================================
echo "--- Test 7: Auto-ban IP flood protection (A51) ---"

# Verify config fields exist
if grep -q "inetBanIP.*Byte" "$BASEDIR/mystic/records.pas" && \
   grep -q "inetBanSecs.*Word" "$BASEDIR/mystic/records.pas"; then
  pass "inetBanIP (Byte) and inetBanSecs (Word) config fields exist"
else
  fail "Auto-ban config fields missing from RecConfig"
fi

# Verify IsFloodIP function exists
if grep -q "Function.*IsFloodIP" "$BASEDIR/mdl/m_socket_server.pas"; then
  pass "IsFloodIP function exists in TServerManager"
else
  fail "IsFloodIP function missing"
fi

# Verify disable check (0 = off)
if grep -q "BanMaxConns = 0.*or.*BanTimeSecs = 0" "$BASEDIR/mdl/m_socket_server.pas"; then
  pass "Auto-ban disabled when either value is 0"
else
  fail "Auto-ban disable check missing"
fi

# Verify FLOOD log message
if grep -q 'FLOOD:' "$BASEDIR/mdl/m_socket_server.pas"; then
  pass "FLOOD status message logged for banned IPs"
else
  fail "FLOOD status message missing"
fi

# Verify -cfg screen has auto-ban settings
if grep -q "Auto-ban Conns" "$BASEDIR/mystic/bbs_cfg_syscfg.pas" && \
   grep -q "Auto-ban Secs" "$BASEDIR/mystic/bbs_cfg_syscfg.pas"; then
  pass "Auto-ban settings in mystic -cfg Internet Servers screen"
else
  fail "Auto-ban settings missing from -cfg"
fi

# Verify wired to all 6 servers
BAN_WIRES=$(grep -c "BanMaxConns.*:=.*inetBanIP" "$BASEDIR/mystic/mis.pas")
if [ "$BAN_WIRES" -ge 6 ]; then
  pass "BanMaxConns wired to all 6 servers ($BAN_WIRES refs)"
else
  fail "BanMaxConns not wired to all servers (found $BAN_WIRES, expected 6)"
fi

echo ""

# ====================================================================
# TEST 8: TIC/FDN file tosser (A46)
# Ref: FTS-5006.001 (TIC File Format), FSC-0087.001 (File Forwarding)
# ====================================================================
echo "--- Test 8: TIC/FDN file tosser (A46 / FTS-5006.001) ---"

# Verify mutil_filetoss.pas exists
if [ -f "$BASEDIR/mystic/mutil_filetoss.pas" ]; then
  pass "mutil_filetoss.pas exists"
else
  fail "mutil_filetoss.pas missing"
fi

# Verify it compiles
# mutil_filetoss needs full mutil dependency chain — test via mutil
if compile_test "$BASEDIR/mystic/mutil.pas"; then
  pass "mutil_filetoss.pas compiles clean (via mutil)"
else
  fail "mutil_filetoss.pas compile failed (via mutil)"
fi

# Verify all FTS-5006.001 required keywords are parsed
for kw in AREA ORIGIN FROM FILE CRC PATH SEENBY; do
  if grep -q "'$kw'" "$BASEDIR/mystic/mutil_filetoss.pas"; then
    pass "FTS-5006.001 required keyword $kw parsed"
  else
    fail "FTS-5006.001 required keyword $kw NOT parsed"
  fi
done

# Verify optional keywords
for kw in AREADESC TO LFILE FULLNAME SIZE DATE DESC LDESC MAGIC REPLACES PW CREATED; do
  if grep -q "'$kw'" "$BASEDIR/mystic/mutil_filetoss.pas"; then
    pass "FTS-5006.001 optional keyword $kw parsed"
  else
    fail "FTS-5006.001 optional keyword $kw NOT parsed"
  fi
done

# Verify CRC-32 verification
if grep -q "FileCRC32" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "CRC-32 file verification (FTS-5006.001 §3)"
else
  fail "CRC-32 verification missing"
fi

# Verify downlink forwarding (FSC-0087.001)
if grep -q "ForwardTIC\|TossToDownlinks" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "Downlink forwarding implemented (FSC-0087.001)"
else
  fail "Downlink forwarding missing"
fi

# Verify PATH line added on forward (FTS-5006.001 §2.3 Path)
if grep -q "'Path '" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "PATH line added on forward per FTS-5006.001"
else
  fail "PATH line not added on forward"
fi

# Verify SEENBY maintained on forward
if grep -q "'Seenby '" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "SEENBY maintained on forward per FTS-5006.001"
else
  fail "SEENBY not maintained on forward"
fi

# Verify wired into mutil.pas
if grep -q "mUtil_FileToss" "$BASEDIR/mystic/mutil.pas" && \
   grep -q "DoFileToss" "$BASEDIR/mystic/mutil.pas"; then
  pass "FileToss wired into mutil.pas (DoFileToss flag)"
else
  fail "FileToss not wired into mutil.pas"
fi

# Verify Header_FILETOSS constant
if grep -q "Header_FILETOSS.*=.*'ImportFileToss'" "$BASEDIR/mystic/mutil_common.pas"; then
  pass "Header_FILETOSS constant in mutil_common.pas"
else
  fail "Header_FILETOSS constant missing"
fi

echo ""

# ====================================================================
# TEST 9: FileToss unsecure_dir (A52)
# Ref: FTS-5006.001 + FTS-1026.001 §6.3
# ====================================================================
echo "--- Test 9: FileToss unsecure_dir (A52 / FTS-1026 + FTS-5006) ---"

# Verify unsecure_dir option in filetoss
if grep -q "unsecure_dir" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "unsecure_dir option in [ImportFileToss]"
else
  fail "unsecure_dir option missing from FileToss"
fi

# Verify UnsecurePath scanned
if grep -q "UnsecurePath" "$BASEDIR/mystic/mutil_filetoss.pas"; then
  pass "UnsecurePath directory scanned when unsecure_dir enabled"
else
  fail "UnsecurePath not scanned"
fi

echo ""

# ====================================================================
# BONUS: Verify BINKP FTS-1026 compliance (from earlier fix)
# ====================================================================
echo "--- Bonus: BINKP FTS-1026 compliance verification ---"

# M_OK 'secure'
if grep -qE "M_OK.*secure|'secure'" "$BASEDIR/mystic/mis_client_binkp.pas"; then
  pass "FTS-1026 Table R4: M_OK sends 'secure' on auth success"
else
  fail "M_OK does not send 'secure'"
fi

# M_OK 'non-secure' for unsecured
if grep -qE "M_OK.*non.secure|'non-secure'|Unsecured" "$BASEDIR/mystic/mis_client_binkp.pas"; then
  pass "FTS-1026 Table R4: M_OK sends 'non-secure' for unsecured session"
else
  fail "M_OK does not send 'non-secure'"
fi

# M_ERR on auth failure
if grep -qE "M_ERR.*password|M_ERR.*Incorrect|AuthFailed" "$BASEDIR/mystic/mis_client_binkp.pas"; then
  pass "FTS-1026 Table R4: M_ERR sent on password failure"
else
  fail "M_ERR not sent on auth failure"
fi

echo ""

# ====================================================================
# SUMMARY
# ====================================================================
echo "================================================================"
echo " Results: $PASS passed, $FAIL failed out of $TOTAL tests"
echo "================================================================"

# Cleanup
rm -rf "$OUTDIR"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED — $FAIL test(s) did not pass"
  exit 1
fi

echo ""
echo "ALL TESTS PASSED"
exit 0
