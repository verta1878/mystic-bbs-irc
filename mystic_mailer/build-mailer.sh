#!/bin/sh
# Build the mystic_mailer sample FidoNet mailer front-end.
# Usage: ./build-mailer.sh [win32]
# Depends on ../mystic_modem (serial/modem layer) and ../mdl (Mystic units).
FPC=${FPC:-ppc386}
MODEM=../mystic_modem
MDL=../mdl
mkdir -p out bin
find . -name '*.ppu' -delete 2>/dev/null
find . -name '*.o'   -delete 2>/dev/null
if [ "$1" = "win32" ]; then
  echo "Building mystic_mailer for Win32..."
  $FPC -Twin32 -Mobjfpc -O2 -Fu"$MODEM" -Fu"$MDL" -Fi"$MDL" -FUout -FEbin mailer.pas
else
  echo "Building mystic_mailer for Linux (i386)..."
  $FPC -Tlinux -Mobjfpc -O2 -Fu"$MODEM" -Fu"$MDL" -Fi"$MDL" -FUout -FEbin mailer.pas
fi
echo "Done.  Executable in bin/"
