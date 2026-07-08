# BinkP-over-Modem — Specification

Status: design spec for the Mystic A38 fork (mystic_modem / mystic_mailer).
Scope: how a FidoNet BinkP mail session is carried over a dial-up modem link
instead of a TCP socket, and exactly what has to be built to make it work.
This documents intent and mechanism; it is not itself code.

--------------------------------------------------------------------
## 1. The problem in one sentence

BinkP (FTS-1026) was designed to run over TCP — a reliable, error-corrected,
in-order byte stream — and a raw modem line does not provide that, so the
missing reliability must come from somewhere before BinkP will work over a
phone call.

--------------------------------------------------------------------
## 2. Where the reliability comes from: V.42

We do NOT re-invent TCP's reliability inside BinkP.  Instead we rely on the
modems themselves.  Two modems that negotiate **V.42 (LAPM) or MNP 2-4**
error correction at connect time present each other with a clean, retransmitted
byte stream; **V.42bis / MNP5** add compression on top.  With error correction
active, the serial link behaves closely enough to a reliable stream that BinkP's
own framing rides on it unchanged.

Consequences that MUST be understood:

- Both modems MUST connect in an error-correcting mode.  A connection that
  falls back to a raw/direct mode (no V.42/MNP) is NOT safe for BinkP and should
  be refused or treated as best-effort only.
- This is a hardware/line reality.  No amount of code fully compensates for a
  non-EC link; the spec's correctness assumption is "EC is present end to end."
- Flow control must be hardware (RTS/CTS).  Software (XON/XOFF) flow control is
  unsafe because BinkP frames are binary and will contain the XON/XOFF bytes.

--------------------------------------------------------------------
## 3. What already exists in the fork

- **BinkP engine** — `mystic/mis_client_binkp.pas`, unit `MIS_Client_BINKP`,
  class `TBinkP`.  It implements the full BinkP session (handshake, addresses,
  password, file send/receive, acknowledgements).  It is proven over TCP today.
- **Serial layer** — `mystic_modem/mdm_serial.pas` (`TModemSerial`) and
  `mdm_fossil.pas` (`TFossil`): open/close, read/write, DTR/RTS, CTS/DSR/RI.
- **Modem control** — `mystic_modem/mdm_modem.pas` (`TModem`): init, answer,
  dial, CONNECT-speed parse, carrier detect, hangup.
- **Mailer front-end** — `mystic_mailer/`: answers, classifies the caller
  (EMSI / BinkP / human), and routes.  `mlr_binkp.pas` detects a BinkP caller
  and marks the hand-off seam.

The ONE missing piece is the adapter that lets `TBinkP` read/write the modem
line instead of a socket (section 6).

--------------------------------------------------------------------
## 4. BinkP frame format (as implemented in our engine)

Every BinkP block is length-prefixed with a 2-byte big-endian header:

    byte 0 : high 8 bits of a 16-bit value
    byte 1 : low  8 bits
    -> value = (byte0 << 8) or byte1
       bit 15 (0x8000) : 1 = command frame, 0 = data frame
       bits 0..14      : payload length (1..32767)

For a COMMAND frame the payload is:  <CmdType byte> <command args...>
For a DATA frame the payload is raw file bytes.

Our engine builds a command frame as (mis_client_binkp.pas):

    DataSize := (Length(CmdData) + 1) OR $8000;
    Write( Char(Hi(DataSize)) + Char(Lo(DataSize)) + Char(CmdType) + CmdData );

