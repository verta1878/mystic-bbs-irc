# RIPscrip v2.0 Server-Side Rendering Engine — Implementation Phases

Based on mystic_ripapi v1.0.0 (RIPscrip v1.54, all 8 phases complete).
New features decoded from RIPaint 2.1 scene files — no code taken.

## Inherited from v1.54 (COMPLETE)

All 51 v1.54 commands, 4037 lines, 175/175 items done.

## Phase 9: Protocol and Color Extensions — PENDING

- [ ] Bare pipe `|` command prefix (in addition to `!|`)
- [ ] Extended MegaNum (3-4 digit values for coords > 1295)
- [ ] 256-color palette (extend Palette[0..15] to [0..255])
- [ ] Extended color values in commands (0G..9R = colors 16-255)
- [ ] Configurable canvas resolution (640x480, 800x600, 1024x768)
- [ ] Pixel buffer as dynamic allocation (not fixed 640x350)
- [ ] |J nn — protocol version init
- [ ] |n nnnn — set resolution
- [ ] |M nn — set color mode

## Phase 10: New Drawing Commands — PENDING

- [ ] |K nnnnnnnn — clear/kill bounded region (x0 y0 x1 y1)
- [ ] |k nn — pen width / line thickness
- [ ] |N nn — drawing context / layer select
- [ ] |j nnnn — jump to coordinates
- [ ] |y nn... — extended polyline/path (variable length)
- [ ] |x nn... — extended filled polygon (variable length)
- [ ] |t nn... — text on path
- [ ] |D nn... — define palette/gradient (variable length)
- [ ] |d nnnnnnn — define palette entry (palette cycling)

## Phase 11: New File Formats — PENDING

- [ ] .BMH loading (BMP highlight icons — standard BMP, already works)
- [ ] .PAL loading (16-byte EGA or 868-byte 256-color RGB)
- [ ] .JPG loading (JPEG image support)
- [ ] .RFF loading (RIPscrip scalable vector fonts)
- [ ] .WAV reference (audio playback — server-side stub)
- [ ] |f nnnn — font select (RFF font by ID)
- [ ] |1i — extended icon load (JPEG/BMP)
- [ ] |1b — extended button
- [ ] |1p — extended put image

## Phase 12: SVGACC-Inspired Enhancements — PENDING

Based on Zypher Software SVGACC v2.6 API (source rights from author).
Backported to Pascal — no SVGACC code used, API as design reference.

- [ ] Block resize (scale raster block to new dimensions)
- [ ] Block rotate (rotate raster block by angle)
- [ ] 2D transforms: rotate, scale, translate point arrays
- [ ] 3D transforms: rotate, scale, translate, project (3D→2D)
- [ ] 256-color palette fade/dim/rotate (palchgstep, paldimstep)
- [ ] Sprite system (transparency color, background save)
- [ ] Sprite collision detection
- [ ] 4-direction region scrolling (up/down/left/right)
- [ ] Antialiased line drawing

## Phase 13: Animation and Multimedia — PENDING

- [ ] Frame-based BMP animation (EARTH_01..EARTH_30 sequences)
- [ ] Palette cycling (CYC*.RIP fade transitions)
- [ ] FADEIN/FADEOUT transitions
- [ ] WAV audio playback hooks
- [ ] Animation timer/frame rate control

## Phase 14: Documentation — PENDING

- [ ] Update ripscript.doc/txt/htm for all v2.0 commands
- [ ] Document RFF font format
- [ ] Document PAL file format (16-byte and 868-byte)
- [ ] Document BMH format (= standard BMP)
- [ ] Document new command parameters
- [ ] Update VERSION, README, features.txt

## Summary

v1.54 base: 175 done, 0 todo (inherited)
v2.0 additions: 0 done, 53 todo (Phases 9-14)
Total: 175 done, 53 todo
