# emxbind for Linux (OS/2 final-link tool) - WORKING

`emxbind` is the tool FPC's OS/2 target calls for the FINAL link step: it
converts the intermediate a.out (from `ld`) into an OS/2 LX `.exe` and builds
the LX import table.  Historically it runs on OS/2; **this is a working port
that runs on a Linux x86-64 host** (see emxbind.linux-x86_64).

## What this is
- `*.c`, `emxbind.h`, `defs.h` - emxbind's own GPL source (emx 0.9d, from
  emxsrcr.zip) + the moddef .def-parser (moddef1/2/3.c, from emxsrcd) it needs.
- `shim/` - small headers written for this port so the emx sources build on
  Linux:
  - `sys/moddef.h`   - reconstructed from the moddef implementation + emxbind's
                       use (the original ships only in the emx binary dev kit).
  - `sys/user.h`     - minimal emx core-dump header (core path unused by normal
                       binding; struct only needed to compile exec.c).
  - `io.h`, `share.h` - map emx low-level I/O + sopen() sharing to POSIX.
  - `emxcompat.h/.c` - emx libc helpers (_strncpy, stricmp, _errno, _fsopen,
                       _defext/_remext, _path, _fncmp, optswchar).

## Build
```
gcc -I. -Ishim -include shim/emxcompat.h -w -c *.c
gcc *.o -o emxbind          # Linux x86-64 executable
```
Install as `emxbind` (and symlink `i386-os2-emxbind`) on PATH for the OS/2 build.

## STATUS: emxbind works; the OS/2 LINK is NOT yet fully self-hosted on Linux
Running the FPC OS/2 link pipeline on Linux now gets:
  as (i386-os2-as)  OK  ->  ld (i386-os2-ld)  FAILS  ->  emxbind  (works, ready)

The `ld` step fails to resolve the FPC OS/2 RTL's DLL imports, which ship in
emx's a.out `IMPORT#` format (doscalls.a: `_$dll$doscalls$_index_NNN =
DOSCALLS.NNN`, symbol types N_IMP1/N_IMP2).  Stock GNU binutils classifies
these as debug symbols, not linkable definitions, so ld reports them as
"undefined reference".

## The remaining blocker, precisely located
emx patches GNU binutils' BFD a.out backend to treat N_IMP1/N_IMP2 as import
definitions.  The core change is tiny and lives in `bfd/aoutx.h`:
  1. IS_STAB() must EXCLUDE (N_IMP1|N_EXT) and (N_IMP2|N_EXT).
  2. translate_from_native_sym_flags() needs cases:
       N_IMP1|N_EXT -> abs section, BSF_EMX_IMPORT1
       N_IMP2|N_EXT -> abs section, BSF_EMX_IMPORT2
Plus the matching writer side + BSF_EMX_IMPORT* flag allocation, and ld must
keep these symbols + their relocations in the output a.out so emxbind
(fixup.c: import_symbol / ref_proc) can build the LX import table.

The emx-patched binutils 2.6 source (that has all this) is in the emx
`gbinusrc.zip`; N_IMP handling is in its bfd/aoutx.h + bfd/emx-aout.c.
Porting those ~9 BFD files into modern binutils 2.30 is the remaining work -
this is the same step the ArcaOS/bitwiseworks toolchain maintainers have open
as unsolved ("ld fails to configure").  emxbind - the piece everyone assumed
was the hard part - is DONE here.

## License
emx is GPL (c) 1990-1998 Eberhard Mattes.  These sources are redistributed
under the GPL; the shim headers are build aids under the same terms.

## Host build environment (where emxbind.linux-x86_64 was built)
- OS:        Ubuntu 24.04.4 LTS (Noble Numbat)
- Kernel:    Linux 6.18.5 x86_64
- Compiler:  gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
- Arch:      x86_64 (dynamically linked, glibc)

The binary is a standard dynamically-linked x86-64 ELF; it should run on any
current x86-64 Linux with glibc.  If you need it fully portable, rebuild from
the sources here (the build line above) or link static (`gcc *.o -static -o
emxbind`).  It is a host build tool - it runs on the build machine, not on
OS/2, and not on the DOS/target side.

## Upstream contribution
The C sources here are unmodified upstream emx (see upstream/); the only new
work is shim/ (the reconstructed sys/moddef.h + libc-ism shims) that lets emx's
own emxbind build on modern Linux.  That shim set is the natural thing to offer
upstream (emx / bitwiseworks / ArcaOS toolchain), since a Linux-hosted emxbind
is an open request there.  See the repo's UPSTREAM-EMX.md for the writeup.

## IMPORTANT: build 32-bit
emxbind's a.out structs use C `long` (4 bytes on the original 32-bit target).
On 64-bit Linux `long` is 8 bytes, which corrupts every header struct.  Build
32-bit so the layouts are correct:
```
gcc -m32 -I. -Ishim -include shim/emxcompat.h -w -c *.c
gcc -m32 *.o -o emxbind
```
The shipped emxbind.linux-i386 is the 32-bit build (needs 32-bit glibc to run:
`apt install gcc-multilib libc6-dev-i386`).  The getopt string is prefixed with
"+" so the emx runtime options FPC appends (-ai -s8) aren't misparsed as
commands.  See OS2-LINK-STATUS.md for the full OS/2 link pipeline state.
