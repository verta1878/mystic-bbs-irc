# Building the fork (all targets)

Compiler: **FPC 2.6.4irc, release r3, i386** (the default project compiler).
Every target builds the same 14 binaries (see `docs/CREATING-THE-INSTALLER.md`
for the binary inventory + how to package a release once built).

> The compiler is bundled at `libs/fpc264irc.tar.gz` (self-sustaining — it ships
> its own assembler/linker/archiver via a 3-tier fallback, so a build never
> dead-ends on a missing tool). Unpack it and point `FPC=` at its `bin/ppc386`.
> It is PPU-compatible with stock FPC 2.6.4 (wordversion unchanged), so on-disk
> record layout / anchors are unaffected. (FPC 2.6.2 was the earlier pin.)

--------------------------------------------------------------------------------

## Native / primary

### Linux -> ELF
```bash
./build.sh                 # all 14 binaries
./build.sh mis             # a single target
```

### Windows -> PE32
```
build-win32.bat            # run on Windows (FPC 2.6.2 i386)
```
Also cross-buildable from Linux with the native compiler via `ppc386 -Twin32`
plus the i386-win32 RTL units.

--------------------------------------------------------------------------------

## Cross-compile targets (all built from a Linux host)

### OS/2 -> LX executables
```bash
LINK=1 ./build-os2.sh
```
- `LINK=1`  compile **and** link to `.exe`. Without it: compile-only (safe on
  any Linux host - no OS/2 toolchain required for the compile pass).
- **Needs:** the emx cross-toolchain on `PATH`, built from
  the fork bundle's emx tools (fpc264irc/bin/tools/i386-emx: patched binutils with the a.out-emx target +
  emxbind Linux port + emxl.exe + the i386-os2-ld alignment wrapper).
- Also builds natively on OS/2 (the FPC 2.6.2 OS/2 release bundles emx).

### macOS -> Mach-O
```bash
SDK=/path/to/MacOSX10.6.sdk ./build-darwin.sh      # all 14
SDK=/path/to/MacOSX10.6.sdk ./build-darwin.sh mis  # one target
```
- `SDK=`  path to a macOS SDK (10.6 suits the FPC 2.6.2 era; needs
  `usr/lib/crt1.o`). Auto-detected from `$MACOS_SDK`, `~/darwin/MacOSX*.sdk`, or
  `/opt/darwin/MacOSX*.sdk` if `SDK=` is unset.
- **Needs:** a cctools/ld64 cross-toolchain for i386-apple-darwin10 on `PATH`
  (tools also symlinked to FPC's `i386-darwin-*` prefix), AND the i386-darwin RTL
  built with that external assembler (not FPC's internal Mach-O writer).

### DOS -> go32v2 (protected-mode DPMI)
```bash
WATT32LIB=/path/to/watt ./build-dos.sh     # 14/14  (with libwatt.a)
./build-dos.sh                             # 10/14  (no networking)
```
- `WATT32LIB=`  directory containing `libwatt.a`. Supply it to build all 14.
- **Without it:** the 4 networked programs (`mis`, `fidopoll`, `nodespy`,
  `qwkpoll`) will not link -> 10/14. The other 10 build fine.
- **Needs:** the go32v2 cross compiler + go32v2 RTL + patched binutils that reads
  FPC's COFF output (the DOS toolchain). See `docs/DOS-SOCKETS.md` for the
  Watt-32 socket layer details.

--------------------------------------------------------------------------------

## Notes

- **Stale headers:** the `build-*.sh` script header comments still say
  "1.10 A38 fork". This is cosmetic - the scripts compile whatever is in the
  tree, so the imported A40 work builds regardless. (Tied to the open
  "what alpha is this fork" version-label decision.)
- **Packaging:** after building a target's binaries, use `make_release.sh`
  to assemble the FULL / UPDATE archives - see `docs/CREATING-THE-INSTALLER.md`.
  Archives are named `mystic-<VER>-<tag>-<mode>-<STAMP>.zip` (VER default
  `1.10a38irc`; STAMP defaults to today, MM-DD-YYYY, or pass `STAMP=FINAL` once an
  alpha's import is complete). Each archive unpacks into a matching top-level
  folder so FULL and UPDATE never merge, and its FILE_ID.DIZ ends with a
  `Released: <STAMP>` line.
