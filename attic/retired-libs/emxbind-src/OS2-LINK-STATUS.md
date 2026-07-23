# OS/2 self-hosted link on Linux — STATUS: WORKING

A complete FPC 2.6.2 OS/2 program links to a valid OS/2 LX .exe entirely on a
Linux x86-64 host.  No OS/2 machine involved.  This was historically considered
unsolved (bitwiseworks/ArcaOS "emx toolchain on Linux" issue).

    $ ppc386 -Tos2 -XPi386-os2- ... maketheme.pas
    emxbind 0.9d -- Copyright (c) 1991-1997 by Eberhard Mattes
    $ file maketheme.exe
    MS-DOS executable, LX for OS/2 (console) i80386, emx 0.9d   (364,938 bytes)
    MZ magic OK | LX header at 0x600 OK

## Full pipeline — every step working

| Step                                | Status | How |
|-------------------------------------|--------|-----|
| compile  ppc386 -Tos2               | WORKS  | 14/14 |
| assemble i386-os2-as                | WORKS  | binutils 2.30 i386-aout |
| ld: resolve DLL imports             | WORKS  | binutils N_IMP patch + re-ranlib |
| ld: emx a.out layout (text @0x400)  | WORKS  | a.out-emx BFD target (i386os2.c) |
| ld: unpadded a_text in header       | WORKS  | rawsize fix in i386os2.c write |
| ld: data at 64 KB segment boundary  | WORKS  | two-pass i386-os2-ld wrapper |
| emxbind: build + run on Linux       | WORKS  | 32-bit build (-m32) + getopt "+" |
| emxbind: emxl.exe loader            | WORKS  | emxl.exe on PATH |
| emxbind: bind a.out -> LX .exe      | WORKS  | all 4 header/data checks pass |

## The four emxbind checks — all pass
  1. header magic 0x010b .................. OK
  2. entry == TEXT_BASE 0x10000 .......... OK
  3. startup code (prt0 68/e8/eb/e8 @0x400) OK
  4. os2_bind_header: text_base 0x10000,
     text_end 0x38040, data_base 0x40000 .. OK

## Documentation
Full technical explanation + reproduction recipe:
  docs/os2-linux-toolchain/TECHNICAL-REFERENCE.md
  docs/os2-linux-toolchain/BUILD-ON-UBUNTU-24.04.md
Patches + target + apply steps:
  libs/emxbind-src/binutils-patch/

## Note
On a real OS/2/ArcaOS box none of this is needed - the stock FPC OS/2 release
links natively.  This work is about self-hosting the OS/2 link on a Linux CI
host, which is now done.
