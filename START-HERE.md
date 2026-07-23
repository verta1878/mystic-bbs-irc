# Start Here

Welcome to **Mystic BBS 1.10IRC** — the community fork.

## Quick Start

1. **Get the compiler:** https://github.com/verta1878/fpc264irc
2. **Build:** `./build-linux.sh` or `build-win32.bat`
3. **Read:** `docs/BUILDING.md` for full build instructions

## What's in the repo?

| Directory | What it is |
|-----------|-----------|
| `mystic/` | BBS core — the main source code |
| `mdl/` | Mystic Development Library (shared units) |
| `mystic_ripapi/` | RIPscrip v1.54 engine |
| `mystic_ripapi2/` | RIPscrip v2.0 engine |
| `mystic_ripapi3/` | RIPscrip v3.0 engine |
| `mystic_ripapi4/` | RIPscrip v4.0 engine (HTML, MPEG, Print, Unicode) |
| `mystic_sdl/` | SDL2 graphical terminal |
| `examples/` | Reference code (HS/Link, MARC, RIPterm, ansilove) |
| `docs/` | Documentation |
| `attic/` | Retired code (don't need it, kept for history) |

## Key Files

| File | Read this for... |
|------|-----------------|
| `README.md` | Project overview |
| `docs/RELEASENOTES.md` | What's new in 1.10IRC |
| `docs/BUILDING.md` | How to compile |
| `docs/PROTOCOLS.md` | File transfer protocol reference |
| `mystic/upgrade.txt` | Upgrade instructions |
| `mystic/whatsnew.txt` | Full change history |

## Building

You need **FPC 2.6.4irc r3.1+** (not stock FPC). Get it from:
https://github.com/verta1878/fpc264irc

```bash
# Linux
./build-linux.sh

# Windows (cross-compile from Linux)
./build-win32.sh

# DOS
./build-dos.sh
```

## The BBS programs

| Binary | What it does |
|--------|-------------|
| `mystic` | The BBS itself (runs per-node) |
| `mis` | Mystic Internet Server (Telnet, FTP, HTTP, SMTP, POP3, NNTP, BINKP) |
| `mutil` | Maintenance utility (echomail, file base, user purge) |
| `fidopoll` | FidoNet mailer polling |
| `nodespy` | Node monitor |
| `marc` | Internal ZIP archiver + media tag viewer |

## Contributing

- Fork the repo, make changes, submit a pull request
- All code is GPLv3
- Use `{$H-}` (ShortString mode) — the entire codebase uses it
- Compile with FPC 2.6.4irc, not stock FPC
- Test on both Linux and Windows before submitting

## Community

- FTN: 1:152/158 (Ecstasy BBS)
- Maintained by Antonio Rico (Reapern66)

## Version

- **1.10IRC** — feature-complete, alpha testing
- **1.11IRC** — next version (roadmap in docs/RELEASENOTES.md)
