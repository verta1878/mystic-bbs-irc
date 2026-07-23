# Deferred Items Test Suite

Tests for the 9 deferred items from A45–A52 that were completed in a
single focused effort.

## Usage

```bash
FPC=/path/to/ppc386 ./tests/deferred9/run.sh
```

## What's tested

| Test | Item | Alpha | Spec Reference |
|------|------|-------|----------------|
| 1 | Console DELETE/BACKSPACE detection | A45 | VT100/ANSI X3.64 |
| 2 | BINKP timeout reset during transfer | A48 | FTS-1026.001 §6 |
| 3 | FTP QWK display option | A49 | RFC 959 |
| 4 | CTRL+U lastread update in area index | A51 | — (BBS internal) |
| 5 | Socket shutdown flush | A51 | RFC 793 §3.5 |
| 6 | MIS crash fix — critical sections | A51 | POSIX mutex semantics |
| 7 | Auto-ban IP flood protection | A51 | cf. RFC 5321 §4.5.3.2 |
| 8 | TIC/FDN file tosser | A46 | FTS-5006.001, FSC-0087.001 |
| 9 | FileToss unsecure_dir | A52 | FTS-5006.001 + FTS-1026.001 |
| Bonus | BINKP FTS-1026 compliance | A52 | FTS-1026.001 Table R4 |

## Test methodology

Tests verify:
- **Code presence**: required fields, functions, and handlers exist
- **Spec compliance**: FTS/FSC/RFC keyword coverage and protocol behavior
- **Compilation**: mutil_filetoss.pas compiles clean with r3.1
- **Safety**: critical section patterns, disable checks, error handling
- **Integration**: wiring into mutil.pas, mis.pas, -cfg screens

## FTS/FSC/RFC references

- **FTS-1026.001** — Binkp/1.0 Protocol Specification
- **FTS-5006.001** — TIC File Format (was FSP-1039)
- **FSC-0087.001** — File Forwarding in FidoNet Technology Networks
- **RFC 793** — TCP (connection close semantics)
- **RFC 959** — FTP (LIST/NLST responses)
- **RFC 5321** — SMTP (connection rate limiting pattern)
