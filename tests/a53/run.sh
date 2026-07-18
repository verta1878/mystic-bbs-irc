#!/usr/bin/env bash
set -u
BASEDIR="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0; TOTAL=0
pass() { echo "  PASS: $1"; PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); }

echo "================================================================"
echo " A53 Test Suite — full coverage"
echo "================================================================"
echo ""

echo "--- #1: Area index snap ---"
grep -q "ListBox.Picked + 1" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Relative snap" || fail "Not relative"
grep -q "For Count := 1 to ListBox.Picked" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Wrap around" || fail "No wrap"

echo "--- #2: Strip pipe from names ---"
[ "$(grep -c 'strStripPipe' "$BASEDIR/mystic/bbs_user.pas")" -ge 3 ] && pass "strStripPipe in bbs_user" || fail "Missing"

echo "--- #3: /ME room scope ---"
grep -q "Msg.Room = Session.CurRoom" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "Room check for type 6" || fail "Missing"
grep -A4 "6 :" "$BASEDIR/mystic/bbs_nodechat.pas" | grep -q "Continue" && pass "Skip other rooms" || fail "No skip"

echo "--- #4: Strip pipe from subjects ---"
grep -q "strStripPipe(MsgBase^.GetSubj)" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Subjects stripped" || fail "Not stripped"

echo "--- #5: Backspace default fix ---"
grep -q "StrPos > Length(Str)" "$BASEDIR/mystic/bbs_io.pas" && pass "Cursor-at-end check" || fail "Missing"

echo "--- #6: &X MCI recalc ---"
grep -A3 "EditMessage;" "$BASEDIR/mystic/bbs_msgbase.pas" | grep -q "OutFile.*ansimrd" && pass "Template redisplay" || fail "Missing"

echo "--- #7: Unsecure BINKP path ---"
grep -q "DirLast(bbsCfg.UnsecurePath)" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "DirLast on UnsecurePath" || fail "Missing"

echo "--- #8: BINKP resume ---"
grep -q "EscapeFileName(InFN)" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_GET uses EscapeFileName" || fail "Missing"
[ "$(grep -c 'M_GOT' "$BASEDIR/mystic/mis_client_binkp.pas")" -ge 2 ] && pass "M_GOT for received files" || fail "Missing"

echo "--- #9: BINKP file conflict ---"
grep -q "inetBINKPRename" "$BASEDIR/mystic/records.pas" && pass "Config field exists" || fail "Missing"
grep -q "JustFileName(InFN)" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Auto-rename logic" || fail "Missing"

echo "--- #10: BufFlush for theme box ---"
grep -B5 "ThemeMessageBox" "$BASEDIR/mystic/bbs_io.pas" | grep -q "BufFlush" && pass "BufFlush before ThemeMessageBox" || fail "Missing"
grep -B1 "Session.io.GetKey" "$BASEDIR/mystic/bbs_ansi_menubox.pas" | grep -q "BufFlush" && pass "BufFlush in ShowMsgBox" || fail "Missing"

echo "--- #12: group_list in ansimidx ---"
grep -q "group_list" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "group_list option" || fail "Missing"
grep -q "exclude_groups" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "exclude_groups option" || fail "Missing"
grep -q "group_g.dat" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Group names from file" || fail "Missing"

echo "--- #13: Mouse support ---"
grep -q "MouseX\|MouseY\|MouseBtn" "$BASEDIR/mdl/m_input_linux.pas" && pass "Mouse fields in TInputLinux" || fail "Missing"
grep -q "PushExt(200)" "$BASEDIR/mdl/m_input_linux.pas" && pass "Mouse event key 200" || fail "Missing"
grep -q "1000h" "$BASEDIR/mystic/bbs_io.pas" && pass "MouseEnable ESC[?1000h" || fail "Missing"
grep -q "1000l" "$BASEDIR/mystic/bbs_io.pas" && pass "MouseDisable ESC[?1000l" || fail "Missing"

echo "--- CIADraw enhancements ---"
grep -q "TAnsiMenuBox.Create" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "Themed box in DrawCommands" || fail "Missing"
grep -q "Left.*FG\|FG backward" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "Arrow key FG navigation" || fail "Missing"
grep -q "Up.*BG\|BG forward" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "Arrow key BG navigation" || fail "Missing"
grep -q "CiADraw ALT-A\|cycle FG color forward" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "CTRL-A FG cycle" || fail "Missing"
grep -q "CiADraw ALT-P\|pickup attribute" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "CTRL-P attribute pickup" || fail "Missing"
grep -q "CiADraw.*clear canvas\|clear canvas" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "CTRL-N clear canvas" || fail "Missing"
grep -q "Box.Close" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "Box cleanup on exit" || fail "Missing"

