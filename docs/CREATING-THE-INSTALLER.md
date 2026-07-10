# Creating a Mystic A38 fork installer

How the fork's installer works, how `install_data.mys` is formatted, and how to
build a complete per-platform installer package from a set of binaries.

--------------------------------------------------------------------------------
## 1. What "the installer" is

Mystic installs itself with its own tools - there is no external setup program:

  * **`install`** - the installer binary.  Run in an empty directory, it unpacks
    a working BBS (menus, themes, text, scripts, data) and writes the initial
    config.
  * **`install_data.mys`** - the payload archive `install` reads.  It holds all
    135 default data files, grouped into sections.
  * **`install_make`** - the tool that *builds* `install_data.mys` from a
    directory tree (used when you change the default data).

So a "release installer" for a platform is simply a directory / zip containing:

    install            (+ install_make)      the installer binaries
    install_data.mys                          the payload
    <the other 12 program binaries>           mystic, mis, mutil, ...
    whatsnew.txt  upgrade.txt                 release docs
    FILE_ID.DIZ                               BBS file-listing description
    COPYING                                   GPLv3

`make_release.sh <tag> <bin-dir>` assembles exactly this (see §4).

--------------------------------------------------------------------------------
## 2. The `install_data.mys` format (MYS archive, version 3)

`install_data.mys` is the fork's own **MYS** archive.  It is **stored, NOT
compressed** - every file is copied in verbatim, preceded by a fixed-size header
record.  (Verified against the live file: 135 files, 2,793,210 bytes of data +
135x100-byte headers + a 12-byte archive header = 2,806,722 bytes on disk,
which is the exact file size.  There is no deflate/zlib/RLE step - `maAddFile`
in install_arc.pas is a plain BlockRead/BlockWrite byte copy.)

The format is defined in **mystic/install_arc.pas**.  On-disk layout:

### Archive header (12 bytes, once at the start)
    field     type          on-disk size   value
    Header    String[4]     6 bytes        'MYS' + #26  (0x04 'M' 'Y' 'S' 0x1a + pad)
    Version   Word          2 bytes        3
    Files     LongInt       4 bytes        135
  (SizeOf(maHeaderRec) = 12)

### Per-file record (100-byte header, then the raw file bytes)
    field     type          on-disk size   notes
    Header    String[4]     ~6 bytes       'MYS' + #26 (marks a valid record)
    FileName  String[80]    ~81 bytes      lower-cased name (no path)
    FileSize  LongInt       4 bytes        byte count of the stored file
    Execute   Boolean       1 byte         set from the +x bit on Unix at add time
    EID       String[6]     7 bytes        section id (see below)
  (SizeOf(maFileHdrRec) = 100)
  ...immediately followed by FileSize raw bytes of the file...

Records use FPC's default record alignment (String[4] rounds up), which is why
the header is 12 bytes and each file record is 100 bytes rather than the naive
byte sums.  Always compute offsets with `SizeOf`, not by hand.

### Sections (EID) in the shipped archive
    EID      files   contents
    DOCS       3     mystic.txt, records.110, door-install notes
    DATA      18     binary data / default databases
    TEXT      47     .ans / .asc screens and prompts
    MENUS     24     .mnu menu definitions
    SCRIPT    32     .mps/.mpx scripts + a few helper .exe
    ROOT      11     top-level files incl. some stock binaries
             ---
             135

`install` extracts the sections it needs by passing the matching EID to
`maOpenExtract(FN, EID, dir)`; files whose EID doesn't match are skipped.

--------------------------------------------------------------------------------
## 3. Rebuilding `install_data.mys` (only if you change the default data)

You normally DON'T rebuild it - the shipped `install_data.mys` is kept as-is
(single archive in mystic/, byte-identical across targets; see DECISIONS).
Rebuild only when the stock menus/themes/scripts/data change.

`install_make` drives `maOpenCreate` / `maAddFile` from install_arc.pas.  The
build groups files by section EID.  Conceptually:

    maOpenCreate('install_data', Add:=False)      // new archive
    for each section (DOCS, DATA, TEXT, MENUS, SCRIPT, ROOT):
      for each file in that section's source dir:
        maAddFile(path, EID, filename)            // stores the file verbatim
    maCloseFile                                   // writes the final header

Run `install_make` from the fork's data-source layout (the same tree the stock
archive was built from).  Because files are stored, the archive size is just the
sum of the inputs + 100 bytes per file + 12.  Keep names <= 80 chars, EIDs <= 6.

IMPORTANT: `install_data.mys` is a binary payload - it is marked `binary` in
.gitattributes and must never be line-ending converted.

--------------------------------------------------------------------------------
## 4. Building a per-platform installer package (`make_release.sh`)

    ./make_release.sh <tag> <bin-dir> [full|upgrade|both] [out-dir]
      tag  = lnx | win | mac | os2 | dos     (the target platform)
      mode = both (default) | full | upgrade
    -> writes into release/<tag>/  (mystic<tag>full.zip and/or mystic<tag>upd.zip)

### FULL vs UPGRADE
  * **FULL** (`mystic<tag>full.zip`): all 14 binaries + `install_data.mys`
    + docs + `FILE_ID.DIZ` labelled "`<tag> FULL`".  This is what a NEW sysop
    installs from - `install` unpacks the payload into an empty dir.
  * **UPGRADE** (`mystic<tag>upd.zip`): all 14 binaries + docs +
    `FILE_ID.DIZ` labelled "`<tag> UPGRADE`", but NO `install_data.mys`.  Drop
    the binaries over an existing install; data/menus/config are untouched.
    (See upgrade.txt for the per-version upgrade steps.)

