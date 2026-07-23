# Mystic BBS 1.10 A38irc-A63 — Community Fork (IRC)

> **Release: 2026-07-22** — Mystic 1.10 A38 fork with A41–A63 ported.
> BINKP FTS-1026 compliant. TIC file tosser (FTS-5006.001).
> RIPscrip v1–v4 server-side rendering engines.
> Built with **FPC 2.6.4irc r3.1+**.

A community fork of **Mystic BBS 1.10 Alpha 38** source, released under the
**GNU General Public License v3**. Maintained by Antonio Rico (Reapern66),
Ecstasy BBS, FTN node 1:152/158.

## RIPscrip Rendering Engines

All seven TeleGrafix whitepaper "Future Goals" implemented. 1,433 tests passing.

| Engine | Lines | Tests | Features |
|--------|-------|-------|----------|
| v1 (ripscr.pas) | 4,041 | 97/97 | RIPscrip 1.54 — 51 commands, EGA 16-color, CHR fonts |
| v2 (rip2api.pas) | 5,304 | 115/115 | 256-color, 1280x1024, RFF fonts, JPEG/PNG, WAV streaming |
| v3 (rip3api.pas) | 8,294 | 592/592 | 16M TrueColor, world coords, 11 image formats, MIDI FM synth |
| v4 (rip4api.pas) | 8,572 | 629/629 | HTML 1.0, MPEG-1 video, Print API, Unicode/TTF, FLI/FLC |

### v4.0 Highlights

- **HTML 1.0** — 44-tag parser, DOM tree, box model layout, pixel renderer
- **Print API** — 6 drivers: ESC/P, PCL, PostScript, BMP, Raw
- **MPEG-1 Video** — demuxer, I/P/B decoder, YUV→RGB, A/V sync
- **Unicode** — CP437↔UTF-8, TTF glyph loader, UTF-8 renderer
- **FLI/FLC** — Autodesk animation decoder (7 chunk types)
- **FONT COLOR/SIZE** — #RRGGBB + 10 named colors, BODY BGCOLOR
- **TABLE columns** — equal-width layout, INPUT/SELECT/TEXTAREA rendering
- **IMG loading** — JPG/PNG/GIF/BMP/PCX by extension
- **A HREF** — creates RIP mouse fields for click regions
- **ASM fast paths** — JPEG IDCT, MP3 IMDCT/synthesis, audio mixing (i386 + Pascal fallback)
- **MegaNum** — standalone base-36 encoder/decoder
- **Editor: RIPforge** (planned)

### Codec Totals

| Engine | img/ | wav/ | prg/ | prn/ | pasjpeg/ | Total |
|--------|------|------|------|------|----------|-------|
| v1 | — | — | — | — | — | 1 |
| v2 | 2 | 8 | — | — | 58 | 68 |
| v3 | 22 | 39 | 6 | — | 58 | 125 |
| v4 | 32 | 44 | 6 | 6 | 58 | 146 |

All codec filenames DOS 8.3 compliant. Pure Pascal. Zero dependencies.

## Alpha Porting Status

| Alpha | Items | Status |
|-------|-------|--------|
| A41–A44 | 27 | ✅ Complete |
| A45–A50 | 38 | ✅ Complete |
| A51 | 4 | ✅ Auto-ban, MIS crash fix, socket flush, CTRL+U |
| A52 | 14 | ✅ CTRL-P, |SS/|RS, BINKP resume, mouse infra |
| A53 | 13 | ✅ Area snap, pipe strip, group_list |
| A54 | 1 | ✅ IgnoreGroup restore |
| A55 | 4 | ✅ Record locking, X hotkey, BINKP_DEBUG |
| A56 | 17 | ✅ Argus auth, date 2070, BINKP NR, chat commands |
| A57 | 1 | N/A (packaging fix) |
| A58 | 4 | ✅ Node chat colors, private base Enter |
| A59 | 3 | ✅ Kludge preservation, QWK Sent flag |
| A60 | 12 | ✅ goodip.txt, BINKP junk, Zmodem 32KB, MPL AppendText |
| A61 | 16 | ✅ Output buffering, DI baud, hourly events, 80-char wrap |
| A62–A63 | — | Version-bumped, items deferred |

## File Transfer Protocols

| Protocol | File | Status |
|----------|------|--------|
| Xmodem | m_protocol_xmodem.pas | Full (CRC-16, 1K) |
| Ymodem | m_protocol_ymodem.pas | Full (batch, Block 0) |
| Ymodem-G | m_protocol_ymodem.pas | Full (streaming) |
| Zmodem | m_protocol_zmodem.pas | Full (1K/8K/32K, CRC-32, crash recovery) |
| Kermit | m_protocol_kermit.pas | Full (7-bit safe, CRC-16) |
| HS/Link | examples/hslink-src/ | Reference (GPLv3, needs Pascal port) |

