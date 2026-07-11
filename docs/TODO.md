# TODO / ROADMAP — Mystic BBS A38 Fork ("IRC")

> The ONE canonical roadmap. Read this first on resume.
> This file is FORWARD-LOOKING (what's left). For what's already DONE, see
> **whatsnew.txt** (user-facing changelog). For the deep record of *why* every
> change was made — decisions, corrections, "do NOT revert" notes, research
> findings — see **DECISIONS.md** (~1900 lines). Build instructions: **INSTALL**.

--------------------------------------------------------------------------

## STATUS (2026-07-08)

The substantive A39 feature-import work is essentially COMPLETE. The full list
of what landed is in whatsnew.txt; in brief: the FidoNet tosser subsystem, JAM
A51-compatibility, the ANSI draw mode, themed message boxes (|#B/|#I + the theme
editor screen), and the full message base index reader with its template
subsystem. All build 14/14 on win32 + linux, compile clean for Darwin, and are
cross-checked against the stock A51/A49 binaries. On-disk data format unchanged
(anchors SizeOf RecConfig=5282 / RecTheme=768 / RecEchoMailNode=901).

NEW (2026-07-08): RIP graphics Phase 1 landed — the ripterm client engine is
now IN THE TREE as a self-contained example module, mystic_rip/ (TTermRip in
rip_term.pas — the TTermAnsi parallel — plus the rip_canvas seam, software
surface, SDL viewer and demos; FPC RTL units only, no mdl deps). Verified
both platforms; renders pixel-identical to the client reference. Promotion
to mdl/ happens at the live hook-up. Design + status: docs/RIP-INTEGRATION.md.
Phases 2/3 below (item 4).

What remains on the A39 side is not more porting — it's PROOF. See item 1.

--------------------------------------------------------------------------

## ORIENTATION (on resume, do this first)

  1. cd /home/claude/mystic-src/msrc110a38
  2. Confirm the tree + FPC 2.6.2 are present; run a baseline build before new
     work. If the container reset wiped the tree, restore from the latest
     mystic-A38fork-source-*.zip in /mnt/user-data/outputs/, then re-read this
     file + DECISIONS.md.
  3. Invariants to verify after ANY records.pas change:
       SizeOf(RecConfig)=5282, SizeOf(RecTheme)=768, SizeOf(RecEchoMailNode)=901
  4. Ground truth for "what shipped": the A51 binaries (1.10) and A49 binaries
     (1.12). Real board .jdx/.jhr files are the ultimate proof for JAM/data
     behavior. User-facing UI strings are conclusive; internal symbol names are
     not (may not appear in `strings`).
  5. Build check = 14 programs, both platforms, plus Darwin-compile clean. See
     INSTALL.

--------------------------------------------------------------------------

## 1. FINAL VALIDATION GATE — Live FTN testing on the board (SYSOP to run)

Node 152/158, tnabbs.org. Nothing else matters as much as this. Everything
compiles and matches the shipped binaries, but none of it is truly proven until
real echomail flows through a live node.

Test on the board:
  - Tosser inbound: import a real packet; confirm dupe detection catches a
    re-sent message (SEEN-BY aware).
  - Tosser outbound: bundle + queue mail; confirm it routes to the right uplinks
    via GetNodeByRoute; check the FLO queue.
  - Semaphore .out files: confirm they trigger the tosser.
  - Hide AKAs: enable on a node, poll an uplink, confirm only the uplink's-zone
    AKAs are advertised in the BinkP handshake.
  - RefuseForeign: mis.ini RefuseForeign=false accepts foreign-domain mail;
    =true (or no file) rejects it.
  - AreaFix (echofix): subscribe/unsubscribe an echo, confirm it works.
  - Index reader (NEW): menu command 'I' / MI opens the message base index —
    a searchable list of all bases with total/new/personal counts; scroll,
    search, select to read. Needs the ansimidx.* files (in default_theme_text/)
    dropped into the theme's text dir, and at least one message group.

Whatever surfaces here IS the next real work.

--------------------------------------------------------------------------

## 2. OPTIONAL POLISH (deferred by choice — current behavior works)

  (Nothing currently pending.  The RefuseForeign setting was moved from the
  interim data/mis.ini into the config editor — Config -> Servers -> SMTP Server
  -> Allow Foreign — on 2026-07-07; see whatsnew.txt / DECISIONS.md.)

--------------------------------------------------------------------------

## 3. OPEN INVESTIGATIONS (watch, need live observation — don't necessarily act)

  - ZMODEM "transfers stopped": the nodespy protocol-layer unification (m_prot_*
    vs old m_protocol_*) MAY be relevant. Live testing will tell. The 2TB figure
    is impossible by protocol (32-bit offset); likely escaping/timing.
  - XP socket anomaly: code binds AF_INET6/'::' dual-stack; XP has no IPv6 yet
    accepts telnet. Mechanism unknown. KEEP the working code, flagged.
  - ANSI high-ASCII bleeding (chars 128-255): in output (m_output_*) AND parser
    (bbs_ansi*); strStripPipe a candidate.

--------------------------------------------------------------------------

## 4. RIP GRAPHICS — Phase 1 DONE, next phases

  Engine landed 2026-07-08 (see docs/RIP-INTEGRATION.md §9 for exactly what
  went where). Remaining, in design-doc order:

  - Phase 2a (renderer): fill patterns (RIP 'S'/'s'), line styles/thickness
    ('='), stroked/scalable fonts ('Y' text settings), the button/icon system
    ('U','1B' level-1 buttons) with <clk> invert feedback, text windows ('w')
    and viewports ('v') instead of the simplified whole-screen 'e'/'E' clear.
  - Phase 2b (hook-up): give TTermRip a live seat next to TTermAnsi — an
    RIP-capable front-end path (nodespy_term / mystic_sdl session) that
    auto-detects RIP and routes the stream; wire TRipWindow.OnRegionClick to
    the connection so hot-region clicks type at the host. THIS is the
    promotion point: rip_term.pas -> mdl/m_term_rip.pas, reply callback ->
    TIOBase. Threading (if any) = FPC TThread/cthreads (like
    m_socket_server), never a custom layer.
  - Phase 2c (emitter): serve RIP from the BBS side — author screens ->
    '!|' sequences, the way ANSI is emitted from templates/MCI today.
  - Phase 3: Beziers ('Z'), polygons ('P'/'p'), clipboard ops ('C' level-1
    extended), RIP_QUERY replies via the SetReplyClient seam, the rare-command
    long tail.
  - Environment note (RESOLVED 2026-07-08 for the shipped lib): the FPC 2.6.2
    i386 "crash in SDL_Init" was the 4-byte vs 16-byte i386 stack-alignment
    mismatch with modern distro SDL. libs/linux-i386/libSDL2-2.0.so.0 is now
    built from 2.32.8 source WITH -mstackrealign and runs clean (rip_view and
    sdl_demo verified headless). A stock distro SDL will still crash; use the
    bundled one. Windows SDL2.dll was never affected.

--------------------------------------------------------------------------

## 5. OS/2 TARGET — source done, native link + live test outstanding

  Source ported and compiles 14/14 for i386-os2 (cross, compile-only) as of
  2026-07-08; details + toolchain in docs/DECISIONS.md. Remaining:
  - OS/2 NATIVE LINK: the container can compile but not link OS/2 (needs
    emxbind + EMX OS/2 import libs; FPC's os2 link is ld-then-emxbind). Build
    natively on OS/2/eComStation/ArcaOS with the FPC 2.6.2 OS/2 release
    (period-matched to this fork's compiler). This produces the actual .exe.
  - LIVE SHAKE-OUT on real OS/2: m_io_stdio's OS/2 WaitForData is a blocking
    stub (revisit with DosPeekNPipe if a nonblocking poll is needed); confirm
    so32dll TCP/IP sockets, TProcess per-node spawning, and door drop-file
    behavior. Sysop has OS/2 history - this is his gate.
  - Optional: once linking works, wire an os2 arm into build.sh (today it's
    linux/win32/darwin).

--------------------------------------------------------------------------

## 6. 1.12 FILE_ID / DIZ support (9a + 9b DONE)

  9a DONE (2026-07-09): color-aware DIZ. mdl/m_strings.pas strDizColor()
  preserves pipe codes + converts ANSI SGR color to pipe; wired into
  bbs_filebase ReadDIZ and mutil_upload. Verified 14/14 + unit test.
  Still pending (minor, fold in later):
  - @BEGIN_FILE_ID.DIZ inline-tag scanner (description embedded in a text file).
  - Raise the desc line cap toward 99 (mind mysMaxFileDescLen=50 + MsgText).
  - Wildcat/PCBoard/WWIV color notations (only ANSI+pipe handled so far).
  9b DONE (2026-07-09): full-screen FILE_ID.ANS archive viewer.
  TFileBase.ShowFileIDAns extracts FILE_ID.ANS (same ExecuteArchive path as
  the DIZ reader) and shows it via OutFile; hooked into ArchiveView (auto-
  shows cover on open) + an 'A' key to redisplay. Reused existing PArchive/
  ExecuteArchive/OutFile infra. 14/14 build.
  Intentionally skipped (niche): @BEGIN_FILE_ID.DIZ inline scanner,
  Wildcat/PCBoard/WWIV color notations, desc-width 50->79 (all-desc change).

## 7. cryptlib win32 cross-build (feasibility proven; finish the wiring)

  Answered: cl32.dll CAN cross-compile with mingw. docs/patches/
  cryptlib-mingw-endian.patch (one endian branch) makes the entropy module
  random/win32.c compile under i686-w64-mingw32. Remaining: wire cryptlib's
  makefile win32 target (target-init win32 + WIN32ASMOBJS) to the mingw prefix
  and link the DLL, then drop it in libs/win32/cl32.dll. Or use a vendor
  (commercial-license) DLL. See DECISIONS.md 2026-07-09.

## 8. Release packaging (tooling done; use it per build)

  file_id.diz = master example (literal "xxx BINARIES"); 6 per-target files
  file_id.{win,lnx,os2,mac,dos} each have their tag filled in.
  make_release.sh <tag> <bin-dir> copies file_id.<tag> into a per-target
  archive renamed to FILE_ID.DIZ. One archive per target, never combined.
  (dos DIZ exists; no dos build target yet - come back to it.)

--------------------------------------------------------------------------

## INTENTIONAL DIVERGENCES — do NOT "align" these back to A39/A51

  - qwkpoll PrintLog: our qwkpoll logs each poll line to a timestamped
    qwkpoll.log (fork enhancement). A39/A51 use plain WriteLn. KEEP OURS.
  - RefuseForeign via mis.ini: fork-original; A51 hardcodes the refusal. Ours is
    a strict superset (identical by default, adds an escape hatch).
  - JAM CRC = StringCRC32 (raw), matching A51/1.10. Verified vs real board data.
    NOTE: 1.12 uses LOWERCASED JAM CRCs (per A34 changelog) — a known
    1.10-vs-1.12 divergence. Correct for our 1.10 base; do NOT undo without real
    1.12 data.
  - GetMBaseByIndex kept returning Boolean (ours) vs A39's LongInt. AreaIndex was
    adapted to our Boolean API; all our callers rely on it.

--------------------------------------------------------------------------

Everything done is in whatsnew.txt; every decision + rationale is in DECISIONS.md
(incl the JAM CRC 1.10-vs-1.12 timeline, the template subsystem, A49 cross-checks,
and SizeOf anchors). A fresh session picks up from item 1.

o7

## DOS port - networking (socket layer DONE; needs Watt-32 libwatt.a)

DONE (2026-07-09): DOS builds 10/14, including the mystic server. The socket
layer is written and the binutils link blocker is solved - both in the repo.

  - mdl/sockets_go32v2.pas: a complete FPC-Sockets-compatible BSD API (TCP+UDP,
    DNS, select, sockopts, address helpers) bound to Watt-32. The fork's code
    is unchanged; go32v2 `Uses sockets_go32v2` in place of the RTL Sockets unit
    (which FPC 2.6.2's go32v2 target does not ship). This keeps the fork's code
    Pascal on our PINNED 2.6.2 - no risky re-pin to 3.0.4/3.2.2, so the SizeOf
    record anchors stay intact.
  - libs/dos-binutils-patch/: the C_SECTION(0x68) fix so GNU ld reads FPC
    objects (stock binutils 2.30 rejected them, breaking any C-library link).
    Includes the pristine binutils-2.30 source tarball (GPL source travels with
    the repo). The patched ld/nm/objdump are in libs/dos-toolchain.zip.
  - DOS code gaps closed: m_io_stdio, m_pipe, mis_events ShellExec, go32v2 MD5.

REMAINING - build Watt-32 (libwatt.a) for djgpp/go32v2:
  - build-dos.sh already wires the link: set WATT32LIB=<dir-with-libwatt.a> and
    it adds -Fl<dir> -k-lwatt. With libwatt.a present the 4 networked programs
    (mis/fidopoll/nodespy/qwkpoll) link.
  - Watt-32 is external C (a real TCP/IP stack + a runtime packet driver), NOT
    bundled - it is a build/runtime dependency like a driver. Candidate sources:
    the jwt27/watt32 djgpp cross-compile fork, gvanem/Watt-32, sezero/watt32.
    Check the specific fork's LICENSE before bundling any Watt-32 SOURCE (the
    old Waterloo "may not sell" clause is non-standard; not legal advice).
  - Then: link-test, and runtime shake-out with a packet driver + WATTCP.CFG.

CONCURRENCY: Watt-32 handles multiple concurrent sockets (it has select_s). The
DOS constraint is no preemptive threads, not "one connection". The DOS mis
Execute currently serves one caller at a time (bring-up simplification); a
cooperative select() accept-loop for multiple concurrent nodes is the planned
upgrade. See docs/DOS-SOCKETS.md.
