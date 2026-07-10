# DOS (go32v2) binutils patch - C_SECTION storage class

Teaches GNU binutils 2.30's `coff-go32` target to read Free Pascal (FPC 2.6.2)
object files, so `ld` can link FPC DOS programs against C libraries such as
Watt-32. Without this, linking any FPC go32v2 program that references an
external C symbol fails with:

    i386-go32v2-ld: sockets_go32v2.o: Unrecognized storage class 104 for
    .text symbol `.text' - could not read symbols: Invalid operation

## Root cause

FPC 2.6.2 emits storage class **0x68 (104) = C_SECTION** for its section
symbols (`.text`/`.data`/`.bss`) - the PE/NT convention. In plain COFF, 0x68 is
`C_LINE`, and binutils' `coff-go32` target is built WITHOUT `COFF_WITH_PE`, so
`coffcode.h` treats 0x68 as `C_LINE` and rejects it as unrecognized instead of
handling it as a section symbol.

The non-networked FPC DOS programs link fine because FPC uses its INTERNAL
linker for them; a `cdecl external` C symbol (e.g. a Watt-32 call) forces FPC
to invoke the EXTERNAL GNU `ld`, which is where the rejection bites.

## The fix (2 files, ~minimal)

- **coff-go32.c.patch**: define `COFF_GO32_C_SECTION` before including
  coff-i386.c (-> coffcode.h).
- **coffcode.h.patch**: under `COFF_GO32_C_SECTION`, (a) accept `case
  C_SECTION:` (0x68) as a section symbol - the same path PE uses - and (b)
  exclude the conflicting `case C_LINE:` (also 0x68) to avoid a duplicate-case
  collision.

This mirrors the OS/2 emx binutils patch (import-symbol handling) - both teach
binutils to read an FPC symbol convention its stock coff/a.out reader rejects.

## Build recipe (Ubuntu 24.04)

    apt-get install -y bison flex
    tar xf binutils-2.30.tar.gz            # pristine
    cd binutils-2.30
    patch -p0 < .../coff-go32.c.patch      # applies to bfd/coff-go32.c
    patch -p0 < .../coffcode.h.patch       # applies to bfd/coffcode.h
    mkdir build && cd build
    ../configure --target=i586-pc-msdosdjgpp --prefix=<pfx> \
      --disable-nls --disable-werror --enable-targets=i586-pc-msdosdjgpp
    make all-ld all-binutils MAKEINFO=true -j4
    # install under the FPC -XP prefix names:
    cp ld/ld-new        <pfx>/bin/i386-go32v2-ld
    cp binutils/nm-new  <pfx>/bin/i386-go32v2-nm
    cp binutils/objdump <pfx>/bin/i386-go32v2-objdump
    cp binutils/ar ranlib strip-new ...    # as needed

Then put `i386-go32v2-ld` (patched) where FPC's `-XPi386-go32v2-` finds it
(overwrite the one bundled in dos-toolchain.zip).

## Verified

- Patched `objdump -t`/`nm` read FPC objects (scl 104 `.text/.data/.bss`
  accepted; real symbols like `T_FOO` show correctly).
- A non-networked FPC DOS program still links (no regression).
- A networked program (fidopoll) now links PAST the class-104 rejection - the
  only remaining errors are `undefined reference to 'sock_init'/'socket'/
  'connect'/...`, i.e. the Watt-32 functions that `libwatt.a` provides. That
  confirms the object-reading fix is complete; the remaining step is building
  Watt-32 (libwatt.a) and adding `-lwatt` to the link.