## MIS Servers

| Server | Port | Status |
|--------|------|--------|
| Telnet | 23 | Working |
| FTP | 21 | Working (SIZE/REST/PASV fixed) |
| HTTP | 8080 | New — serves webroot/ + file downloads |
| SMTP | 25 | Working |
| POP3 | 110 | Working |
| NNTP | 119 | Working |
| BINKP | 24554 | Working |

## Build Status

| Platform | Build | Link | Notes |
|----------|-------|------|-------|
| Linux i386 | 15/15 ✅ | 15/15 ✅ | — |
| Windows | 15/15 ✅ | 15/15 ✅ | Wine-tested |
| DOS go32v2 | 9/9 ✅ | 9/9 ✅ | — |
| OS/2 EMX | ✅ compiles | ⚠️ | emxbind needs emxl.exe |
| FreeBSD | 3/15 | 3/15 | Console unit differences |
| Darwin | — | — | Missing base RTL PPUs |

## Directory Structure

```
mystic/              Core BBS source (Pascal)
mdl/                 Mystic Development Library
mystic_ripapi/       RIPscrip v1.54 engine (ripscr.pas)
mystic_ripapi2/      RIPscrip v2.0 engine (rip2api.pas)
mystic_ripapi3/      RIPscrip v3.0 engine (rip3api.pas)
mystic_ripapi4/      RIPscrip v4.0 engine (rip4api.pas)
mystic_rip/          RIP viewer/parser
mystic_sdl/          SDL2 screen rendering
mystic_crypt/        CryptLib SSH/TLS binding (runtime loaded)
mystic_spell/        Hunspell spell check binding (runtime loaded)
mystic_modem/        Modem/FOSSIL driver
mystic_mailer/       BINKP/FidoNet mailer
mystic_misdos/       DOS MIS (Mystic Internet Server)
mystic_test/         Integration workspace
examples/rip/        v1 RIP parser, viewer, demo
examples/rip2/       v2 RIP parser, viewer, demo
examples/ripterm154/ RIPterm 1.54 freeware assets
examples/ansilove-src/ Ansilove ANSI renderer
examples/ciadraw/    CIA Draw tool
examples/rez2ans-next/ REZ to ANSI converter
scripts/             MPL example scripts
utilities/           Helper tools
tools/               Build tools
tests/               Automated test suites
docs/                Documentation and whitepapers
docs/rip/            TeleGrafix whitepaper + implementation whitepaper
attic/               Retired platform libraries (not needed for RIPscrip)
```

## New Subsystems

- **uforkpty.pas** — Pure FPC forkpty(), zero libc/libutil dependency
- **utextmouse.pas** — Cross-platform mouse (xterm/Win32/INT 33h)
- **mutil_filetoss.pas** — TIC file tosser per FTS-5006.001/FSC-0087
- **netmodem_fossil.pas** — FOSSIL INT 14h serial test for DOS
- **MPL AppendText** — Procedure #561, appends line to text file

## Documentation

| File | Description |
|------|-------------|
| `docs/BUILDING.md` | How to compile from source |
| `docs/rip/ripscrip-v3-whitepaper.htm` | Original TeleGrafix whitepaper |
| `docs/rip/ripscrip-v3-implementation-whitepaper.htm` | Our implementation whitepaper (12 sections) |
| `docs/FPCIRC-BUG-REPORT-HEAP-CRASH.md` | BUG-038 report (RESOLVED) |
| `mystic_ripapi4/rip4api.htm` | v4.0 API reference |
| `mystic_ripapi4/HTML_V1_NOTES.md` | HTML 1.0 features and limitations |
| `mystic_ripapi4/RIPSCRIPT_V4_ROADMAP.md` | v4.0 roadmap |
| `mystic_ripapi4/features.txt` | Full v1/v2/v3/v4 feature comparison |

## Build Scripts

| Script | Purpose |
|--------|---------|
| `build-linux.sh` | Build 15 Linux i386 binaries |
| `build-win32.sh` | Cross-compile 15 Win32 PE32 .exe |
| `build-dos.sh` | Cross-compile 9 DOS go32v2 binaries |
| `build-os2.sh` | Cross-compile OS/2 EMX |

## Compiler

FPC 2.6.4irc r3.1 — https://github.com/verta1878/fpc264irc

## License

GNU General Public License v3. See `COPYING`.
