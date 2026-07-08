#!/bin/sh
# Build the mystic_spell spell-check add-on.
# Usage: ./build-spell.sh [win32]
# Runtime-loads Hunspell (libhunspell*.so / hunspell*.dll); nothing is linked
# at compile time, so this builds with no Hunspell present.
FPC=${FPC:-ppc386}
mkdir -p out bin
find . -name '*.ppu' -delete 2>/dev/null
find . -name '*.o'   -delete 2>/dev/null
if [ "$1" = "win32" ]; then
  echo "Building mystic_spell for Win32..."
  $FPC -Twin32 -Mobjfpc -O2 -FUout -FEbin spelltest.pas
else
  echo "Building mystic_spell for Linux (i386)..."
  $FPC -Tlinux -Mobjfpc -O2 -FUout -FEbin spelltest.pas
fi
echo "Done.  Executable in bin/"
