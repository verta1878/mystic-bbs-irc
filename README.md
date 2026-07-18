# Mystic BBS 1.10 A38irc-A63 — Community Fork (IRC)

> **Release: 2026-07-18** — base **Mystic 1.10 A38irc-A63**, with all
> **A41–A63 + final 1.10** features ported from g00r00's whatsnew.
> BINKP FTS-1026 compliant. TIC file tosser per FTS-5006.001. Built-in
> ZIP archiver (marc). System tray support (utrayit). RIPscrip v1.54
> integration. Builds **7/7 core + 27/27 mdl/** with
> **FPC 2.6.4irc r5.1** across 6 targets.

A community fork of the **Mystic BBS 1.10 Alpha 38** source, released under the
**GNU General Public License v3**. The goal is a clean, buildable, well-documented
tree that the BBS scene can build, run, study, and carry forward.

Mystic BBS is Copyright 1997-2013 by James Coyle (g00r00). This fork preserves
that attribution and all GPL notices; see [COPYING](COPYING).

*Maintained by Antonio Rico (Reapern66) — Ecstasy BBS, FTN node 152/158, tnabbs.org*

## Compiler

**FPC 2.6.4irc r5.1** (fork: [verta1878/fpc264irc](https://github.com/verta1878/fpc264irc))

- Native linker fixed for modern binutils (ld stall bug)
- Prebuilt PPUs for md5/crc/zipper/netdb/process
- cNetDB retired; migrated to pure-Pascal `netdb` unit
- `fpSetEUID`/`fpSetEGID` wrappers in source (PPU rebuild pending)
- 7-platform cross-compiler: i386-linux, i386-win32, i386-go32v2, i386-os2, i386-freebsd, x86_64-linux, i8086-msdos

## Build Targets

| Target | Status | Notes |
|--------|--------|-------|
| `mystic` | ✅ 7/7 | BBS server |
| `mis` | ✅ | Internet Server (with utrayit tray support) |
| `mutil` | ✅ | Mail utilities (with TIC file tosser) |
| `mplc` | ✅ | MPL compiler |
| `fidopoll` | ✅ | FidoNet poller (extended commands) |
| `qwkpoll` | ✅ | QWK poller |
| `maketheme` | ✅ | Theme compiler |
| `marc` | ✅ | Built-in ZIP archiver + media tags (objfpc) |
| mdl/ | ✅ 27/27 | Core library (with SDL/SDL_TTF headers) |
| mystic_rip/ | ✅ 13/13 | RIPscrip engine + tools |

## Alpha Features Ported (A41–A63)

### A41 — FidoNet Enhancements (11 items) ✅
CTRL-A→@ in quotes, FMPT/TOPT kludges, PKT passwords (export+import),
ESC in address picker, MIS event fixes, file base EchoTag+NetAddr,
full FileFix subsystem (%HELP/%PWD/%LIST/%LINKED/%UNLINKED/+TAG/-TAG).

### A42 — Protocol Fixes (5 items) ✅
BINKP CRAM-MD5 ARGUS null terminator fix, FIDOPOLL echomail.in semaphore,
|DF MCI nested display, QWKPOLL corrupt message fix, BINKP domain strip.

### A43 — Import & Display (3 items) ✅
Event editor crash fix, twit filter (100 names), Hide AKA uses domain.

### A44 — FidoNet Mail Engine (7 items) ✅
TID local-only (IsLocal param), SEEN-BY all downlinks (.lnk scan),
BINKP correct file dates (was March 2013!), outbound FileBoxes,
additional import logging, area index network category sort fix.

### A45 — Server & Console (6 items) ✅
FIDOPOLL LIST/ROUTE, UID/GID privilege drop (SetUserOwner), `*.pkt`
extraction, console DELETE/BACKSPACE detection (fpIOCtl TIOCGPGRP).

### A46 — TIC/FDN File Tosser ✅
`mutil_filetoss.pas` — complete file-echo tosser per **FTS-5006.001** and
**FSC-0087.001**. Parses all TIC keywords, CRC-32 verification, area tag
matching, file import with descriptions, downlink forwarding with
PATH/SEENBY, unsecure inbound scanning. mutil.ini `[ImportFileToss]`.

### A47 — Auto-Create (1 item done) ✅
PKT dest AKA for auto-create bases.

### A48 — BINKP Reliability ✅
Timeout timer resets on every data block sent AND received during transfers.
Prevents random disconnects on large files (**FTS-1026.001 §6**).

### A49 — FTP QWK ✅
`inetFTPHideQWK` wired at 3 points in LIST/NLST (**RFC 959**).

### A50 — FIDOPOLL Extended ✅
FIDOPOLL FORCED [type] filter with ParseTypeFilter.

### A51 — Server Stability (7 items) ✅
- **Auto-ban IP**: rate tracking per IP, configurable via `mystic -cfg`
  (Auto-ban Conns / Auto-ban Secs, 0=off). Wired to all 6 MIS servers.
- **MIS crash fix**: Try/Finally critical sections, ClientList protection,
  Destroy safe-nil pattern. Applied to both `m_socket_server.pas` and
  `mis_server.pas`.
- **Socket shutdown flush**: half-close (SHUT_WR) + drain (**RFC 793 §3.5**).
- **CTRL+U lastread**: updates to last message in area index reader.
- **ICE color bleed fix**: re-emit background after `0;` SGR reset.

### A52 — Full Feature Set (13 of 14) ✅
- CTRL-P post from area index reader
- |SS/|RS MCI screen save/restore
- FS editor auto-reformat on DELETE
- JAM REPLY kludge (only `REPLY:` = subfield 5, variants → UNKNOWN)
- Unsecured BINKP server (files → UnsecurePath when `inetBINKPUnsecure`)
- Squish seconds handling
- Show kludge in exported files (when ShowKludge on)
- FTP Firefox login fix (331 for all USER commands)
- PKT V2+ zone preference
- MUTIL unsecure_dir for echomail import
- FileToss unsecure_dir (via TIC tosser)
- INS key verified (toggles INS/OVR display in FS editor)
- Only deferred: FileToss auto_create (cosmetic)

## BINKP FTS-1026 Compliance

| Requirement | Status |
|-------------|--------|
| M_OK "secure" on password match | ✅ |
| M_OK "non-secure" for unsecured session | ✅ |
| M_ERR "Incorrect password" on failure | ✅ |
| M_PWD "-" for no password | ✅ |
| CRAM-MD5 challenge via M_NUL OPT | ✅ |
| File dates as unixtime in M_FILE | ✅ |
| Timeout reset during active transfer | ✅ |

## New Features (Fork)

### marc — Built-in ZIP Archiver
Standalone pure-Pascal ZIP archiver + MP3 ID3v2/v1 + MP4 codec tag reader.
Commands: `a` (pack), `x` (unpack), `l` (list), `m` (media tags).
ExecuteArchive tries marc first, falls back to external archiver.

### utrayit — System Tray Support
MIS `-T` flag minimizes to system tray (Windows) or iconifies terminal (Unix).
Cross-platform: Windows notification area, xterm XTWINOPS, DOS/OS2 stubs.

### Extended fidopoll
Commands: SEND, FORCED [Type], UPLINK [Type], [Address], LIST, ROUTE [Address],
SEARCH [Text], KILLBUSY [Mode].

### TEditorANSI — ANSI Art Editor
CIADraw-style ANSI editor integrated into `-cfg`. File load/save, draw mode,
read-only viewer (log files). Accessible from Configuration menu.

### RIPscrip v1.54
Server-side integration: auto-detection, .rip file resolution, |RI MCI code,
menu display with ANSI fallback, door drop files report GR for RIP.

## Test Suites

| Suite | Tests | Status |
|-------|-------|--------|
| `tests/marc/run.sh` | ZIP round-trip, FILE_ID.DIZ, FidoNet .pkt, QWK | ✅ |
| `tests/deferred9/run.sh` | 54 tests across 9 items, FTS/FSC/RFC verified | ✅ 54/54 |
| `tests/a53/run.sh` | 98 tests: A52-A56 + CIADraw + utrayit + mouse + modem | ✅ 98/98 |
| `tests/a40/run.sh` | Record anchors, log stamps | ✅ |

## FTS/FSC/RFC References

| Feature | Spec |
|---------|------|
| BINKP protocol | FTS-1026.001 |
| TIC file tosser | FTS-5006.001, FSC-0087.001 |
| PKT format | FTS-0001.016 |
| PKT Type 2+ | FSC-0039.004, FSC-0048 |
| EchoMail (SEEN-BY, PATH) | FSC-0074 |
| FTP server | RFC 959 |
| Socket close | RFC 793 §3.5 |

## Directory Structure

```
mystic/          BBS source (7 core targets + support units)
mdl/             Core library (sockets, strings, I/O, crypto, protocols)
mystic_rip/      RIPscrip engine, tools, examples
mystic_sdl/      SDL2 bindings (optional, for RIP viewer)
libs/            Third-party libraries and cross-compile tools
docs/            Documentation, patches, whatsnew
tests/           Test suites (marc, deferred9, a40)
retired/         Retired source files
```

## License

GNU General Public License v3.0 — see [COPYING](COPYING).

New files by the fork maintainer: Copyright 2026 by Antonio Rico.
Original Mystic BBS: Copyright 1997-2013 by James Coyle.


## Build & Release

### Build scripts
- `build-linux.sh` — 15/15 ELF 32-bit linked
- `build-win32.sh` — 15/15 PE32 .exe cross-compiled
- `build-dos.sh` — 9/9 DOS go32v2
- `build-os2.sh` — compiles, EMX linker needs emxbind

### Release scripts
- `make_release.sh` — builds FULL + UPD packages for all platforms
- `make_install_data.sh` — builds `install_data.mys` from a Mystic directory
- `make_all_releases.sh` — builds all platforms at once

### Package types
- **FULL** (5 files): `install` + `install_data.mys` + `COPYING` + `FILE_ID.DIZ` + `whatsnew.txt`
- **UPD** (20 files): all 15 binaries + `install_data.mys` + `COPYING` + `FILE_ID.DIZ` + `whatsnew.txt` + `upgrade.txt`

### Cross-compile status (fpc264irc r5.1)
| Platform | Build | Link | Notes |
|----------|-------|------|-------|
| Linux i386 | 15/15 ✅ | 15/15 ✅ | — |
| Windows | 15/15 ✅ | 15/15 ✅ | — |
| DOS go32v2 | 9/9 ✅ | 9/9 ✅ | — |
| OS/2 EMX | ✅ compiles | ⚠️ emxbind | Needs emxl.exe |
| FreeBSD | 3/15 | 3/15 | m_ops.pas fixed, console units need work |
| Darwin | — | — | Missing base RTL PPUs |

### New subsystems
- `uforkpty.pas` — pure FPC forkpty(), zero libc dependency
- `utextmouse.pas` — xterm/Win32/INT 33h mouse (ANSI editor only)
- `mutil_filetoss.pas` — TIC tosser per FTS-5006.001
- `netmodem_fossil.pas` — FOSSIL INT 14h serial test for DOS

### Documentation
- `docs/INSTALL-MAKE.md` — how to build install_data.mys
- `docs/CREATING-THE-INSTALLER.md` — full installer/release workflow
- `docs/BUILDING.md` — build instructions