Example (OS/2, built on Linux via the emx toolchain):

    LINK=1 ./build-os2.sh                     # -> out/bin-os2/*.exe
    ./make_release.sh os2 out/bin-os2         # both -> release/os2/mysticos2full.zip
                                              #        + release/os2/mysticos2upd.zip

The script: copies the bin dir, strips build intermediates
(`.o .ppu .a .s .out`), generates `FILE_ID.DIZ` (see §4a), adds
`whatsnew.txt` + `upgrade.txt` + `COPYING`, adds `install_data.mys` only in
FULL mode, and zips one archive per target.

### 4a. FILE_ID.DIZ and CRLF
Each release carries a `FILE_ID.DIZ` - the description a BBS shows in a file
listing.  It is generated from the per-target template `mystic/file_id.<tag>`,
with the title line's "`<tag> BINARIES`" replaced by
"`<tag> FULL`" or "`<tag> UPGRADE`", and written with **CRLF** line endings.

CRLF matters: FILE_ID.DIZ (like all BBS text artifacts) must be CRLF regardless
of the build host, or DOS/OS/2 BBS software renders it wrong.  Two safeguards:
  * `.gitattributes` pins `file_id.*`, `*.diz`, `whatsnew.txt`, `upgrade.txt`,
    `*.asc`, `*.mnu` to `text eol=crlf` (and `*.ans` to binary), so a checkout
    on any host keeps them CRLF - a cross-compile from Linux still ships correct
    DOS text.
  * `make_release.sh` force-normalises the generated DIZ to CRLF at pack time.

Note this is separate from RUNTIME text: the BBS itself emits the right newline
per platform via `LineTerm` in records.pas (CRLF for DOS/OS2/Win, LF for
Linux/Mac) - that's compiled in by target and needs no cross-compile handling.

### 4b. Build every platform at once
`make_all_releases.sh [full|upgrade] [out-dir]` compiles all five targets and
calls `make_release.sh` for each.  Each target is independent: if a target's
toolchain is missing it is skipped with a note and the others still build.

    ./make_all_releases.sh full                    # all FULL installers
    ./make_all_releases.sh upgrade                 # all UPGRADE bundles
    SDK=/path/to/MacOSX10.6.sdk ./make_all_releases.sh full   # incl. macOS

Toolchain env knobs: `WIN32RTL=` (Win32 RTL units), `SDK=` (macOS), the emx
toolchain on PATH (OS/2), and for DOS the bundled `libs/dos-toolchain.zip`
(auto-unpacked by `build-dos.sh`) plus optional `WATT32LIB=` for the networked
utilities.  See INSTALL and docs/DOS-SOCKETS.md.

### 4c. Where compiled binaries land (repo-root output dirs)
    Linux    out/bin/           (build.sh)
    Win32    out/bin-win/       (make_all_releases.sh; or the .bat's -FE dir)
    macOS    out_darwin/bin/    (build-darwin.sh)
    OS/2     out/bin-os2/       (build-os2.sh)
    DOS      out/bin-dos/       (build-dos.sh; 10/14 - networked utils need
                                 Watt-32 libwatt.a, see docs/DOS-SOCKETS.md)
All of `out/` and `out_darwin/` are gitignored - build output never enters the
repo.  Point `make_release.sh <tag> <bin-dir>` at the matching dir above.

### Which platforms produce a full installer
    Linux   14/14  native ELF
    Win32   14/14  PE32 (FPC internal linker)
    macOS   14/14  Mach-O (ld64 + SDK)
    OS/2    14/14  LX (built on Linux via libs/os2-linux-toolchain.zip)
    DOS      7/14  non-networked utilities only - no full installer yet
                   (networked programs need a DOS socket layer; see docs/TODO.md)

--------------------------------------------------------------------------------
## 5. Release layout & artifact naming

Each target gets its own directory under `release/`, named by the platform tag,
holding its FULL install and its UPGRADE bundle:

    release/
      lnx/  mysticlnxfull.zip     mysticlnxupd.zip
      win/  mysticwinfull.zip     mysticwinupd.zip
      mac/  mysticmacfull.zip     mysticmacupd.zip
      os2/  mysticos2full.zip     mysticos2upd.zip

    mystic<tag>full.zip FULL    - install + install_data.mys + docs + FILE_ID.DIZ
    mystic<tag>upd.zip  UPGRADE - binaries + docs + FILE_ID.DIZ (no payload)

    mystica38src<YYYYMMDD>.zip   full source release

A NEW sysop installs from `mystic<tag>full.zip` (FULL).  An existing sysop updates
in place with `mystic<tag>upd.zip` (UPGRADE - drop the binaries over the
install; data/menus/config are untouched; see upgrade.txt for per-version
steps).

There is deliberately no separate combined "binaries" bundle - the per-target
`mystic<tag>upd.zip` IS the binaries drop for that platform, so a combined
cross-platform bin archive would just duplicate it.

--------------------------------------------------------------------------------
## 6. Quick reference: verify an install_data.mys

To confirm a `.mys` file is valid (version 3, N files), read its header with the
real record types from install_arc.pas (SizeOf gives 12 / 100):

    archive header @0 : 'MYS'#26, Version=3, Files=N
    then N records   : each 100-byte header ('MYS'#26 + name + size + exec + EID)
                       followed by <size> raw bytes.

If the first 5 bytes are `04 4D 59 53 1A` you have a MYS archive; byte layout and
counts follow §2.
