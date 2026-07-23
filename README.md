# Mystic BBS 1.10IRC — Community Fork

> **Release: 2026-07-23** — Mystic 1.10IRC final (alpha testing).
> A41–A63 ported. Next version: 1.11IRC.
> Built with **FPC 2.6.4irc r3.1+**.

Based on **Mystic BBS 1.10 Alpha 38** GPL source, released under the
**GNU General Public License v3**. Maintained by Antonio Rico (Reapern66),
Ecstasy BBS, FTN node 1:152/158.

## RIPscrip Rendering Engines

| Engine | Lines | Tests | Features |
|--------|-------|-------|----------|
| v1 (ripscr.pas) | 4,041 | 97/97 | RIPscrip 1.54 — 51 commands, EGA 16-color |
| v2 (rip2api.pas) | 5,304 | 115/115 | 256-color, 1280x1024, JPEG/PNG |
| v3 (rip3api.pas) | 8,294 | 592/592 | 16M TrueColor, MIDI FM synth |
| v4 (rip4api.pas) | 8,572 | 629/629 | HTML 1.0, MPEG-1, Print, Unicode/TTF |

1,433 tests passing.

## File Transfer Protocols

| Protocol | Status |
|----------|--------|
| Xmodem | Full (CRC-16, 1K) |
| Ymodem / Ymodem-G | Full (batch, streaming) |
| Zmodem / 8K / 32K | Full (CRC-32, crash recovery) |
| Kermit | Full (7-bit safe, CRC-16) |
| HS/Link | Reference in examples/ (GPLv3) |

## MIS Servers

| Server | Port | Status |
|--------|------|--------|
| Telnet | 23 | Working |
| FTP | 21 | Fixed (SIZE/REST/PASV) |
| HTTP | 8080 | New — webroot/ + file downloads |
| SMTP | 25 | Working |
| POP3 | 110 | Working |
| NNTP | 119 | Working |
| BINKP | 24554 | Working |

## Directory Structure

```
mystic/                  BBS core source
  tests/                 Automated test suites
  scripts/               MPL example scripts
  utilities/             Helper tools
  webroot/               HTTP server document root
  GPLV3                  License
mdl/                     Mystic Development Library
mystic_ripapi/           RIPscrip v1.54 engine
mystic_ripapi2/          RIPscrip v2.0 engine
mystic_ripapi3/          RIPscrip v3.0 engine
mystic_ripapi4/          RIPscrip v4.0 engine
mystic_sdl/              SDL2 screen rendering
mystic_rip/              RIP viewer/parser
mystic_crypt/            CryptLib SSH/TLS binding
mystic_spell/            Hunspell spell check binding
mystic_modem/            Modem/FOSSIL driver
mystic_mailer/           BINKP/FidoNet mailer
mystic_misdos/           DOS MIS
mystic_test/             Integration workspace
examples/                Reference code (RIP, HS/Link, MARC, etc)
docs/                    Documentation
attic/                   Retired code
```

## Version History

| Version | Status |
|---------|--------|
| 1.10IRC A41-A63 | Feature-complete, alpha testing |
| 1.11IRC A1+ | Roadmap — MDL refactor, HS/Link port |

## Compiler

FPC 2.6.4irc r3.1 — https://github.com/verta1878/fpc264irc

## License

GNU General Public License v3. See `LICENSE`.
