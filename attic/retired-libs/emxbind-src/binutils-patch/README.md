# binutils 2.30 emx patches — OS/2 (LX) linking on Linux

Apply these to a pristine GNU binutils 2.30 tree to get a linker that (a)
resolves emx a.out IMPORT# DLL symbols and (b) emits the emx a.out layout, so
FPC's OS/2 target can link to a valid LX .exe on Linux.  Verified: a clean
2.30 tree + these files builds an ld whose `--help` shows
`supported targets: a.out-i386 a.out-emx ...`.

## Apply (from the binutils-2.30 top directory)

    P=<repo>/libs/emxbind-src/binutils-patch
    patch -p1 < $P/aoutx.h.patch        # N_IMP import symbols
    patch -p1 < $P/archive.c.patch      # armap indexes import stubs
    patch -p1 < $P/bfd-in2.h.patch      # BSF_EMX_IMPORT flags
    patch -p1 < $P/targets.c.patch      # register i386_os2_vec
    patch -p1 < $P/config.bfd.patch     # i386_os2_vec in i386-aout selvecs
    patch -p1 < $P/configure.patch      # i386_os2_vec -> i386os2.lo mapping
    patch -p1 < $P/Makefile.in.patch    # add i386os2.lo / i386os2.c
    cp        $P/i386os2.c  bfd/i386os2.c   # the a.out-emx BFD target

    ./configure --target=i386-aout --enable-obsolete --disable-werror \
                --disable-nls --disable-gdb --disable-readline --disable-sim \
                MAKEINFO=true
    make all-ld all-binutils MAKEINFO=true

Install `ld/ld-new` as `i386-aout-ld`, and `binutils/{ar,nm-new,ranlib}` as
`i386-aout-{ar,nm,ranlib}`.  Then re-index the FPC OS/2 import archives:

    for a in <fpc262>/rtl/units/os2/*.a; do i386-aout-ranlib "$a"; done

## What each file does
    aoutx.h.patch     N_IMP1/N_IMP2 treated as defined abs symbols (reader,
                      aout_link_add_symbols, aout_link_check_ar_symbols) + the
                      unpadded-a_text logic lives in i386os2.c's write path.
    archive.c.patch   BSF_EMX_IMPORT1 symbols enter the armap.
    bfd-in2.h.patch   BSF_EMX_IMPORT1 (1<<28) / BSF_EMX_IMPORT2 (1<<29).
    targets.c.patch   extern + list entry for i386_os2_vec.
    config.bfd.patch  i386_os2_vec added to targ_selvecs for i386-*-aout*.
    configure.patch   vec->object: i386_os2_vec) tb="$tb i386os2.lo aout32.lo".
    Makefile.in.patch i386os2.lo / i386os2.c in the source lists.
    i386os2.c         the "a.out-emx" BFD target: text file offset 0x400
                      (ZMAGIC_DISK_BLOCK_SIZE + text-incl-header=0), text
                      vaddr/entry 0x10000, 64 KB data segment, and unpadded
                      a_text (rawsize) so emxbind's text_end check matches FPC.

Full explanation: docs/os2-linux-toolchain/TECHNICAL-REFERENCE.md
Reproduction recipe: docs/os2-linux-toolchain/BUILD-ON-UBUNTU-24.04.md

## License
Derived from emx (GPL, (c) Eberhard Mattes) and GNU binutils (GPL); offered
under the GPL.
