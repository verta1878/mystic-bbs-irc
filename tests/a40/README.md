# A40 import — deferred compile/verify tests

These tests are **not run during the A40 import work** (to save build resources
on a loaded container).  Run them once the A40 import is complete, ideally with
the default 2.6.4irc r3 compiler (`libs/fpc264irc.tar.gz`); 2.6.2 also works.

## What A40 touched (the code under test)

- `mystic/records.pas` — `RecEchoMailNode` gained `MaxPktSize`, `MaxArcSize`
  (Word, KB, 0=none), consuming reserved `Res[]` bytes.  **Anchor: SizeOf must
  stay 901.**
- `mystic/bbs_cfg_echomail.pas` — echonode editor "Max PKT KB" / "Max ARC KB".
- `mystic/mutil_echoexport.pas` — MaxArcSize bundle roll + MaxPktSize PKT split
  (via `GetFTNPKTName`), and netmail (NetType 3) exempt from the EchoTag gate.
- `mystic/bbs_database.pas` + `mystic/mutil_common.pas` — netmail routing stage 1
  (direct address match before Route Info) added to both copies of
  `GetNodeByRoute`.

## How to run

```
./tests/a40/run.sh            # anchor check + compile the 3 changed units
FPC=/path/to/ppc386 ./tests/a40/run.sh
```

Requires the fork source tree at repo root (mdl/, mystic/) and an FPC 2.6.4irc r3 or
2.6.2 `ppc386` on PATH (or via FPC=).

## Checks performed

1. **Anchor**: `SizeOf(RecEchoMailNode)=901`, plus RecConfig=5282, RecUser=1536,
   RecTheme=768 (via `check_anchors.pas`).
2. **Compile**: `records`-dependent unit `bbs_cfg_echomail.pas` and
   `mutil_echoexport.pas` compile clean (the A40 edits).
3. **logstamp** (`check_logstamp.pas`): the A40 configurable log-file timestamp
   (`[General] logstamp=`) - verifies `FormatDate` renders every A40 code
   (YYYY/YY/MM/DDD/DD/HH/II/SS/NNN).  The feature itself was already present in
   the fork (INI read in `mutil.pas`, applied per log line in `mutil_common.pas`
   via `FormatDate`); this test guards against regressions.
4. **Behavior (manual, live)**: the items that can only be confirmed on a real
   node — see "Live verification" below.  Not automated here.

## Live verification (manual, on node 152/158)

The following were read-verified only during import and need a real toss test:
- PKT split: set a small "Max PKT KB" on a node, export enough mail to exceed
  it, confirm multiple PKTs are produced, bundled, and routed to that node.
- Bundle split: set a small "Max ARC KB", confirm multiple bundle files roll.
- Netmail no-link: create a NetMail base with NO echo tag / no node link, post a
  netmail to a routable address, confirm it exports (previously it was skipped).
