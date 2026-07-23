# Mystic Source Cleanup Status

## mdl/ — Mystic Development Library
Compiles 44/46 on Linux (2 Windows-only expected).

### Completed
- SDL files → mystic_sdl/
- BinkP programs → mystic/
- uforkpty → inlined into mis_client_telnet.pas
- m_sdlcrt → mystic_sdl/
- utextmouse → attic (unused)

### Deferred
- MDL refactor Phase 1: MIS — replace mdl wrappers with FPC RTL
- MDL refactor Phase 2: BBS core — same replacements across 50+ files
- MDL refactor Phase 3: Clean mdl — delete replaced units
- See docs/MDL-REFACTOR-PLAN.md

## mystic/ — BBS Core

### Completed
- Protocols wired: Xmodem, Ymodem, Ymodem-G, Zmodem, Zmodem-8K, Zmodem-32K, Kermit
- All protocols in m_protocol_*.pas (OOP stack)
- FTP server fixed: SIZE, REST/resume, PASV endian, WriteBuf hang
- HTTP server added: 262 lines, port 8080, webroot/ serving
- AViewMeta wired for MP3/MP4 tag viewing in file base
- default.txt replaced with g00r00 v1.12 prompts (554 prompts)
- BUG-029 AnsiString crash fixed (Header: AnsiString in HTTP)
- uforkpty inlined into mis_client_telnet.pas
- BinkP moved from mdl/ to mystic/
- mis.exe Win32 cross-compile working

### Needs Testing
- mis.exe BUG-029 fix verification on Windows
- HTTP server on real Mystic install
- Protocol transfers (Xmodem/Ymodem/Kermit) end-to-end

### Not Yet Wired
- FTP download prompt (528/529) in bbs_filebase.pas
- Protocol menu strings in protocol.dat
- HS/Link Pascal port
- Web download ([W] option — HTTP stub was empty)

### TODO — BBS Core Source Cleanup
- [ ] Review whatsnew.txt A61 items against source
- [ ] Check all A41-A63 ported items compile clean
- [ ] Audit mystic/*.pas for stale code
- [ ] Verify build scripts work
- [ ] Clean out-win32/ build artifacts
- [ ] Review mystic_test/ vs mystic/ for drift
- [ ] Remove stale .a library files
- [ ] Verify all 15 Linux binaries build
- [ ] Verify all 15 Win32 binaries build
- [ ] Verify 9 DOS binaries build
