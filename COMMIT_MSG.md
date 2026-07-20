# Summary (paste into GitHub Desktop "Summary" field):
RIPscrip v1.54 engine v1.0.0 — all 8 phases, 51/51 commands, 4041 lines

# Description (paste into GitHub Desktop "Description" field):
Standalone RIPscrip v1.54 server-side rendering engine (mystic_ripapi/).
Version 1.0.0 — Released July 19, 2026.
Compiles with just `ppc386 -Mdelphi ripscript.pas` — zero dependencies.

## Engine (ripscript.pas — 4041 lines)
- 51/51 RIPscrip v1.54 commands (36 Level 0 + 15 Level 1)
- 640x350 EGA 16-color rendering with full palette
- Drawing: pixel, line, rect, bar, circle, oval, arc, pie, bezier, polygon, flood fill
- CHR vector fonts: all 10 Borland BGI .CHR files
- 5 system font modes: 80x43, 80x25, 40x25, 91x43, 91x25
- Icon formats: ICN, MSK, HIC (BGI GetImage with transparency)
- Image loading: PCX (16-color EGA RLE), BMP (4-bit + 24-bit)
- Buttons: 3D beveled, radio groups, checkboxes, hotkeys, tab navigation
- Screen save/restore: 10 slots + text window + mouse fields + clipboard
- 43 text variables with $VARNAME$ expansion
- Variable persistence: SaveVars/LoadVars (NAME=VALUE format)
- SaveScene: serialize screen to .RIP file
- BMP export: 24-bit via EGA_RGB palette

## Viewer (examples/rip/)
- RIP_Parser.pas (628 lines) — event-driven parser
- RIP_Viewer.pas (497 lines) — 37 event handlers
- ripview.pas — demo: load .RIP → render → save BMP

## Assets (examples/ripterm154/)
- 212 ICN, 4 MSK, 3 HIC, 10 CHR fonts (cgorringe/RIPterm154 freeware)

## Bug Found
- FPC 2.6.4irc AnsiString stack overflow in -Mdelphi mode
- Fixed with {$H-} + ExpandVars rewrite
- Report: docs/bugs/fpc264irc-ansistring-stack-overflow.md
