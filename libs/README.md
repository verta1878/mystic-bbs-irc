# libs/ — optional runtime libraries for the add-on modules

These are the external shared libraries the optional add-on modules load at
run time.  They are **separately-licensed works, aggregated alongside** this
GPL-licensed source (not combined into it); each keeps its own license, placed
here for sysop convenience so the libraries don't have to be hunted down.

Drop the file(s) for your platform into your Mystic root (or a system library
path) and the matching module will find them.  If a library is absent, its
module simply stays disabled — nothing else is affected.

| Library  | Module         | Files (per platform)                              | License        |
|----------|----------------|---------------------------------------------------|----------------|
| Hunspell | mystic_spell   | libhunspell32.dll / libhunspell64.dll / .so / .dylib | GPL/LGPL/MPL |
| SDL2     | mystic_sdl     | SDL2.dll / libSDL2-2.0.so.0 / libSDL2.dylib       | zlib           |
| cryptlib | mystic_crypt   | cl32.dll / libcl.so / libcl.dylib                 | Sleepycat (GPL-compatible) |

See the matching license file in this folder for each:
  HUNSPELL-LICENSE.txt, SDL2-LICENSE.txt, CRYPTLIB-LICENSE.txt

Spell checking also needs a dictionary (dictionary.aff + dictionary.dic) in the
DATA directory; see mystic_spell/README.md.

These libraries are NOT covered by this project's GPL; each is used under its
own license above.  Their inclusion here is "mere aggregation" in the GPL sense.