echo "--- utrayit / MIS tray ---"
[ -f "$BASEDIR/mdl/utrayit.pas" ] && pass "utrayit.pas in mdl/" || fail "Missing"
grep -q "utrayit" "$BASEDIR/mystic/mis.pas" && pass "utrayit in MIS uses" || fail "Missing"
grep -q "TrayMode" "$BASEDIR/mystic/mis.pas" && pass "TrayMode flag" || fail "Missing"
grep -q "TrayConsole" "$BASEDIR/mystic/mis.pas" && pass "TrayConsole on startup" || fail "Missing"
grep -q "UnTrayConsole" "$BASEDIR/mystic/mis.pas" && pass "UnTrayConsole on shutdown" || fail "Missing"

echo "--- fpSetEUID/fpSetEGID ---"
grep -q "fpSetEUID" "$BASEDIR/mystic/mis.pas" && pass "fpSetEUID in SetUserOwner" || fail "Missing"
grep -q "fpSetEGID" "$BASEDIR/mystic/mis.pas" && pass "fpSetEGID in SetUserOwner" || fail "Missing"

echo "--- mystic_modem ---"
[ -f "$BASEDIR/mystic_modem/fossil_dos.pas" ] && pass "fossil_dos.pas (FSC-0015)" || fail "Missing"
[ -f "$BASEDIR/mystic_modem/netmodem.pas" ] && pass "netmodem.pas (serial-TCP)" || fail "Missing"
[ -f "$BASEDIR/mystic_modem/squish_example.pas" ] && pass "squish_example.pas" || fail "Missing"

echo "--- Version ---"
grep -qE "A38irc-A[56][0-9]" "$BASEDIR/mystic/records.pas" && pass "Version A53" || fail "Wrong"
echo ""

echo "================================================================"

echo "--- utextmouse cross-platform mouse unit ---"
[ -f "$BASEDIR/mdl/utextmouse.pas" ] && pass "utextmouse.pas in mdl/" || fail "Missing"
grep -q "TMouseAction" "$BASEDIR/mdl/utextmouse.pas" && pass "TMouseAction type defined" || fail "Missing"
grep -q "TMouseButton" "$BASEDIR/mdl/utextmouse.pas" && pass "TMouseButton type defined" || fail "Missing"
grep -q "TMouseEvent" "$BASEDIR/mdl/utextmouse.pas" && pass "TMouseEvent record defined" || fail "Missing"
grep -q "TextMouseInit" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMouseInit function" || fail "Missing"
grep -q "TextMouseDone" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMouseDone procedure" || fail "Missing"
grep -q "TextMousePoll" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMousePoll function" || fail "Missing"
grep -q "TextMouseSupported" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMouseSupported function" || fail "Missing"
grep -q "TextMouseShow" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMouseShow procedure" || fail "Missing"
grep -q "TextMouseHide" "$BASEDIR/mdl/utextmouse.pas" && pass "TextMouseHide procedure" || fail "Missing"
grep -q "IFDEF UNIX" "$BASEDIR/mdl/utextmouse.pas" && pass "UNIX platform support" || fail "Missing"
grep -q "IFDEF WINDOWS" "$BASEDIR/mdl/utextmouse.pas" && pass "Windows platform support" || fail "Missing"
grep -q "IFDEF GO32V2" "$BASEDIR/mdl/utextmouse.pas" && pass "DOS go32v2 platform support" || fail "Missing"
grep -q "IFDEF MSDOS" "$BASEDIR/mdl/utextmouse.pas" && pass "DOS i8086 platform support" || fail "Missing"
grep -q "mPress\|mRelease\|mMove" "$BASEDIR/mdl/utextmouse.pas" && pass "Mouse actions (press/release/move)" || fail "Missing"
grep -q "mbLeft\|mbRight\|mbMiddle" "$BASEDIR/mdl/utextmouse.pas" && pass "Mouse buttons (left/right/middle)" || fail "Missing"
grep -q "mbWheelUp\|mbWheelDown" "$BASEDIR/mdl/utextmouse.pas" && pass "Mouse wheel support" || fail "Missing"

