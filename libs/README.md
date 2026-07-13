# libs/ — optional runtime libraries for the add-on modules

These are the external shared libraries the optional add-on modules load at
run time.  They are **separately-licensed works, aggregated alongside** this
GPL-licensed source (not combined into it); each keeps its own license, placed
here for sysop convenience so the libraries don't have to be hunted down.

## Layout

Binaries are split by platform:

    libs/win32/        Windows i386 (.dll)      — matches the win32 Mystic build
    libs/linux-i386/   Linux i386 (.so)         — matches the i386-linux build

Drop the file(s) for your platform next to the Mystic executables (or into a
system library path) and the matching module finds them by name.  If a library
is absent, its module simply stays disabled — nothing else is affected.

## What's here (built 2026-07-08, matched to the fork's FPC 2.6.x i386 builds)

| Library  | Module        | win32              | linux-i386             | Version  | License   |
|----------|---------------|--------------------|------------------------|----------|-----------|
| SDL2     | mystic_sdl / mystic_rip | SDL2.dll  | libSDL2-2.0.so.0       | 2.32.8   | zlib      |
| Hunspell | mystic_spell  | libhunspell32.dll  | libhunspell-1.7.so.0   | 1.7.2    | GPL/LGPL/MPL |
| cryptlib | mystic_crypt  | cl32.dll           | libcl.so / (mac) libcl.dylib | 3.4.9.1 | Sleepycat |

Matching license files in this folder: SDL2-LICENSE.txt, HUNSPELL-LICENSE.txt,
CRYPTLIB-LICENSE.txt (+ CRYPTLIB-COPYING-3.4.9.1.txt shipped with the source).

### Build notes / provenance (so these can be reproduced or trusted)

- **SDL2 2.32.8** — win32 DLL is the official libsdl-org release binary.  The
  linux-i386 .so was built from the 2.32.8 source **with `-mstackrealign`**,
  which is REQUIRED: FPC 2.6.x keeps the old 4-byte i386 stack alignment, and a
  stock modern-distro SDL assumes 16-byte alignment — mixing them crashes in
  SDL_Init.  This local build realigns on entry, so `sdl_demo`, `rip_view` and
  the RIP viewer run cleanly against it (verified headless in-container).
- **Hunspell 1.7.2** — linux-i386 built from source (`-m32`).  win32 built with
  mingw (i686-w64-mingw32) and linked `-static-libgcc -static-libstdc++`, so the
  DLL needs only KERNEL32 + msvcrt (no libstdc++-6.dll / libgcc dependency).
- **cryptlib 3.4.9.1** — built from the official Peter Gutmann source (the
  maintainer holds a commercial license; the free tier applies here).  The
  sysop's target is 3.4.9.2; 3.4.9.1 is the nearest public source and the ABI
  the mystic_crypt binding expects is unchanged.  **linux-i386 .so provided;
  win32 cl32.dll is NOT included** — cryptlib's Windows build wants MSVC and its
  own randomness/entropy plumbing, out of scope for this cross-build pass; drop
  a real cl32.dll here when available.  See the crypt note in DECISIONS.md
  (2026-07-08) about the in-container `cryptInit` entropy result.

### Darwin (macOS, i386) libraries — libs/darwin-i386/

- **cryptlib** `libcl.dylib` — cross-built for i386-darwin (Mach-O) against the
  10.6 SDK with the bundled ld64 toolchain; pure C, builds cleanly.  62 crypt*
  exports; the mystic_crypt binding's darwin probe name is `libcl.dylib`.
- **SDL2** `libSDL2-2.0.0.dylib` — SDL2 **2.0.1** (the last line before SDL
  hard-required a 10.7 SDK), cross-built for i386-darwin against the 10.6 SDK.
  The current SDL2 (2.32.x) refuses to build on 10.6 (its Cocoa backend needs
  10.7 AppKit symbols like `NSFullScreenWindowMask`), so we use the newest
  10.6-compatible release; it's period-appropriate for the FPC 2.6.x era anyway.