Command message IDs (our engine's values — authoritative):

    M_NUL=0  M_ADR=1  M_PWD=2  M_FILE=3  M_OK=4
    M_EOB=5  M_GOT=6  M_ERR=7  M_BSY=8

A session opens with command frames M_NUL / M_ADR (and M_PWD).  That opening
command frame is what the front-end sniffs to recognise a BinkP caller.

--------------------------------------------------------------------
## 5. Session flow over a modem

Answer side (our board receiving a poll):

1. Modem answers the ring (ATA); CONNECT negotiated with V.42 (section 2).
2. Front-end sniffs the first bytes.  A command frame whose header has bit 15
   set and whose CmdType is M_NUL/M_ADR/M_PWD  => BinkP caller (mlr_binkp
   `LooksLikeBinkp`).  (EMSI callers announce `**EMSI` instead; humans type.)
3. The sniffed bytes MUST be preserved and given to the BinkP engine as the
   first thing it reads — they are the start of the real session, not throwaway.
4. A TIOSerial adapter (section 6) is wrapped around the open modem line.
5. `TBinkP` runs its normal session over that adapter: M_NUL/M_ADR/M_PWD
   handshake, optional CRAM-MD5 (already in the engine), then M_FILE / data
   frames / M_GOT until M_EOB.  No BinkP logic changes.
6. On completion the mail bundles are on disk; the existing tosser
   (`mutil_echocore` / echoimport) processes them exactly as for BinkP/TCP.
7. Modem hangs up (drop DTR / ATH).

Call side (our board polling out over a modem) is the mirror image: dial
(ATDT), wait CONNECT with EC, wrap TIOSerial, run `TBinkP` as the client.

--------------------------------------------------------------------
## 6. The missing adapter: TIOSerial

This is the keystone and the only real new engine work.

- New unit: `mdl/m_io_serial.pas`, class `TIOSerial : TIOBase`.
- It implements the same virtual methods every other Mystic I/O class does
  (`ReadBuf`, `WriteBuf`, `DataWaiting`, `BufWriteStr`, `BufFlush`, `ReadChar`,
  `WaitForData`, ...), backed by `TModemSerial` / `TFossil` from mystic_modem.
- Template to copy: `mdl/m_io_stdio.pas` (TIOStdio, ~177 lines) — the existing
  non-socket TIOBase implementation used for local console sessions.

Integration note / caveat:

- Mystic's BinkP class currently declares `Client : TIOSocket` (a concrete
  type), not `Client : TIOBase`.  To drive it from a serial line WITHOUT
  forking the engine, relax that field/constructor to accept `TIOBase` (the
  abstract parent) so either a `TIOSocket` or a `TIOSerial` can be passed.
  This is a small, mechanical widening — every method it calls
  (BufWriteStr, BufFlush, WriteBuf, ReadBuf, ...) is already declared virtual
  on TIOBase — but it IS a change to a core file and must be done carefully and
  compiled/tested against the existing TCP path to prove no regression.
- A "pre-read buffer" is needed so the bytes the front-end already sniffed
  (section 5, step 3) are handed to the engine before fresh reads from the line.

--------------------------------------------------------------------
## 7. Buffer sizes and timing

- BinkP data frames can be up to 32767 bytes; our engine uses
  `BinkPMaxBufferSize`.  Serial reads are small and frequent, so TIOSerial must
  accumulate partial frames — `ReadBuf` returns whatever is available and the
  engine reassembles.  This already matches how the engine consumes a socket.
- Timeouts must be longer than for TCP.  A modem link at, say, 33.6k with
  compression still has more latency and variance than a LAN socket; the BinkP
  timeout value (TBinkP takes a TOV/timeout word) should be tuned up for serial.
- Carrier loss = session abort.  TIOSerial should treat DCD/DSR dropping as the
  equivalent of a socket close, so the engine ends the session cleanly.

--------------------------------------------------------------------
## 8. What is explicitly OUT of scope here

- Re-implementing BinkP.  We reuse `TBinkP` unchanged in logic.
- EMSI/Zmodem mail (the OTHER dial-up mailer style) — that is the EMSI path in
  `mlr_emsi.pas`, a separate handshake, documented with its own flow.
- Providing reliability for non-EC modems.  Out of scope by design (section 2).

--------------------------------------------------------------------
## 9. Build / test gate

- TIOSerial compiles on win32 + linux (mirrors TIOStdio; darwin maintained).
- Regression: the existing BinkP-over-TCP path MUST still build and behave after
  the `TIOSocket`->`TIOBase` widening (section 6).
- Live validation REQUIRES real hardware: two V.42-capable modems (or a modem
  on each end of a line/simulator).  Detection, framing and the adapter can be
  unit-tested in software, but a true BinkP-over-modem mail exchange can only be
  proven on the wire.  This is a sysop-side, hardware-gated test.

--------------------------------------------------------------------
## 10. Summary

BinkP already speaks to an abstract byte stream.  Give it a serial-backed
stream (TIOSerial) instead of a socket, ensure the modems supply reliability
via V.42, preserve the sniffed opening bytes, and lengthen the timeouts — and
the existing engine carries FidoNet mail over a phone call with no change to its
protocol logic.  The work is one adapter unit plus a careful one-line type
widening in the engine, then hardware testing.
