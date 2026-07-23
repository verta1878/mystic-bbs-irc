#!/usr/bin/env bash
# Build the patched go32v2 binutils (ld/nm/objdump/ar/ranlib/as) that reads
# FPC 2.6.2's COFF output.  See README.md for the why.
#
#   ./build-dos-binutils.sh /path/to/binutils-2.30.tar.gz [install-prefix]
#
# Produces i386-go32v2-{ld,nm,objdump,ar,ranlib,strip,as} under <prefix>/bin.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
# Default to the pristine tarball bundled next to this script; allow override.
TARBALL="${1:-$HERE/binutils-2.30.tar.gz}"
PREFIX="${2:-$PWD/dos-binutils-out}"
[ -f "$TARBALL" ] || { echo "no tarball: $TARBALL (pass one, or keep binutils-2.30.tar.gz beside this script)"; exit 1; }

command -v bison >/dev/null || { echo "install bison (apt-get install -y bison flex)"; exit 1; }
command -v flex  >/dev/null || { echo "install flex  (apt-get install -y bison flex)"; exit 1; }

WORK="$(mktemp -d)"; cd "$WORK"
tar xf "$TARBALL"
cd binutils-2.30
patch -p0 < "$HERE/coff-go32.c.patch"
patch -p0 < "$HERE/coffcode.h.patch"

mkdir build && cd build
../configure --target=i586-pc-msdosdjgpp --prefix="$PREFIX" \
  --disable-nls --disable-werror --enable-targets=i586-pc-msdosdjgpp
make all-ld all-binutils all-gas MAKEINFO=true -j"$(nproc)"

mkdir -p "$PREFIX/bin"
cp ld/ld-new          "$PREFIX/bin/i386-go32v2-ld"
cp binutils/nm-new    "$PREFIX/bin/i386-go32v2-nm"
cp binutils/objdump   "$PREFIX/bin/i386-go32v2-objdump"
cp binutils/ar        "$PREFIX/bin/i386-go32v2-ar"
cp binutils/ranlib    "$PREFIX/bin/i386-go32v2-ranlib"
cp binutils/strip-new "$PREFIX/bin/i386-go32v2-strip"
cp gas/as-new         "$PREFIX/bin/i386-go32v2-as"
echo "Done -> $PREFIX/bin/i386-go32v2-*"
