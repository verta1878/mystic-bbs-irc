# Mystic BBS 1.10IRC — Release Notes

**Release: July 2026**
**Status: Alpha Testing**
**Base: Mystic BBS 1.10 Alpha 38 GPL Source**
**Compiler: FPC 2.6.4irc r3.1+**
**License: GNU General Public License v3**

## What is 1.10IRC?

A community fork of Mystic BBS maintained by Antonio Rico (Reapern66),
Ecstasy BBS, FTN node 1:152/158. All alpha patches A41 through A63
ported from g00r00's official releases. Built with the fpc264irc
community compiler fork.

## New Features

### RIPscrip Rendering Engines (v1-v4)
- v1: Complete RIPscrip 1.54 — 51 commands, 16-color EGA, CHR fonts
- v2: 256-color, 1280x1024, JPEG/PNG, WAV streaming
- v3: 16M TrueColor, 11 image formats, MIDI FM synth, 4-stream audio
- v4: HTML 1.0 renderer, MPEG-1 video, Print API, Unicode/TTF, FLI/FLC
- 1,433 automated tests across all engines
- All codec filenames DOS 8.3 compliant

### Internal File Transfer Protocols
- Xmodem (CRC-16, 1K blocks)
- Ymodem (batch, Block 0 file info)
- Ymodem-G (streaming, no per-block ACK)
- Zmodem (1K, 8K, 32K blocks, CRC-32, crash recovery)
- Kermit (7-bit safe, CRC-16, parameter negotiation)
- HS/Link source archived as reference (GPLv3, Pascal port planned)

### HTTP File Server
- Built into MIS on port 8080
- Serves static web pages from webroot/ directory
- File downloads via FTP Name mapping
- HTTP/1.0, Content-Type detection, path traversal protection

### FTP Server Fixes
- SIZE command implemented (was "not implemented")
- REST command added for resume support
- PASV endian fix for passive mode
- SendFile error handling improved

### Media Support
- MediaTag unit: reads MP3 (ID3v1/v2) and MP4 (iTunes atoms) metadata
- AViewMeta: media tag viewer integrated into BBS file base
- MARC archiver: internal ZIP pack/unpack/list + media tag display

## Ported Alpha Patches (A41-A63)

### A41-A44 (27 items)
Initial port — FPC build fixes, platform detection, record alignment

### A45-A50 (38 items)
BINKP improvements, FidoNet compliance, socket fixes

### A51 (4 items)
Auto-ban, MIS crash fix, socket flush, CTRL+U

### A52 (14 items)
CTRL-P, |SS/|RS MCI codes, BINKP resume, mouse infrastructure

### A53 (13 items)
Area snap, pipe strip, group_list

### A54 (1 item)
IgnoreGroup restore

### A55 (4 items)
Record locking, X hotkey, BINKP_DEBUG

### A56 (17 items)
Argus auth, date 2070, BINKP NR, chat commands

### A58 (4 items)
Node chat colors, private base Enter

### A59 (3 items)
Kludge preservation, QWK Sent flag

### A60 (12 items)
goodip.txt whitelist, BINKP junk protection, Zmodem 32KB,
MPL AppendText, CfgChatStart/CfgChatEnd, LZH/LHA viewer

### A61 (16 items)
Output buffering, @TEXTDIZ/@TEXTVIEW/@TEXTSHOW, DI baud rates,
hourly events, DOS CRLF export, 80-char auto-wrap fix

### A62-A63
Version-bumped to 1.10IRC final. No code changes.

## New Subsystems
- uforkpty.pas: pure FPC forkpty() — no libc dependency
- mutil_filetoss.pas: TIC file tosser (FTS-5006.001/FSC-0087)
- netmodem_fossil.pas: FOSSIL INT 14h serial test for DOS

## Bug Fixes
- BUG-038: RIPscrip decimal vs MegaNum range error (RESOLVED)
- BUG-029: AnsiString concat crash under {$H-} on Win32 (FIXED)
- PASV endian fix in FTP server
- FTP SIZE/REST implementation
- HTTP header ShortString overflow fix

## Build Platforms
- Linux i386: 15/15 binaries
- Windows PE32: 15/15 cross-compiled
- DOS go32v2: 9/9 binaries
- OS/2 EMX: compiles, needs emxbind

## Known Issues
- default.txt prompt count must match mysMaxThemeText (515)
- HTTP server port 8080 hardcoded (no config UI yet)
- FTP download prompt (528-531) not wired into file base yet
- Web download option ([W]) not implemented (HTTP stub was empty)
- MPL scripts may need recompilation after upgrade

## Next Version: 1.11IRC

Roadmap:
- MDL refactor (replace mdl wrappers with FPC RTL)
- HS/Link Pascal port (clean-room from HDK spec)
- FTP/Web download prompt wiring
- HTTP server configuration in mystic.dat
- Protocol menu strings in language file

## Credits
- g00r00 (James Coyle) — original Mystic BBS author
- Antonio Rico (Reapern66) — fork maintainer
- evga — contributor
- fpc264irc maintainers — compiler fork
- Samuel Smith — HS/Link protocol (GPLv3 re-release)

## Links
- Source: https://github.com/verta1878/mystic-bbs-irc
- Compiler: https://github.com/verta1878/fpc264irc
- FTN: 1:152/158 (Ecstasy BBS)
