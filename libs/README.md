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

## What's here (built 2026-07-08, matched to the fork's FPC 2.6.2 i386 builds)

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
  which is REQUIRED: FPC 2.6.2 keeps the old 4-byte i386 stack alignment, and a
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
  10.6-compatible release; it's period-appropriate for FPC 2.6.2 anyway.
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