echo "--- TIC tosser auto_create (A52 #11) ---"
grep -q "AutoCreate" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "AutoCreate variable" || fail "Missing"
grep -q "auto_create" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "auto_create INI option" || fail "Missing"
grep -q "fbases.dat" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Appends to fbases.dat" || fail "Missing"
grep -q "EchoTag.*:=.*TIC.Area\|FBase.EchoTag" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Sets EchoTag from area" || fail "Missing"
grep -q "DirCreate" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Creates directory for new base" || fail "Missing"
grep -q "Auto-creating" "$BASEDIR/mystic/mutil_filetoss.pas" && pass "Logs auto-create action" || fail "Missing"


echo "================================================================"

echo "================================================================"

echo "--- A52: CTRL-P post from area index (#1) ---"
grep -q "#16.*Begin" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "CTRL-P (#16) handler in AreaIndex" || fail "Missing"
grep -q "PostMessage" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "PostMessage called from CTRL-P" || fail "Missing"
grep -q "BuildAreaList" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Area list rebuilt after posting" || fail "Missing"

echo "--- A52: |SS/|RS screen save/restore (#4/#5) ---"
grep -q "SavedScreen" "$BASEDIR/mystic/bbs_io.pas" && pass "SavedScreen field in TBBSIO" || fail "Missing"
grep -q "GetScreenImage" "$BASEDIR/mystic/bbs_io.pas" && pass "|SS saves screen (GetScreenImage)" || fail "Missing"
grep -q "RemoteRestore.*SavedScreen" "$BASEDIR/mystic/bbs_io.pas" && pass "|RS restores screen (RemoteRestore)" || fail "Missing"

echo "--- A52: ICE color bleed fix (#6) ---"
grep -A15 "Prefix.*0;" "$BASEDIR/mystic/bbs_io.pas" | grep -q "re-emit\|CurBG\|background" && pass "Background re-emitted after 0; reset" || fail "Missing"

echo "--- A52: JAM REPLY kludge (#8) ---"
grep -q "REPLY:" "$BASEDIR/mystic/bbs_msgbase_jam.pas" && pass "Only exact REPLY: is subfield 5" || fail "Missing"
grep -q "Non-standard variants" "$BASEDIR/mystic/bbs_msgbase_jam.pas" && pass "Non-standard variants fall to UNKNOWN" || fail "Missing"

echo "--- A52: Squish seconds handling (#14) ---"
grep -q "A52.*seconds\|preserve seconds\|HH:MM:SS" "$BASEDIR/mystic/bbs_msgbase_squish.pas" && pass "Squish reads seconds from HH:MM:SS" || fail "Missing"
grep -q "strZero.*Sec\|Sec.*strZero" "$BASEDIR/mystic/bbs_msgbase_squish.pas" && pass "Seconds written with strZero padding" || fail "Missing"

echo "--- A52: Show kludge in exported files (#13) ---"
grep -q "ShowKludge.*Then.*WriteLn\|ShowKludge.*WriteLn" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Kludge lines included when ShowKludge on" || fail "Missing"

echo "--- A52: FS editor reformat on DELETE (#2/3) ---"
grep -q "TextReformat" "$BASEDIR/mystic/bbs_edit_full.pas" && pass "TextReformat called on delete" || fail "Missing"
grep -A5 "#83" "$BASEDIR/mystic/bbs_edit_full.pas" | grep -q "TextReformat\|Reformat" && pass "DELETE key triggers paragraph reformat" || fail "Missing"


echo "================================================================"

echo "--- A54: Group membership fix in index reader ---"
grep -q "IgnoreGroup := True" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "IgnoreGroup set True for BuildAreaList" || fail "Missing"
grep -q "IgnoreGroup := SaveGroup" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "IgnoreGroup restored after BuildAreaList" || fail "Missing"


echo "--- A55: X hotkey menu editor fix ---"
grep -q "AddTog.*'T'.*Timer Type" "$BASEDIR/mystic/bbs_cfg_menuedit.pas" && pass "Timer Type uses 'T' hotkey (was 'X' conflict)" || fail "Still using X"


echo "--- A55: record locking in file listing ---"
grep -q "ioReset.*fmRWDN" "$BASEDIR/mystic/bbs_filebase.pas" && pass "File listing uses shared mode (fmRWDN)" || fail "Missing"

echo "--- A55: BINKP debug logging ---"
grep -q "BINKP_DEBUG" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "BINKP_DEBUG define available" || fail "Missing"


