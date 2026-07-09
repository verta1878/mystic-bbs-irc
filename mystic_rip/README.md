# mystic_rip — optional RIPscrip graphics example for Mystic A38

An **optional, separate example module**: a working RIPscrip 1.x terminal
engine — the groundwork for RIP graphics support in the fork.  Like the other
add-ons (`mystic_sdl/`, `mystic_spell/`, `mystic_crypt/`), nothing in the core
depends on it, it uses **FPC RTL units only** (no `mdl/` units), and its one
external library (SDL2, for the viewer only) is **runtime-loaded** through
`../mystic_sdl/sdl_bind.pas` — never linked.

## What RIP is

RIPscrip (TeleGrafix, 1992) let a BBS send **vector graphics and clickable
mouse buttons** to a caller instead of plain ANSI text: `!|` command
sequences drawing lines, boxes, circles, fills and text on a 640x350 EGA
canvas, plus "hot regions" that transmit a string to the host when clicked.
This module interprets that protocol.

## Design (see docs/RIP-INTEGRATION.md for the full mapping)

- `rip_term.pas`    — **TTermRip**: the terminal class, deliberately shaped
                     exactly like the ANSI class `TTermAnsi`
                     (`mdl/m_term_ansi.pas`): `Create` / `Process` /
                     `ProcessBuf` / `SetReplyClient`.  Feed it the byte
                     stream; it interprets the RIPscrip level-1
                     drawing/menu subset (`c W = m X L R B C O o F @ T M
                     K e E`), CR-framed with `\` line continuation.
- `rip_canvas.pas`  — **TRipCanvas**: the graphics seam TTermRip draws to
                     (RIP is vector graphics, so it cannot render to the
                     text-cell `TOutput`).  Abstract class; backends
                     implement it.  Includes the EGA reference palette and
                     the hot-region record.
- `rip_surface.pas` — **TRipSurface**: a pure-software 640x350 raster
                     backend (Bresenham, midpoint ellipses, flood fill,
                     8x8 font) with a BMP export for headless testing.
- `rip_window.pas`  — **TRipWindow**: SDL2 presenter (streaming ARGB
                     texture, EGA aspect correction); maps clicks back to
                     RIP coordinates and fires the hot regions.
- `rip_sample.pas`  — the built-in sample screen the demos share.
- `rip_render.pas`  — headless demo: `.RIP` → BMP.  No SDL, no display.
- `rip_view.pas`    — GUI demo: `.RIP` in a window; clicking a RIP button
                     prints the string it would send to the host.

The engine derives from the maintainer's clean-room **ripterm client** —
built once, used twice: the standalone client and this module share one
engine, and this module's renderer is pixel-identical to the client's.

## Try it

```
./build-rip.sh                   # or: ./build-rip.sh win32
bin/rip_render --sample out.bmp  # headless render of the sample screen
bin/rip_render screen.rip out.bmp
bin/rip_view --sample            # same screen in a window (needs SDL2)
```

## Promotion path (when RIP goes live in the core)

This module is the staging ground.  The design (docs/RIP-INTEGRATION.md)
maps the promotion: `rip_term.pas` becomes `mdl/m_term_rip.pas` beside
`m_term_ansi.pas`; the reply callback (`TRipReplyProc`) swaps to `TIOBase`
(the public shape already matches); the surface/presenter stay module-side.
Any threading in the live hook-up uses **FPC's own TThread/cthreads**, the
same way `mdl/m_socket_server.pas` already does — no custom thread layer.

## Cross-platform / Darwin

Pure Pascal throughout; the only platform edge is SDL2 loading in
`sdl_bind` (Windows / Linux / macOS names handled there).  As elsewhere in
this fork, the Darwin build is maintained by code review and links on a
real Mac.

## Status

Phase 1 (this module): parser + software raster + SDL viewer with working
clickable hot regions; verified on linux i386 + win32; renderer output
pixel-identical to the ripterm client reference.  Phase 2 (fills, fonts,
buttons, the live hook-up, the emitter) and Phase 3 (long tail) are
tracked in docs/TODO.md item 4.
