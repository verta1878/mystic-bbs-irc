# Bundled ld64 cross-linker (Linux x86-64 host)

This directory contains a **prebuilt, relocatable ld64 / cctools cross
toolchain** so the fork can LINK Mystic for Darwin (Mach-O i386) without you
building the linker yourself.  `build-darwin.sh` auto-discovers it.

## What's here

    bin/i386-apple-darwin10-{ld,as,ar,ranlib,nm,strip,lipo,libtool,otool}
    bin/i386-darwin-*        symlinks (FPC 2.6.x default cross prefix)
    lib/libBlocksRuntime.so  Apple runtimes ld64 links against
    lib/libdispatch.so

`ld` is `ld64-956.6`.  The binaries are patched with an `$ORIGIN/../lib`
rpath, so they find their runtime libs relative to themselves - copy this
whole directory anywhere and it still works.

## IMPORTANT: host requirement

These are **Linux x86-64 (ELF) executables**.  They run on a Linux/amd64
host to PRODUCE macOS binaries.  They do NOT run on Windows, macOS, ARM, or
32-bit hosts.  On any other host, build the toolchain with
`../../build-ld64-toolchain.sh` (repo root) instead (same result, native to your host).

## What you still supply: the macOS SDK

Apple's SDK is **not** included (it's Apple-licensed and ~257MB - it cannot
live in this GPL repo).  Extract a `MacOSX10.6.sdk` from your own Xcode and
point the build at it:

    SDK=/path/to/MacOSX10.6.sdk ./build-darwin.sh

If the SDK lacks `usr/lib/crt1.o`, build it from Apple's open-source Csu
(10.4-compat variant with dyld_glue.s) - see the Darwin section of INSTALL.

## Licensing / provenance

ld64 and cctools are Apple open source (APSL 2.0); libdispatch and
BlocksRuntime likewise.  Built from tpoechtrager/cctools-port and
tpoechtrager/apple-libdispatch (the standard Linux ports).  These are
aggregated here for convenience under their own licenses - not covered by
this project's GPL.  The build recipe is `../../build-ld64-toolchain.sh` (repo root).
