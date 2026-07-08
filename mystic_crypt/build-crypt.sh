#!/bin/sh
# Build the mystic_crypt cryptlib (SSH/TLS) example.
# Usage: ./build-crypt.sh [win32]
# Runtime-loads cryptlib (cl32.dll / libcl.so / libcl.dylib); nothing is linked
# at compile time, so this builds with no cryptlib present.
FPC=${FPC:-ppc386}
mkdir -p out bin
find . -name '*.ppu' -delete 2>/dev/null
find . -name '*.o'   -delete 2>/dev/null
if [ "$1" = "win32" ]; then
  echo "Building mystic_crypt for Win32..."
  $FPC -Twin32 -Mobjfpc -O2 -FUout -FEbin cl_demo.pas
else
  echo "Building mystic_crypt for Linux..."
  $FPC -Tlinux -Mobjfpc -O2 -FUout -FEbin cl_demo.pas
fi
echo "Done.  Executable in bin/  (needs cl32.dll / libcl at runtime for real use)"
