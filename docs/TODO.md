# TODO / ROADMAP — Mystic BBS A38 Fork ("IRC")

> The ONE canonical roadmap. Read this first on resume.
> This file is FORWARD-LOOKING (what's left). For what's already DONE, see
> **whatsnew.txt** (user-facing changelog). For the deep record of *why* every
> change was made — decisions, corrections, "do NOT revert" notes, research
> findings — see **DECISIONS.md** (~1900 lines). Build instructions: **INSTALL**.

--------------------------------------------------------------------------

## STATUS (2026-07-07)

The substantive A39 feature-import work is essentially COMPLETE. The full list
of what landed is in whatsnew.txt; in brief: the FidoNet tosser subsystem, JAM
A51-compatibility, the ANSI draw mode, themed message boxes (|#B/|#I + the theme
editor screen), and the full message base index reader with its template
subsystem. All build 14/14 on win32 + linux, compile clean for Darwin, and are
cross-checked against the stock A51/A49 binaries. On-disk data format unchanged
(anchors SizeOf RecConfig=5282 / RecTheme=768 / RecEchoMailNode=901).

What remains is not more porting — it's PROOF. See item 1.

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
