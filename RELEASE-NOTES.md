# Mystic BBS 1.10 A38 — Community IRC Fork — Release Notes

**Release date:** 2026-07-09
**Base:** Mystic BBS 1.10 alpha 38 (A38), brought to ~1.10 A39 feature level
**Repository:** https://github.com/verta1878/mystic-bbs-irc
**License:** GNU General Public License v3 (GPLv3)
**Live node:** Ecstasy BBS — FidoNet 152/158 — tnabbs.org

This document is the single, complete reference for the release: what's in it,
which platforms it runs on, how the binaries and source are packaged, how to
build and install it, and what is and isn't finished. It supersedes scattered
notes; for day-to-day build detail see INSTALL and docs/.

================================================================================
## 1. What this release is

A clean, buildable, well-documented community fork of the Mystic BBS 1.10 A38
source, released under the GPLv3. The goal is a tree the BBS scene can build,
run, study, and carry forward across the platforms Mystic historically targeted
— now including a fully self-hosted **OS/2 build on Linux**.

Feature level is roughly Mystic 1.10 A39: the FidoNet tosser, JAM/Squish
compatibility, ANSI draw mode, themed message boxes, and the full message-base
index reader are all in. On-disk record layouts are held byte-compatible with
stock Mystic (RecConfig=5282, RecTheme=768, RecEchoMailNode=901, RecUser=1536),
so existing data files and third-party tools keep working.

================================================================================
## 2. Platform / build matrix

All 14 core programs (see §3) build for four platforms; a fifth (DOS) is
partial. Everything below is built from a single Linux host with FPC 2.6.2.

    Platform   Binaries  Format                 Toolchain
    --------   --------  --------------------   ---------------------------------
    Linux      14/14     ELF 32-bit i386        native ppc386
    Win32      14/14     PE32 i386 (XP+)        FPC internal PE linker
    macOS      14/14     Mach-O i386 (10.6+)    ld64 + Apple SDK (you supply)
    OS/2       14/14     LX (emx 0.9d)          self-hosted emx toolchain ON LINUX
    DOS        7/14      MZ/COFF/DJGPP go32v2   go32v2 cross toolchain

Notes:
  * **OS/2 is the headline.** The final OS/2 link (a.out -> LX .exe) now runs
    entirely on Linux — historically it required an OS/2 machine. See §6.
  * **DOS is partial (7/14).** The non-networked utilities build; the five
    networked programs need a DOS socket layer (Watt-32 or FOSSIL) that isn't
    written yet. See §8.
  * macOS binaries are built and linked but runtime-untested (i386 macOS needs
    a 10.4–10.14-era machine).

================================================================================
## 3. The 14 core programs

    mystic         the BBS server / login shell
    mis            Mystic Internet Server (telnet/IRC/socket services)
    mutil          maintenance utility (packing, indexing, imports)
    mplc           Mystic Pascal Language Compiler (menu/door scripts)
    mide           the script IDE
    mbbsutil       BBS utility helpers
    fidopoll       FidoNet/FTN mail poller + tosser
    nodespy        node monitor
    qwkpoll        QWK network poller
    mystpack       message base packer
    install        the installer (unpacks install_data.mys into a new BBS)
    install_make   builds install_data.mys from a data tree
    maketheme      theme builder
    109to110       1.09 -> 1.10 data converter

================================================================================
## 4. Optional example modules (mystic_*)

These are **separate, self-contained example modules** that show how the fork
can be extended. They are drop-in / runtime-loaded and do not touch the core
record layout. Each has its own README.

    mystic_rip     RIPscrip 1.x terminal engine (graphics terminal)
    mystic_sdl     full-screen SDL DOS-text renderer front-end
    mystic_spell   on-the-fly spell checking (Hunspell)
    mystic_crypt   optional SSH/TLS transport example (cryptlib)
    mystic_mailer  FrontDoor/BinkleyTerm-style FTN mailer front-end
    mystic_modem   real serial-modem dialup support
    mystic_misdos  recreation of the classic Mystic "MIS/DOS" behavior

================================================================================
## 5. Bundled runtime & build libraries (libs/)

Runtime libraries (i386, runtime-loaded — "drop-in DLL" model):

    libs/win32/       SDL2 2.32.8, libhunspell, cl32.dll (cryptlib) — Wine-verified
    libs/linux-i386/  SDL2, Hunspell, cryptlib
    libs/darwin-i386/ SDL2 2.0.1, Hunspell 1.6.2, cryptlib (built on 10.6 SDK)

Build toolchains (self-contained zips):

    libs/dos-toolchain.zip        FPC 2.6.2 compiler + go32v2 binutils + RTL
                                  (self-contained DOS cross toolchain)
    libs/os2-linux-toolchain.zip  the emx-on-Linux toolchain: emxbind Linux port,
                                  binutils patches + a.out-emx target, emxl.exe,
                                  ld wrapper, upstream emx sources, full docs
    libs/ld64-linux-x86_64/       cctools ld64 for the macOS cross-link

