# Mystic BBS 1.10 A38irc-A40 - Community Fork (IRC)

> **Release: 2026-07-15** — base **Mystic 1.10 A38irc-A40**, with all
> **A41, A42, and A43** features ported from g00r00's whatsnew. Includes
> FidoNet enhancements (AreaFix/FileFix, PKT passwords, FMPT/TOPT,
> CRAM-MD5 ARGUS fix, echomail.in semaphore), MIS event fixes,
> file-echo support, twit filter, built-in ZIP archiver (marc),
> extended fidopoll commands (LIST/ROUTE/SEARCH/KILLBUSY/UPLINK),
> and the email validation/feedback bug fixes. Builds with
> **Free Pascal 2.6.2** for Windows (XP+, 32-bit), Linux (i386), macOS/Darwin
> (compiles + links with an Apple SDK you supply), and **OS/2** - now built
> **entirely on Linux** to native LX executables via a self-hosted emx
> toolchain (bundled in libs/fpc264irc.tar.gz: bin/tools/i386-emx + patches/os2-cross). DOS/go32v2 builds 10/14 including
> the BBS server; its socket layer and binutils link fix ship in the repo, and
> the networked utilities need only Watt-32 (libwatt.a) - see docs/DOS-SOCKETS.md.

A community fork of the **Mystic BBS 1.10 alpha 38** source, released under the
**GNU General Public License v3**. The goal is a clean, buildable, well-documented
tree that the BBS scene can build, run, study, and carry forward on the platforms
that matter to it - **Windows XP (32-bit)**, **Debian/Linux (i386)**, and
**macOS/Darwin** - using the original **Free Pascal 2.6.2** toolchain.

Mystic BBS is Copyright 1997-2013 by James Coyle (g00r00). This fork preserves
that attribution and all GPL notices; see [COPYING](COPYING).

> **Full release documentation: [RELEASE-NOTES.md](RELEASE-NOTES.md)** — the
> complete reference (platforms, the OS/2-on-Linux toolchain, modules, libs,
> installer/release process, source, and licensing).

*Maintained by Antonio Rico — Ecstasy BBS (aric2746@aim.com). It's been a long
time since 1999; just trying to give back.*

## Why this fork exists

Free software, kept free. This tree exists so that anyone - not just its
maintainer - can compile Mystic from source on real hardware, understand how it
works, fix it, and keep the scene's software alive. Preservation isn't just the
code; it's making the code *buildable by a stranger years from now*. That is why
the build documentation is treated as a first-class part of the project.

## Status

- **Builds cleanly on Windows (XP+) and Linux (i386)** with FPC 2.6.2 - every
  program target compiles on both.
- **macOS/Darwin**: the source compiles to Mach-O objects; a full runnable Mac
  binary is produced by cross-linking with an Apple SDK you supply (see below).
