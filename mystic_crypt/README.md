# mystic_crypt — optional cryptlib (SSH/TLS) example for Mystic A38

An **optional, separate** example showing how the fork could add **SSH and TLS**
using **cryptlib** (Peter Gutmann's crypto toolkit) — the same library stock
Mystic 1.12 uses via `cl32.dll`.  Kept **separate from the main A38 source**;
nothing in the core or the other add-ons depends on it.

SSH/TLS is a **1.12 feature** that postdates this fork's A38/A39 base — our core
is telnet/plaintext only.  This module is the groundwork for bringing secure
sessions forward, as an add-on, in the same runtime-loaded style as the modem,
mailer, spell and SDL modules.

## What cl32.dll is

`cl32.dll` (Windows) / `libcl.so` (Linux) / cryptlib generally is Peter
Gutmann's security toolkit.  Mystic uses it for its SSH server, TLS on the
telnet/mail servers, and AES-256 encrypted netmail.  If cryptlib is not present,
stock Mystic prints "Cryptlib not detected; SSL/SSH capabilities disabled" and
runs plaintext — this module mirrors that graceful-off behaviour.

## Units

- `cl_bind.pas`  — a minimal cryptlib binding, RUNTIME-loaded (cl32.dll /
                   libcl.so / libcl.dylib), so this builds with no cryptlib
                   present and reports "unavailable" if missing.  Binds the
                   session entry points (cryptInit, cryptCreateSession,
                   cryptSetAttribute[String], cryptPushData/cryptPopData,
                   cryptDestroySession, cryptEnd) — the names taken from the
                   stock Mystic binary so a real cl32.dll is a drop-in.
- `cl_session.pas` — TCryptSession: a thin wrapper to stand up an SSH or TLS
                   server/client session over an existing socket handle, then
                   push/pop encrypted data.  This is the seam a future MIS SSH
                   server (a 7th server type beside telnet) would use.
- `cl_demo.pas`  — checks for cryptlib, prints its version/capabilities, and
                   shows the session-setup calls (no live network in the demo).

## Integration seam (NOT done — this is an example)

A real SSH server would be a new MIS client type (like mis_client_telnet) that
wraps the accepted socket in a cryptlib SSH session and then talks to the BBS
through the usual TIOBase stream.  TLS on SMTP/POP3 is the same idea on those
servers.  Config fields (SSH port, host-key/cert paths) would be added.  This
module provides the binding + session wrapper those would build on.

## cl32.dll naming

`cl32.dll` is cryptlib's own canonical name; renaming it is discouraged because
programs load it by that name and it has its own dependencies.  This module
looks for the standard names so the same DLL from a Mystic install drops in.

## Status

Binding + session wrapper compile (win32, linux i386, linux x86_64) with no
external dependency.  Live SSH/TLS needs a real cryptlib (`cl32.dll` / `libcl`)
and is a sysop-side test.