Each library is used under its own license (see the LICENSE files in libs/);
their inclusion is "mere aggregation" in the GPL sense. Match library bitness
to the build (all provided binaries are i386).

================================================================================
## 6. OS/2 on Linux — the self-hosted emx toolchain (headline feature)

FPC's OS/2 target compiles to a.out, then links via `ld` + `emxbind` into an
OS/2 LX executable. That link historically ran only on OS/2. This release makes
it run **entirely on a Linux x86-64 host** — the same problem the ArcaOS /
bitwiseworks maintainers track as an open "emx toolchain on Linux" issue.

    $ ppc386 -Tos2 ... maketheme.pas
    $ file maketheme.exe
    maketheme.exe: MS-DOS executable, LX for OS/2 (console) i80386, emx 0.9d

The solution has five parts, all included and documented:

  1. **binutils N_IMP patch** — teaches GNU ld to resolve emx a.out IMPORT#
     DLL symbols (N_IMP1/N_IMP2), the piece considered the hard blocker.
  2. **a.out-emx BFD target** — a new binutils target with emx's a.out layout
     (text at file 0x400, vaddr 0x10000, 64 KB data segment).
  3. **emxbind Linux port** — Eberhard Mattes' GPL emxbind built to run on
     Linux (32-bit build; getopt fix; small shim layer).
  4. **emxl.exe loader** — the emx loader stub emxbind binds into the image.
  5. **data-alignment ld wrapper** — places the data segment on the 64 KB
     boundary emxbind expects.

Build it: unpack `libs/os2-linux-toolchain.zip`, follow
`docs/os2-linux-toolchain/BUILD-ON-UBUNTU-24.04.md`, put the tools on PATH, then
`LINK=1 ./build-os2.sh`. Full technical reference (format, every fix, an
emxbind-error -> fix debug map) is in
`docs/os2-linux-toolchain/TECHNICAL-REFERENCE.md`; the patches are in
`libs/emxbind-src/binutils-patch/`.

emx is GPL (c) 1990–1998 Eberhard Mattes; the port and patches are offered under
the GPL. `UPSTREAM-EMX.md` is a paste-ready contribution writeup for
bitwiseworks/ArcaOS, FPC, and the emx project.

================================================================================
## 7. Building from source

Prerequisites: FPC 2.6.2 (i386) as `ppc386`; for OS/2 the emx toolchain on
PATH; for macOS an Apple 10.6 SDK (`SDK=...`). Full detail in INSTALL and
docs/os2-linux-toolchain/.

    ./build.sh                         # Linux   -> out/bin/          (14/14)
    ./build-win32.bat  (or the loop)   # Win32   -> out/bin-win/      (14/14)
    SDK=... ./build-darwin.sh          # macOS   -> out_darwin/bin/   (14/14)
    LINK=1 ./build-os2.sh              # OS/2    -> out/bin-os2/      (14/14)
    (DOS: go32v2 cross, 7/14 utilities -> out/bin-dos/)

Compiled-binary output directories (all gitignored — build output never enters
the repo):

    Linux out/bin   Win32 out/bin-win   macOS out_darwin/bin
    OS/2  out/bin-os2   DOS out/bin-dos

Cross-platform text: the BBS emits the right newline per target at runtime via
`LineTerm` in records.pas (CRLF for DOS/OS2/Win, LF for Linux/Mac). Shipped BBS
text artifacts (FILE_ID.DIZ, whatsnew, upgrade, .asc, .mnu) are pinned to CRLF
via `.gitattributes` so a Linux cross-compile still ships correct DOS text.

================================================================================
## 8. DOS status (partial — on hold)

The go32v2 DOS toolchain (`libs/dos-toolchain.zip`) is self-contained and
proven. The 7 non-networked utilities build (maketheme, mplc, mutil, mystpack,
install, install_make, 109to110). The 5 networked programs (mystic, mis,
fidopoll, nodespy, qwkpoll) need a socket layer the pinned FPC 2.6.2 go32v2 RTL
does not provide.

Preferred direction (sysop): use an **FPC-native** socket path rather than a
hand-written C shim — i.e. build the DOS network programs with the last FPC
version whose go32v2 target ships a usable `Sockets` unit, so the networking
comes from the Pascal RTL. This must be verified when DOS resumes (2.6.2, our
pin, has no such unit; the current 3.0.4/3.2.2 DOS builds are the ones to
check), and note that DOS TCP/IP on DJGPP still typically relies on a Watt-32
stack + packet driver underneath even when the Pascal side is just a Sockets
unit. Fallbacks: a Watt-32 BSD-sockets binding, or a FOSSIL/telnet gateway
(separate `m_io_fossil` path).

DOS platform branches (m_ops, records, m_fileio, m_output, m_input) are in the
tree; the socket layer is the remaining work. On hold per sysop. See docs/TODO.md.

