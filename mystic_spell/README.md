# mystic_spell — optional spell-check add-on for Mystic A38

A **self-contained, optional** module that adds on-the-fly spell checking and
word suggestions, using the **Hunspell** engine — the same approach Mystic 1.12
uses.  Kept **separate from the main A38 source** so it drops in without
touching the core; wiring it into the full-screen message editor is a
documented integration seam (the live highlight-as-you-type part is core work).

Spell checking is a **1.12 feature** that postdates this fork's A38/A39 base.
This module brings the capability forward as an add-on.

## How it works

- Uses **Hunspell** via a runtime-loaded shared library (libhunspell on Linux,
  hunspell*.dll on Windows).  Nothing is linked at compile time, so the module
  builds with no Hunspell present and reports "unavailable" gracefully if the
  library or dictionaries are missing — exactly how a sysop deployment works
  (drop the library + dictionaries in place, like 1.12).
- Reads standard ISPELL/HUNSPELL `dictionary.aff` + `dictionary.dic` from the
  data directory (any language), plus an optional `WORDLIST.TXT` of BBS-specific
  terms/acronyms that a normal dictionary would not contain.

## Units

- `spl_hunspell.pas` — a thin Pascal binding that loads libhunspell at runtime
  (Hunspell_create/destroy/spell/suggest/free_list) and exposes them safely.
- `spl_engine.pas`   — TSpellEngine: open dictionaries + wordlist, Check(word),
  Suggest(word); handles the library being absent.
- `spelltest.pas`    — a standalone tester: checks words and prints suggestions.

## Integration seam

The live editor integration (highlighting misspelled words as the user types in
the full-screen message editor) is CORE work and is intentionally NOT done here
— it would hook the editor's keypress loop.  This module provides the engine the
editor would call: Check() and Suggest().

## Status

The binding + engine compile with no external dependency.  Verified against a
real Hunspell + US English dictionary (64-bit test).  The shipped module is
runtime-load so it runs on the fork's 32-bit target with a sysop-supplied
Hunspell library, mirroring the 1.12 deployment model.
