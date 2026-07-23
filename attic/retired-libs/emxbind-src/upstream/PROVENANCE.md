# Upstream emx 0.9d source (pristine)

These are the unmodified upstream emx 0.9d source archives from SourceForge
(https://sourceforge.net/projects/emx/, 0.9d-fix04), kept for provenance and
GPL "corresponding source" compliance for the emxbind binary we distribute.

    emxsrcr.zip    emx runtime sources - contains src/emxbind/ (emxbind.c + the
                   8 helper .c files we build).
    emxsrcd1.zip   emx development sources part 1 - contains src/lib/moddef/
    emxsrcd2.zip   emx development sources part 2   (the .def parser)
    gbinusrc.zip   emx-patched GNU binutils 2.6 source - contains bfd/emx-aout.c
                   and the bfd/aoutx.h N_IMP patch needed to teach `ld` the
                   IMPORT# format (the remaining OS/2 self-hosting step; see
                   ../BUILD.md).

emx is GPL (c) 1990-1998 Eberhard Mattes. Original download:
https://downloads.sourceforge.net/project/emx/emx/0.9d-fix04/<name>.zip

## emx runtime (emxl.exe loader stub)
    emxl.exe originates from emxrt.zip (emx 0.9d runtime), path emx/bin/emxl.exe
    (1447 bytes).  It is prepended by emxbind's bind step to the LX image.
    Source: https://downloads.sourceforge.net/project/emx/emx/0.9d-fix04/emxrt.zip