- **Hunspell** `libhunspell-1.6.0.dylib` — Hunspell **1.6.2** (1.7 uses C++11
  `std::all_of`, absent from the 10.6 SDK's gcc-4.2 libstdc++), cross-built for
  i386-darwin.  The spell binding probes this versioned name then plain
  `libhunspell.dylib`.
  So all three darwin runtime libs (SDL2, Hunspell, cryptlib) are present and
  built with the CURRENT 10.6 SDK — no newer SDK needed.  (Using slightly older
  SDL2/Hunspell releases is the price of 10.6 support; the APIs the modules
  call are unchanged.)

### cl32.dll (Windows cryptlib) — libs/win32/

Cross-built with mingw (i686-w64-mingw32) using the one-line endian patch in
docs/patches/cryptlib-mingw-endian.patch (cryptlib's endian detection checked
__GNUC__ before Windows).  Linked `-static-libgcc` so it needs only standard
Windows system DLLs (KERNEL32/ADVAPI32/WS2_32/NETAPI32/USER32/msvcrt).  DES
uses cryptlib's shipped win32 asm object; 62 crypt* exports.  Stripped, ~1.9MB.

These libraries are NOT covered by this project's GPL; each is used under its
own license above.  Their inclusion here is "mere aggregation" in the GPL sense.
Match the library BITNESS to the Mystic build (all provided binaries are i386).

--------------------------------------------------------------------------------
## Build toolchains (target cross-compilers, bundled)

Two self-contained cross-build toolchains ship as zips here:

### fpc264irc.tar.gz (~170 MB) — the 2.6.4irc compiler fork (release r3)
A complete built distribution of **FPC 2.6.4irc release r3** (2026-07-12), a fork
of FPC 2.6.4 that adds a DOS (go32v2) `Sockets` unit over Watt-32, backports FPC
3.0/3.3 cross-link fixes (so stock `binutils-djgpp` links go32v2 with no
C_SECTION patch), adds the `-Ao` (assembler extra options) and `-WS` (embed
CWSDSTUB into go32v2 exes) flags, and fixes OS/2 import-symbol generation.
Mirrors github.com/verta1878/fpc264irc.  Contents: `bin/ppc386` + `bin/ppcx64`
(prebuilt) with `bin/units/` (compiled RTL per target incl.
`i386-go32v2/sockets.ppu`); `bin/lazarus/`, `bin/tools/`, `bin/ide/` (kept for
future Mystic upgrades); `src/` (full compiler + rtl incl. `rtl/go32v2/
sockets.pp`); `test/` (per-platform socket tests incl. FreeBSD); `lib/`
(Watt-32, CWSDPMI, build-tools); `patches/os2-cross/`; build scripts;
`CHANGELOG-IRC.md`; `BACKPORT-METHOD.md`; `MILESTONE-R2.md`.  (`.ppu`/`.o` build
artifacts are stripped from `src/`; they rebuild.)

Version identity: `minorpatch='irc'`, `release_tag='r3'`,
`release_date='2026-07-12'` — stable metadata that does not change on rebuild.
Key property: base FPC 2.6.4, **PPU wordversion unchanged** — binary-compatible
with stock 2.6.4 units, so on-disk record layout stays 2.6.x (record anchors
safe by construction).  The payoff: `Uses Sockets` works on DOS exactly like
every other platform, with **no** app-level `{$IFDEF GO32V2}`.  NOTE: FPC 2.6.4irc
r3 is now the default project compiler (see docs/TODO.md #9); 2.6.2 is retained
as a working fallback.  Both are the 2.6.x i386 ABI (4-byte stack alignment; the
16-byte default arrived in FPC 3.0), so the prebuilt libs here match either.

### dos-toolchain.zip (~25 MB)
FPC 2.6.2 compiler (bin/ppcross386, bin/ppc386) + binutils (i386-go32v2-*) +
the go32v2 RTL units.  Self-contained: unzip, add bin/ to PATH, build a DOS
(MZ/COFF/DJGPP go32) executable with no separately-installed FPC.  See
DOS-TOOLCHAIN-README.md.

### OS/2 (LX) toolchain — now provided by the FPC 2.6.4irc fork bundle
Everything to build OS/2 (LX) executables ON LINUX — the emxbind Linux port, the
binutils 2.30 emx patches + the a.out-emx BFD target, the data-alignment ld
wrapper, and the emxl.exe loader — now ships inside `libs/fpc264irc.tar.gz`:
prebuilt tools in `fpc264irc/bin/tools/i386-emx/` (as/ld/ar/emxbind) and the
patches + recipe in `fpc264irc/patches/os2-cross/` (README.md, EMXL-LOADER.md).
The fork also carries `build-mystic-os2.sh`, a companion that wires the exact
compiler + RTL + package paths (incl. fcl-process, which `mis` needs on OS/2).
The old standalone `os2-linux-toolchain.zip` + `emxbind-src/` were removed from
libs/ once the fork absorbed them.  emx content is GPL (c) Eberhard Mattes.