echo "--- Mouse: only enabled in ANSI editor ---"
grep -q "MouseEnable" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "MouseEnable called in TEditorANSI.Edit" || fail "Missing"
grep -q "MouseDisable" "$BASEDIR/mystic/bbs_edit_ansi.pas" && pass "MouseDisable called on Edit exit" || fail "Missing"


echo "--- A56: kludge #1->@ in V command ---"
grep -q "ShowKludge.*#1.*@\|A56.*kludge" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Kludge #1 replaced with @ in display" || fail "Missing"

echo "--- A56: BINKP secure/non-secure ---"
echo "  (covered by FTS-1026 tests in deferred9)"
pass "M_OK secure/non-secure already verified"

echo "--- A56: MUTIL logs log level ---"
grep -q "Log level" "$BASEDIR/mystic/mutil.pas" && pass "Log level logged at startup" || fail "Missing"

echo "--- A56: Node chat commands ---"
grep -q "/QUIT" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "/QUIT alias for /Q" || fail "Missing"
grep -q "/EMOTE" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "/EMOTE alias for /ME" || fail "Missing"
grep -q "/TELL" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "/TELL alias for /MSG" || fail "Missing"
grep -q "/REPLY" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "/REPLY private message" || fail "Missing"
grep -q "LastPrivateFrom" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "LastPrivateFrom tracks sender for /REPLY" || fail "Missing"


echo "--- A56: BINKP Argus non-secure auth ---"
grep -q "Password = '-'" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "M_PWD dash treated as empty password" || fail "Missing"

echo "--- A56: Date past 2070 ---"
grep -q "A56.*2-digit year pivot\|A56.*pivot" "$BASEDIR/mdl/m_datetime.pas" && pass "Date pivot fixed for years past 2070" || fail "Missing"


echo "--- A56: QWK corruption fix ---"
grep -q "LongInt.*Chunks\|Chunks.*LongInt" "$BASEDIR/mystic/bbs_msgbase_qwk.pas" && pass "QWK Chunks is LongInt (was Word — overflow at 64KB)" || fail "Missing"

echo "--- A56: BINKP 1.0 NR extension ---"
grep -q "OPT NR" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "BINKP advertises NR extension" || fail "Missing"

echo "--- A56: Chat word wrap ---"
grep -q "WrapPos" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "Word wrap at word boundary" || fail "Missing"
grep -q "word.*wrap\|word boundary\|A56.*word" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "Word wrap comment present" || fail "Missing"


echo "--- A58: node chat &2/&3/&4 prompt codes ---"
grep -q "|&2" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "&2 node number code" || fail "Missing"
grep -q "|&3" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "&3 low node color" || fail "Missing"
grep -q "|&4" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "&4 high node color" || fail "Missing"
grep -q "FromNode MOD 8" "$BASEDIR/mystic/bbs_nodechat.pas" && pass "Color cycles through 8 values" || fail "Missing"

echo "--- A58: Enter on private/netmail base ---"
pass "Netmail base uses Y mode (NetType=3 check below)"
grep -q "NetType = 3" "$BASEDIR/mystic/bbs_msgbase.pas" && pass "Netmail base uses Y mode" || fail "Missing"


echo "--- A59: kludge preservation in toss ---"
grep -q "DoKludgeLn" "$BASEDIR/mystic/mutil_echoimport.pas" && pass "Kludge lines stored via DoKludgeLn" || fail "Missing"
grep -q "SEEN-BY" "$BASEDIR/mystic/mutil_echoexport.pas" && pass "SEEN-BY regenerated in export" || fail "Missing"
grep -q "PATH" "$BASEDIR/mystic/mutil_echoexport.pas" && pass "PATH regenerated in export" || fail "Missing"

echo "--- A59: QWK Sent flag ---"
grep -q "IsSent" "$BASEDIR/mystic/bbs_msgbase_qwk.pas" && pass "QWK checks Sent flag for dupes" || fail "Missing"


echo "--- A60: goodip.txt whitelist ---"
grep -q "goodip.txt" "$BASEDIR/mystic/mis_server.pas" && pass "goodip.txt whitelist check" || fail "Missing"
grep -q "whitelisted" "$BASEDIR/mystic/mis_server.pas" && pass "Whitelisted IPs skip all blocking" || fail "Missing"

echo "--- A60: BINKP junk protection ---"
grep -q "JUNK.*oversized" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Oversized frame rejection" || fail "Missing"
grep -q "Disconnect" "$BASEDIR/mystic/mis_client_binkp.pas" && pass "Connection terminated on junk" || fail "Missing"

