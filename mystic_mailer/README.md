# mystic_mailer — sample FidoNet mailer front-end for Mystic A38

A **sample, self-contained** FrontDoor/BinkleyTerm-style *mailer front-end* that
owns the modem, answers the phone, and decides what kind of caller is on the
line — routing each to the right handler. It builds on the `mystic_modem/`
serial/modem/FOSSIL layer and **changes nothing in the Mystic source tree**.

Historically the mailer was a *separate program* from the BBS (FrontDoor,
BinkleyTerm, InterMail). This mirrors that: the mailer owns the line, and only
hands off to Mystic when a human calls.

## The three-way detector

After answering (CONNECT), the front-end listens for a few seconds and
classifies the caller:

| Caller announces… | Kind  | Handler |
|-------------------|-------|---------|
| `**EMSI_INQ` / `**EMSI_*` | EMSI mailer  | `mlr_emsi` handshake, then [stub] Zmodem mail |
| a BinkP command frame (M_NUL/M_ADR/…) | BinkP mailer | [seam] hand line to Mystic's BinkP engine via `TIOSerial` |
| a keystroke / nothing | human | [stub] spawn Mystic bound to the serial line |

## Units

- `mlr_emsi.pas`  — **real** EMSI handshake (FSC-0056): `EMSI_INQ` detection,
                    build/parse `EMSI_DAT` (address, system, password,
                    protocols), `EMSI_ACK`/`EMSI_NAK` with a CRC16-CCITT
                    checksum (verified against the $29B1 test vector).
- `mlr_binkp.pas` — BinkP-over-modem **detection** + the **integration seam**.
- `mailer.pas`    — the front-end program: answer → classify → route.

## What is real vs. stubbed (be honest about scope)

- **Real:** the EMSI handshake (INQ/DAT/ACK/NAK, CRC, field parsing) and the
  three-way caller detector.
- **Stub — Zmodem mail transfer:** after EMSI settles, real mailers Zmodem the
  bundles. That transfer is a separate chunk; the sample marks the point. Once
  bundles land on disk, Mystic's existing tosser (`mutil_echocore`) takes over
  unchanged.
- **Seam — BinkP over serial:** the sample does **not** re-implement BinkP.
  Mystic already has a full BinkP tosser/poller written against a `TIOBase`
  byte stream. Running it over the modem needs only a `TIOSerial : TIOBase`
  class (the same one the human/BBS path needs) — then the *existing* engine
  runs unchanged. `mlr_binkp` documents exactly where that hand-off goes.
- **Seam — human hand-off:** spawning Mystic bound to the serial line also needs
  `TIOSerial` + the parent→child handle hand-off.

## BinkP-over-modem: the V.42 assumption (important)

BinkP (FTS-1026) was designed for TCP — a reliable, error-corrected stream. A
raw modem link is not that. **BinkP-over-modem relies on the modems negotiating
V.42/MNP error correction (with V.42bis compression)** so the serial stream is
reliable enough for BinkP's framing to ride on top. On two error-correcting
modems over a decent line this works; on a noisy or non-EC link it is not safe.
**This assumption must hold on both ends.** It is a hardware reality the code
cannot fully paper over.

## Build

    ./build-mailer.sh          # linux i386
    ./build-mailer.sh win32    # needs FPC win32 with the serial unit

Depends on `../mystic_modem` and Mystic's `../mdl` units.

## Status

EMSI handshake + detector compile, link, and pass logic tests (CRC vector,
EMSI/BinkP classification) on Linux i386 (FPC 2.6.2). The transfer and hand-off
seams are the documented next steps, and all of it needs real modem hardware —
ideally V.42-capable on both ends — for live validation.
