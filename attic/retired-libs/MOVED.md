# Retired Libraries

Moved from libs/ on July 22, 2026.

These platform libraries are NOT needed for:
- RIPscrip engines (v1-v4) — zero dependencies
- Example code (examples/rip, examples/rip2)
- Any Pascal source compilation

They ARE needed for:
- Full Mystic BBS with SDL2 screen rendering (mdl/sdl.pas)
- CryptLib SSH/TLS (mystic_crypt/ — runtime loaded, compiles without)
- Hunspell spell check (mystic_spell/ — runtime loaded, compiles without)
- DOS cross-compile (dos-binutils-patch/)
- OS/2 cross-compile (emxbind-src/)
- Darwin cross-compile (ld64-linux-x86_64/)

Will be deleted after verifying full cross-compile works without them.
