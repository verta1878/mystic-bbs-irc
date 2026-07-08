# mystic_modem — legacy dialup / serial modem support for Mystic A38

A **self-contained, optional** module that adds real serial-modem dialup support
(the classic "Waiting For Caller" workflow) to Mystic BBS 1.10 A38.  It is kept
**separate from the main A38 source** so it can be dropped in without disturbing
the existing telnet/TCP code, then wired in when you're ready.

Legacy dialup was removed from Mystic before its GPL source release (the 1.10
line is TCP/telnet only).  This module reconstructs that capability on top of
Free Pascal's cross-platform `Serial` unit (FPC 2.6.2+), so it builds for both
Win32 (COM ports) and Linux (/dev/ttyS*, /dev/ttyUSB* for USB serial adapters).

## Units

- `mdm_serial.pas`   — thin cross-platform serial layer over FPC's `Serial` unit
                       (open/close, params, read/write, DTR/RTS, CTS/DSR/RI).
- `mdm_fossil.pas`   — a FOSSIL-style comms abstraction (init/deinit, tx/rx,
                       carrier detect, DTR, flush, status) with two backends: the
                       native `mdm_serial` layer (Win32/Linux) and a real INT 14h
                       path compiled only for a DOS target (X00/BNU/NetFoss).  Code
                       written FOSSIL-style runs on modern systems and drops onto
                       real DOS+FOSSIL unchanged.
- `mdm_modem.pas`    — Hayes AT command modem control: init, answer, dial,
                       carrier detect/drop, hangup.  Init/dial strings config.
- `mdm_config.pas`   — a small INI-based config (modem.ini) so this module needs
                       NO changes to Mystic's RecConfig / MYSTIC.DAT.  Includes a
                       `usefossil` switch and `fossilport`.
- `mdm_wfc.pas`      — the Waiting-For-Caller screen with a live modem window
                       (status line state, RING detect, connect at N baud).
- `mdm_miswfc.pas`   — a MIS-style WFC status screen (titled panel + fields +
                       hot-key bar), drawn like the Internet Server's screen.
- `modemcfg.pas`     — an interactive setup tool so a sysop can configure the
                       modem (device, baud, init string, rings, flow control,
                       FOSSIL, local mode) without hand-editing modem.ini.
                       Shared by both add-on modules.
- `WFCSCRN.ANS`     — an authentic blue ANSI Waiting-For-Caller screen echoing
                       the Mystic 1.07 DOS layout: caller-info fields (Alias/Name/
                       Address/Email, Baud/Sec/Time/Flags), modem status, and the
                       full sysop command bar (Chat/Split/Edit/Hangup/DOS/Upgrade/
                       Status Bar/Offhook/Local Logon/Exit).  Point `wfcscreen` at
                       it in modem.ini; ShowWfcAnsi streams it to the console.
- `wfcdemo.pas`      — a standalone test program that runs the WFC loop and,
                       on CONNECT, hands the open serial handle to a callback.

## Design notes

- **No edits to core A38 required to BUILD.** The module compiles on its own.
- Config is a plain `modem.ini` (this module's own file), so nothing in
  MYSTIC.DAT / RecConfig changes — on-disk compatibility is untouched.
- Integration hook: on CONNECT, `mdm_wfc` calls a user-supplied callback with the
  serial handle + negotiated baud, which is where a future patch would launch a
  Mystic session bound to the serial line instead of a telnet socket.

## Status

Serial + modem + WFC compile on Linux (i386) with FPC 2.6.2.  Win32 uses the
same FPC `Serial` unit (standard in a full install; absent only from this build
container's partial RTL).  Live testing needs real modem hardware / a serial
loopback.

## Cross-platform / Darwin

The serial layer is built on Free Pascal's cross-platform Serial unit, so the
same source targets Windows, Linux and macOS.  Device names differ by platform:
Windows uses COM1/COM2..., Linux uses /dev/ttyS0 or /dev/ttyUSB0, and macOS uses
/dev/cu.* (e.g. /dev/cu.usbserial-XXXX for a USB serial adapter) - set this in
modem.ini.  As elsewhere in this fork, the Darwin build is maintained by code
review (the build container cannot link Darwin); it links on a real Mac.