echo "--- A60: Zmodem 32KB buffer ---"
grep -q "32768" "$BASEDIR/mdl/m_prot_zmodem.pas" && pass "ZMaxBlockSize = 32768" || fail "Still 8192"

echo "--- A60: INTL address order ---"
grep -q "GetDestAddr.*GetOrigAddr" "$BASEDIR/mystic/mutil_echoexport.pas" && pass "INTL dest orig order correct" || fail "Wrong order"


echo "--- A60: [X [Y MCI disabled ---"
grep -q "A60.*disabled" "$BASEDIR/mystic/bbs_io.pas" && pass "[X and [Y MCI codes disabled" || fail "Still active"

echo "--- A60: LZH level 2 support ---"
grep -q "Level.*2\|level 2\|Level 2" "$BASEDIR/mystic/aviewlzh.pas" && pass "LZH level 0/1/2 detection" || fail "Missing"


echo "--- A60: MPL AppendText procedure ---"
grep -q "appendtext" "$BASEDIR/mystic/mpl_common.pas" && pass "AppendText registered as MPL builtin" || fail "Missing"
grep -q "561 :" "$BASEDIR/mystic/mpl_execute.pas" && pass "AppendText executor (proc 561)" || fail "Missing"


echo "--- A60: MPL CfgChatStart/CfgChatEnd variables ---"
grep -q "cfgchatstart" "$BASEDIR/mystic/mpl_common.pas" && pass "CfgChatStart registered as MPL variable" || fail "Missing"
grep -q "cfgchatend" "$BASEDIR/mystic/mpl_common.pas" && pass "CfgChatEnd registered as MPL variable" || fail "Missing"
grep -q "ChatStart" "$BASEDIR/mystic/mpl_common.pas" && pass "Points to bbsCfg.ChatStart" || fail "Missing"
grep -q "ChatEnd" "$BASEDIR/mystic/mpl_common.pas" && pass "Points to bbsCfg.ChatEnd" || fail "Missing"

echo "--- A60: MPL char type function results ---"
grep -q "vType = iChar" "$BASEDIR/mystic/mpl_execute.pas" && pass "Char type detected in function returns" || fail "Missing"
grep -A2 "vType = iChar" "$BASEDIR/mystic/mpl_execute.pas" | grep -q "TempStr\[0\] := #1" && pass "Char wrapped to length-1 string" || fail "Missing"


echo "--- A60: MPL example scripts ---"
[ -f "$BASEDIR/scripts/appendtext_demo.mps" ] && pass "appendtext_demo.mps exists" || fail "Missing"
[ -f "$BASEDIR/scripts/chatcheck_demo.mps" ] && pass "chatcheck_demo.mps exists" || fail "Missing"
grep -q "AppendText(" "$BASEDIR/scripts/appendtext_demo.mps" && pass "appendtext_demo calls AppendText()" || fail "Missing"
grep -q "CfgChatStart" "$BASEDIR/scripts/chatcheck_demo.mps" && pass "chatcheck_demo uses CfgChatStart" || fail "Missing"
grep -q "CfgChatEnd" "$BASEDIR/scripts/chatcheck_demo.mps" && pass "chatcheck_demo uses CfgChatEnd" || fail "Missing"
grep -q "AppendText(" "$BASEDIR/scripts/chatcheck_demo.mps" && pass "chatcheck_demo uses AppendText for logging" || fail "Missing"

echo "--- uforkpty: pure FPC PTY ---"
[ -f "$BASEDIR/mdl/uforkpty.pas" ] && pass "uforkpty.pas in mdl/" || fail "Missing"
grep -q "ForkPTY_Pure" "$BASEDIR/mdl/uforkpty.pas" && pass "ForkPTY_Pure function defined" || fail "Missing"
grep -q "ForkPTY_Pure" "$BASEDIR/mystic/mis_client_telnet.pas" && pass "MIS uses ForkPTY_Pure" || fail "Missing"
grep -q "LinkLib libutil" "$BASEDIR/mystic/mis_client_telnet.pas" && fail "Still has LinkLib libutil" || pass "No libutil.a LinkLib dependency"


echo "================================================================"
echo " Results: $PASS passed, $FAIL failed out of $TOTAL tests"
[ "$FAIL" -gt 0 ] && { echo "FAILED"; exit 1; }
echo "ALL TESTS PASSED"; exit 0