- Work is ongoing to bring the tree forward from A38 while keeping strict
  on-disk data compatibility (a running board's config/message files stay valid).

This is alpha-era software being carefully modernized; expect rough edges and
read [mystic/whatsnew.txt](mystic/whatsnew.txt) for exactly what has changed.

## Building

Each target has its own script and its own prerequisites. **Read
[INSTALL](INSTALL) first** - it covers what to install for each platform,
the vintage-processor / SDK details for the Mac build, and a step-by-step
Linux -> Darwin cross-compile recipe.

| Target         | Script            | Runs on                              |
|----------------|-------------------|--------------------------------------|
| Windows (XP+)  | `build-win32.bat` | Windows / cmd.exe                    |
| Linux (Debian) | `build.sh`        | Linux / bash                         |
| macOS (Darwin) | `build-darwin.sh` | macOS, or Linux with a cross toolchain |
| OS/2           | `build-os2.sh`    | Linux (full: compile + LX link)      |
| DOS (go32v2)   | `build-dos.sh`    | Linux cross toolchain → runs on 386+ DOS via DPMI |

> **DOS = 32-bit protected-mode (go32v2/DJGPP).** The DOS binaries are 32-bit
> and require a 386 or better plus a DPMI host (CWSDPMI). This is **not** a
> 16-bit real-mode (i8086/8088/286) build — FPC 2.6.x (including 2.6.4irc r3.1)
> has no i8086 target, so true 16-bit DOS is out of scope for this compiler.

```
# Linux (native)
./build.sh                       # build everything
./build.sh mis                   # build a single target

# Other targets (all cross-compiled from a Linux host):
LINK=1 ./build-os2.sh            # OS/2  -> LX executables (needs libs/ emx toolchain)
SDK=/path/to/MacOSX10.6.sdk ./build-darwin.sh   # macOS -> Mach-O
./build-dos.sh                   # DOS   -> go32v2 (10/14; networked need libwatt.a)
```

The OS/2 and DOS cross toolchains ship inside `libs/fpc264irc.tar.gz` (bin/tools/i386-emx,
`dos-toolchain.zip`) with the binutils patches that let GNU `ld` read FPC's
object output. FPC 2.6.4irc r3.1 bundles both toolchains (fpc264irc/bin/tools/: i386-emx for OS/2, i386-go32v2 for DOS).

## What's in the tree

- `mystic/` - the BBS and its utilities (main programs)
- `mdl/` - the MDL support layer (I/O, sockets, strings, protocols, ...)
- `scripts/` - MPL scripts
- `utilities/` - extra tools
- `mystic_modem/` - **optional dialup add-on**: real serial-modem support with
  a Waiting-For-Caller screen, a FOSSIL layer, and an interactive setup tool.
  Separate from the core; changes nothing on disk. See its README.
- `mystic_mailer/` - **optional sample FidoNet mailer front-end** (FrontDoor
  style) built on `mystic_modem/`: answers the phone, tells apart an EMSI
  mailer, a BinkP mailer, or a human, and routes each. Includes the
  BinkP-over-modem spec. See its README.
- `mystic_spell/` - **optional spell-check add-on**: on-the-fly spell checking
  and word suggestions via the Hunspell engine (the same approach Mystic 1.12
  uses), as a self-contained module. Runtime-loads Hunspell; ships a BBS-terms
  word list. See its README.
- `mystic_sdl/` - **optional SDL2 DOS-session front-end**: renders a full-screen
  80x25 CP437 DOS window (the toolkit g00r00 uses for NetRunner) so the dialup /
  BinkP screens can display graphically. Runtime-loads SDL2. See its README.
- `mystic_rip/` - **optional RIPscrip graphics example**: a working RIP terminal
  engine (TTermRip, shaped like the ANSI class) + software EGA surface + SDL2
  viewer with clickable RIP buttons - the groundwork for RIP support. FPC RTL
  only; SDL2 runtime-loaded via mystic_sdl's binding. See docs/RIP-INTEGRATION.md
  and its README.
- `mystic_crypt/` - **optional cryptlib (SSH/TLS) example**: groundwork for
  secure sessions using cryptlib (the cl32.dll stock Mystic 1.12 uses), as a
  self-contained example. Runtime-loads cryptlib; degrades to plaintext if
  absent. Our core is telnet/plaintext only - this is a feature-forward. See README.
- `libs/` - drop-in runtime libraries for the optional modules (Hunspell,
  SDL2, cryptlib), each under its own license; see libs/README.md.
- `attic/` - retired code, kept (not deleted) for GPL attribution and scene
  history (superseded classes, reference implementations)

## Dialup / modem support (optional)

Mystic went telnet/TCP-only before its source release; this fork adds dialup
back as two **self-contained, optional modules** that don't touch the core:

- **`mystic_modem/`** - serial/modem/FOSSIL layer, a MIS-style Waiting-For-Caller
  status screen, and `modemcfg` (an interactive tool so a sysop can configure the
  modem without hand-editing `modem.ini`). Built on Free Pascal's cross-platform
  serial unit: Windows COM ports and Linux `/dev/tty*` (incl. USB adapters).
- **`mystic_mailer/`** - a sample mailer front-end with a real EMSI handshake and
  a three-way (EMSI / BinkP / human) caller detector, plus a documented spec for
  running BinkP over a modem.

These compile and run today; wiring a live session onto the serial line (a small
`TIOSerial` class) is the remaining integration step, documented in each module.
Live use needs real modem hardware (V.42-capable for BinkP).

## Documentation

- **[INSTALL](INSTALL)** - how to build on each platform, prerequisites,
  and the macOS cross-compile recipe.
- **[mystic/whatsnew.txt](mystic/whatsnew.txt)** - the changelog: every change in this fork.
- **[docs/mystic.html](docs/mystic.html)** - the full Mystic manual (HTML): the original
  sysop documentation header plus a consolidated export of the entire Mystic wiki
  (80 pages: configuration, MUTIL, menus/display codes, scripting, changelogs).
  Describes stock 1.12 Mystic; cross-check docs/DECISIONS.md for fork differences.
- **[docs/DECISIONS.md](docs/DECISIONS.md)** - every import/porting decision and the
  reasoning, with ground-truth cross-checks against the A49/A51 binaries.
- **[COPYING](COPYING)** - GNU GPL v3.

## Contributing

Contributions are welcome, especially platform testing (a **Mac contributor** who
can build/run the Darwin target is particularly valuable). The tree targets FPC
2.6.2 and 32-bit builds by design; please keep changes on-disk-compatible with a
running board unless a change is explicitly a data-format migration.

## Credits

Mystic BBS by James Coyle (g00r00). This fork stands on that work and on the
broader free-software BBS scene. Kept free, in that tradition.

Fork maintained by **Antonio Rico — Ecstasy BBS** — aric2746@aim.com. It's been
a long time since 1999; just trying to give back.