================================================================================
## 9. The installer and the MYS payload

Mystic installs itself with its own tools — no external setup program:

  * `install` unpacks a working BBS from `install_data.mys`.
  * `install_data.mys` is the fork's **MYS** archive (version 3): **stored, not
    compressed** — 135 files across 6 sections (DOCS 3, DATA 18, TEXT 47,
    MENUS 24, SCRIPT 32, ROOT 11). Format defined in mystic/install_arc.pas.
  * `install_make` rebuilds the payload from a data tree (only needed if you
    change the stock menus/themes/scripts/data).

Full format spec and build detail: `docs/CREATING-THE-INSTALLER.md`.

================================================================================
## 10. Release artifacts & how they're packaged

### Per-target release directories
Each platform gets its own directory, holding a FULL install and an UPGRADE
bundle:

    release/
      lnx/  mysticlnxfull.zip     mysticlnxupd.zip
      win/  mysticwinfull.zip     mysticwinupd.zip
      mac/  mysticmacfull.zip     mysticmacupd.zip
      os2/  mysticos2full.zip     mysticos2upd.zip

    mystic<tag>full.zip   FULL    — 14 binaries + install_data.mys + docs +
                                    FILE_ID.DIZ labelled "<tag> FULL"
    mystic<tag>upd.zip    UPGRADE — 14 binaries + docs + FILE_ID.DIZ labelled
                                    "<tag> UPGRADE" (no payload; drop over an
                                    existing install)

Docs in every archive: whatsnew.txt, upgrade.txt, COPYING (GPLv3), and a
per-target FILE_ID.DIZ (CRLF).

### Building the archives
    ./make_release.sh <tag> <bin-dir> [full|upgrade|both] [out-dir]
    ./make_all_releases.sh [full|upgrade|both] [out-dir]   # every platform

`make_release.sh` strips build intermediates, generates the CRLF FILE_ID.DIZ,
adds docs, includes install_data.mys only in FULL, and writes into
`release/<tag>/`.

### Source release
    mystica38src<YYYYMMDD>.zip    the full source tree (this repo, minus .git and
                                  build output). Includes all sources, the
                                  optional modules, libs/ (runtime libs +
                                  toolchain zips), and all docs.

================================================================================
## 11. Documentation map

    README.md                        overview + quick build table
    START-HERE.md                    orientation + current state
    INSTALL                          full per-platform build instructions
    UPSTREAM-EMX.md                  paste-ready upstream contribution writeup
    COPYING                          GPLv3

    docs/CREATING-THE-INSTALLER.md   installer + MYS format + release process
    docs/DECISIONS.md                the running record of locked decisions
    docs/TODO.md                     open items (incl. DOS sockets)
    docs/SAVE-STATE.md               session-continuity snapshot
    docs/RIP-INTEGRATION.md          RIP graphics integration notes
    docs/os2-linux-toolchain/        the OS/2-on-Linux toolchain docs:
      README.md                        index
      TECHNICAL-REFERENCE.md           format + every fix + debug map
      BUILD-ON-UBUNTU-24.04.md         from-scratch reproduction recipe

    libs/README.md                   runtime-lib provenance + toolchain index
    libs/DOS-TOOLCHAIN-README.md     DOS toolchain usage
    libs/emxbind-src/                emxbind sources, shim, patches, status

================================================================================
## 12. Known limitations / open items

  * DOS: 7/14 (no socket layer yet — Watt-32 or FOSSIL). On hold.
  * macOS: built + linked, runtime-untested (needs an i386-era Mac).
  * OS/2: builds fully on Linux; live shake-out on real OS/2/ArcaOS is the gate.
  * Live FidoNet validation of the tosser on node 152/158 is sysop-side.
  * Version string reads "1.10 A38" internally while the DIZ shows the fork
    version — cosmetic, tracked in TODO.
  * Upstream emx contribution (UPSTREAM-EMX.md) is prepared but must be posted
    by the maintainer.

================================================================================
## 13. Licensing summary

  * The fork (all Pascal sources, scripts, docs): **GPLv3** — see COPYING.
  * emx / emxbind / the OS/2 toolchain patches: **GPL** (c) Eberhard Mattes;
    corresponding source in libs/emxbind-src/upstream/.
  * GNU binutils patches: **GPL**.
  * Bundled runtime libs (SDL2, Hunspell, cryptlib, ld64/cctools): each under
    its own license (see libs/*-LICENSE*.txt); "mere aggregation".
  * The Apple macOS SDK is NOT redistributed — the sysop supplies it locally.

================================================================================
## 14. Credits

Fork maintained by Antonio Rico (Reapern66). Base Mystic BBS (c) 1997–2013 by
James Coyle. emx / emxbind (c) 1990–1998 Eberhard Mattes. FidoNet node 152/158,
Ecstasy BBS (tnabbs.org).
