# DOS (go32v2) toolchain - FPC 2.6.2

`dos-toolchain.zip` is the DOS cross-build toolchain for the Mystic IRC fork,
built with the **same FPC 2.6.2** that produces every other target
(linux / win32 / darwin / os2).  Because it's version-matched to the fork's
pinned compiler, DOS binaries built with it have record layouts byte-compatible
with the other targets (RecConfig=5282, RecUser=1536, etc.).

`go32v2` is FPC's target for **32-bit protected-mode DOS** via a DPMI extender
(CWSDPMI / GO32) - i.e. the "DOS extender" build that produces the
`dos BINARIES` the release DIZ (file_id.dos) refers to.

## Contents
    units/go32v2/    the go32v2 RTL units (51), built from FPC 2.6.2's own
                     rtl/go32v2 source with `ppc386 -Tgo32v2`.
    bin/             DOS assembler + linker (binutils 2.30), exposed under the
                     `i386-go32v2-*` names FPC calls.  Built as target
                     i386-msdosdjgpp (emulation i386go32 - the triplet ld
                     actually supports; i386-pc-go32v2 is rejected), then
                     symlinked to i386-go32v2-{as,ld,ar,nm,strip,ranlib,...}.
    PROVENANCE.md    build provenance + licenses (inside the zip).

## NOT included
    `ppc386` itself - that's the fork's pinned system compiler (FPC 2.6.2),
    which lives on the build host, not in the repo.  These are the DOS TARGET
    pieces that plug into it.

## Build a DOS binary
    ppc386 -Tgo32v2 -XPi386-go32v2- -Fu<fpc262>/rtl/units/go32v2 prog.pas
    -> "MZ for MS-DOS, COFF, DJGPP go32 DOS extender" executable.

Extract with: `cd libs && unzip dos-toolchain.zip`

## Licenses
    Free Pascal: compiler GPL, RTL/units LGPL + static-linking exception.
    binutils: GPL.  All redistributed unmodified / built from stock source.
