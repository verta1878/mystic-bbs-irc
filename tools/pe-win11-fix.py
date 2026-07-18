#!/usr/bin/env python3
"""
pe-win11-fix.py — Patch FPC-built PE32 executables for Windows 11 compatibility

FPC 2.6.4 generates PE32 with:
  DllCharacteristics = 0x0000  (no DEP/NX flag — Win11 enforces DEP)
  MajorSubsystemVersion = 4    (targets NT 4.0 — Win11 may reject)
  MajorOperatingSystemVersion = 4

This script patches:
  DllCharacteristics -> 0x0100 (NX_COMPAT / DEP compatible)
  SubsystemVersion   -> 6.0   (minimum Vista, recognized by Win11)
  OSVersion          -> 6.0

Usage:
  python3 tools/pe-win11-fix.py mystic.exe mide.exe *.exe
  python3 tools/pe-win11-fix.py out-win32/bin/*.exe
"""

import struct
import sys
import os

def patch_pe(filename):
    with open(filename, 'r+b') as f:
        # Read DOS header — PE offset at 0x3C
        f.seek(0x3C)
        pe_offset = struct.unpack('<I', f.read(4))[0]

        # Verify PE signature
        f.seek(pe_offset)
        sig = f.read(4)
        if sig != b'PE\x00\x00':
            print(f'  SKIP  {filename} — not a PE file')
            return False

        # COFF header is at pe_offset + 4
        # Optional header is at pe_offset + 4 + 20
        opt_offset = pe_offset + 4 + 20

        # Verify PE32 magic (0x10B)
        f.seek(opt_offset)
        magic = struct.unpack('<H', f.read(2))[0]
        if magic != 0x10B:
            print(f'  SKIP  {filename} — not PE32 (magic=0x{magic:04X})')
            return False

        # MajorOperatingSystemVersion at opt_offset + 40
        f.seek(opt_offset + 40)
        os_major = struct.unpack('<H', f.read(2))[0]
        os_minor = struct.unpack('<H', f.read(2))[0]

        # MajorSubsystemVersion at opt_offset + 48
        f.seek(opt_offset + 48)
        sub_major = struct.unpack('<H', f.read(2))[0]
        sub_minor = struct.unpack('<H', f.read(2))[0]

        # DllCharacteristics at opt_offset + 70
        f.seek(opt_offset + 70)
        dll_chars = struct.unpack('<H', f.read(2))[0]

        changes = []

        # Patch MajorOperatingSystemVersion -> 6.0
        if os_major < 6:
            f.seek(opt_offset + 40)
            f.write(struct.pack('<HH', 6, 0))
            changes.append(f'OSVer {os_major}.{os_minor}->6.0')

        # Patch MajorSubsystemVersion -> 6.0
        if sub_major < 6:
            f.seek(opt_offset + 48)
            f.write(struct.pack('<HH', 6, 0))
            changes.append(f'SubVer {sub_major}.{sub_minor}->6.0')

        # Patch DllCharacteristics — set NX_COMPAT (0x0100)
        if not (dll_chars & 0x0100):
            new_chars = dll_chars | 0x0100
            f.seek(opt_offset + 70)
            f.write(struct.pack('<H', new_chars))
            changes.append(f'DllChar 0x{dll_chars:04X}->0x{new_chars:04X}')

        if changes:
            print(f'  PATCH {filename} — {", ".join(changes)}')
        else:
            print(f'  OK    {filename} — already patched')

        return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: pe-win11-fix.py <exe files...>')
        print('Example: pe-win11-fix.py out-win32/bin/*.exe')
        sys.exit(1)

    patched = 0
    for arg in sys.argv[1:]:
        if os.path.isfile(arg):
            if patch_pe(arg):
                patched += 1

    print(f'\nPatched {patched} file(s)')
