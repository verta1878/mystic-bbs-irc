# Mystic BBS 1.10 A38irc-A63 — Community Fork (IRC)

> **Release: 2026-07-18** — Mystic 1.10 A38 fork with A41–A60 fully ported.
> BINKP FTS-1026 compliant. TIC file tosser (FTS-5006.001).
> Built with **FPC 2.6.4irc r3.1+**.

A community fork of **Mystic BBS 1.10 Alpha 38** source, released under the
**GNU General Public License v3**. Maintained by Antonio Rico (Reapern66),
Ecstasy BBS, FTN node 1:152/158.

## Build Status

| Platform | Build | Link | Notes |
|----------|-------|------|-------|
| Linux i386 | 15/15 ✅ | 15/15 ✅ | — |
| Windows | 15/15 ✅ | 15/15 ✅ | Wine-tested, needs Win11 verification |
| DOS go32v2 | 9/9 ✅ | 9/9 ✅ | — |
| OS/2 EMX | ✅ compiles | ⚠️ | emxbind needs emxl.exe |
| FreeBSD | 3/15 | 3/15 | Console unit differences |
| Darwin | — | — | Missing base RTL PPUs |

Tests: **188 pass** (134 a53 + 54 deferred9)

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
| A61–A63 | — | Version-bumped, items deferred |

## New Subsystems

- **uforkpty.pas** — Pure FPC forkpty(), zero libc/libutil dependency
- **utextmouse.pas** — Cross-platform mouse (xterm/Win32/INT 33h), ANSI editor only
- **mutil_filetoss.pas** — TIC file tosser per FTS-5006.001/FSC-0087
- **netmodem_fossil.pas** — FOSSIL INT 14h serial test for DOS
- **MPL AppendText** — Procedure #561, appends line to text file
- **MPL CfgChatStart/CfgChatEnd** — Read-only config variables

## Directory Structure

```
mystic/          Core BBS source (Pascal)
mdl/             Mystic Development Library
scripts/         MPL example scripts
utilities/       Helper tools (mbbshtml, mys_php, ansi2pipe, etc)
thirdparty/      Third-party source (ansilove, rez2ans-next, ciadraw)
tests/           Automated test suites
docs/            Documentation
libs/            Platform libraries and toolchain patches
attic/           Retired/archived files
```

## Build Scripts

| Script | Purpose |
|--------|---------|
| `build-linux.sh` | Build 15 Linux i386 binaries |
| `build-win32.sh` | Cross-compile 15 Win32 PE32 .exe |
| `build-dos.sh` | Cross-compile 9 DOS go32v2 binaries |
| `build-os2.sh` | Cross-compile OS/2 EMX (compile only) |
| `make_clean.sh` | Remove all build artifacts |
| `make_release.sh` | Build FULL + UPD packages for all platforms |
| `make_install_data.sh` | Build install_data.mys from Mystic directory |

## Release Packages

- **FULL** (5 files): `install` + `install_data.mys` + `COPYING` + `FILE_ID.DIZ` + `whatsnew.txt`
- **UPD** (20 files): All 15 binaries + `install_data.mys` + `COPYING` + `FILE_ID.DIZ` + `whatsnew.txt` + `upgrade.txt`

## Documentation

| File | Description |
|------|-------------|
| `docs/BUILDING.md` | How to compile from source |
| `docs/INSTALL-MAKE.md` | How to build install_data.mys |
| `docs/CREATING-THE-INSTALLER.md` | Full release workflow |
| `docs/BUGS.md` | Known fpc264irc compiler bugs |
| `docs/DOS-SOCKETS.md` | DOS TCP/IP socket layer |
| `docs/RIP-INTEGRATION.md` | RIPscrip integration notes |
| `mystic/whatsnew.txt` | Release notes (A41–A60 with alpha tags) |
| `mystic/upgrade.txt` | Upgrade instructions |

## License

GNU General Public License v3. See `COPYING`.
