# RIPscrip v2.0 Server-Side Rendering Engine

Extension of mystic_ripapi v1.0.0 (RIPscrip v1.54) with v2.0 features.

## v1.54 Base (Complete)

All 51 v1.54 commands, 4037 lines, standalone, zero dependencies.
See `../mystic_ripapi/` for the complete v1.54 engine.

## v2.0 Extensions (In Development)

New features decoded from RIPaint 2.1 (TeleGrafix, 1997) scene files.
No code taken — all information from file format observation.

### New Commands (15)
| Cmd | Params | Purpose |
|-----|--------|---------|
| `J` | 2 | Protocol version init |
| `n` | 4 | Set resolution |
| `M` | 2 | Color mode (256-color) |
| `f` | 4 | RFF font select |
| `k` | 2 | Pen width |
| `N` | 2 | Drawing layer |
| `K` | 8 | Clear bounded region |
| `D` | var | Define palette/gradient |
| `d` | 7 | Palette entry (cycling) |
| `y` | var | Extended polyline/path |
| `x` | var | Extended filled polygon |
| `j` | 4 | Jump to coordinates |
| `1b` | var | Extended button |
| `1i` | var | Extended icon load |
| `1p` | var | Extended put image |

### New File Formats
- `.BMH` — BMP highlight icons (standard Windows BMP)
- `.PAL` — 256-color RGB palette (768 bytes + header)
- `.RFF` — Scalable vector fonts (design units, multi-style)
- `.JPG` — JPEG image loading
- `.WAV` — Audio playback

### Enhancements (from SVGACC reference, author permission)
- Configurable resolution (640x480, 800x600, 1024x768)
- 256-color palette with fade/dim/rotate
- Block resize and rotate
- 2D/3D point transformations
- Sprite system with collision detection
- Animation support

## License

GNU General Public License v3. Part of the Mystic BBS IRC Fork.
