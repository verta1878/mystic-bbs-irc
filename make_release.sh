#!/usr/bin/env bash
# ============================================================
#  Mystic 1.10 A38irc-A63 — Release package builder
#  Creates FULL (installer) and UPD (binary update) packages
# ============================================================
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"; cd "$ROOT"
DATE=$(date +%m-%d-%Y)
VER="1.10a38irc-a63"

echo "=================================================="
echo " Mystic BBS $VER Release Builder"
echo " $(date)"
echo "=================================================="
echo ""

INSTALL_DATA="${INSTALL_DATA:-/mnt/user-data/uploads/install_data.mys}"
if [ ! -f "$INSTALL_DATA" ]; then
    echo "ERROR: install_data.mys not found at $INSTALL_DATA"
    echo "Set INSTALL_DATA=/path/to/install_data.mys"
    exit 1
fi

# Clean
rm -rf out-linux out-win32 out-dos release
find . -name '*.ppu' -not -path "*/fpc264irc/*" -delete 2>/dev/null
find . -name '*.o' -not -path "*/fpc264irc/*" -delete 2>/dev/null

# Build all platforms
echo "--- Building Linux ---"
./build-linux.sh 2>&1 | tail -1
echo "--- Building Win32 ---"
./build-win32.sh 2>&1 | tail -1
echo "--- Building DOS ---"
./build-dos.sh 2>&1 | tail -1
echo ""

# Compile MPL scripts
echo "--- Compiling MPL scripts ---"
if [ -x out-linux/bin/mplc ]; then
    ./out-linux/bin/mplc scripts/appendtext_demo.mps 2>/dev/null && echo "  OK appendtext_demo.mpx" || echo "  FAIL"
    ./out-linux/bin/mplc scripts/chatcheck_demo.mps 2>/dev/null && echo "  OK chatcheck_demo.mpx" || echo "  FAIL"
fi
echo ""

mkdir -p release

# ============================================================
# FULL packages — 5 files only: install + install_data.mys
#   + COPYING + FILE_ID.DIZ + whatsnew.txt
# User runs install, it extracts everything from install_data.mys
# ============================================================

echo "--- Packaging Win32 FULL ---"
mkdir -p release/full-win32
cp out-win32/bin/install.exe release/full-win32/
cp "$INSTALL_DATA" release/full-win32/
cp COPYING release/full-win32/
cp mystic/file_id.win release/full-win32/FILE_ID.DIZ
cp mystic/whatsnew.txt release/full-win32/
cd release/full-win32
zip -9 "$ROOT/release/mystic-${VER}-win32-full-${DATE}.zip" * 2>&1 | tail -1
cd "$ROOT"

echo "--- Packaging Linux FULL ---"
mkdir -p release/full-linux
cp out-linux/bin/install release/full-linux/
cp "$INSTALL_DATA" release/full-linux/
cp COPYING release/full-linux/
cp mystic/file_id.lnx release/full-linux/FILE_ID.DIZ
cp mystic/whatsnew.txt release/full-linux/
cd release/full-linux
tar czf "$ROOT/release/mystic-${VER}-linux-full-${DATE}.tar.gz" *
cd "$ROOT"

echo "--- Packaging DOS FULL ---"
mkdir -p release/full-dos
cp out-dos/bin/install.exe release/full-dos/
cp "$INSTALL_DATA" release/full-dos/
cp COPYING release/full-dos/
cp mystic/file_id.dos release/full-dos/FILE_ID.DIZ
cp mystic/whatsnew.txt release/full-dos/
cd release/full-dos
zip -9 "$ROOT/release/mystic-${VER}-dos-full-${DATE}.zip" * 2>&1 | tail -1
cd "$ROOT"

# ============================================================
# UPD packages — all binaries + install_data.mys + COPYING
#   + FILE_ID.DIZ + whatsnew.txt + upgrade.txt
# Drop binaries into existing Mystic install
# ============================================================

echo "--- Packaging Win32 UPD ---"
mkdir -p release/upd-win32
cp out-win32/bin/*.exe release/upd-win32/
cp "$INSTALL_DATA" release/upd-win32/
cp COPYING release/upd-win32/
cp mystic/file_id.win release/upd-win32/FILE_ID.DIZ
cp mystic/whatsnew.txt release/upd-win32/
cp mystic/upgrade.txt release/upd-win32/
cd release/upd-win32
zip -9 "$ROOT/release/mystic-${VER}-win32-upd-${DATE}.zip" * 2>&1 | tail -1
cd "$ROOT"

echo "--- Packaging Linux UPD ---"
mkdir -p release/upd-linux
cp out-linux/bin/* release/upd-linux/
cp "$INSTALL_DATA" release/upd-linux/
cp COPYING release/upd-linux/
cp mystic/file_id.lnx release/upd-linux/FILE_ID.DIZ
cp mystic/whatsnew.txt release/upd-linux/
cp mystic/upgrade.txt release/upd-linux/
cd release/upd-linux
tar czf "$ROOT/release/mystic-${VER}-linux-upd-${DATE}.tar.gz" *
cd "$ROOT"

echo "--- Packaging DOS UPD ---"
mkdir -p release/upd-dos
cp out-dos/bin/* release/upd-dos/
cp "$INSTALL_DATA" release/upd-dos/
cp COPYING release/upd-dos/
cp mystic/file_id.dos release/upd-dos/FILE_ID.DIZ
cp mystic/whatsnew.txt release/upd-dos/
cp mystic/upgrade.txt release/upd-dos/
cd release/upd-dos
zip -9 "$ROOT/release/mystic-${VER}-dos-upd-${DATE}.zip" * 2>&1 | tail -1
cd "$ROOT"

echo ""
echo "=================================================="
echo " Release packages:"
ls -la release/mystic-${VER}-* 2>/dev/null | awk '{printf "  %-55s %6dKB\n", $NF, $5/1024}'
echo "=================================================="

# Copy to outputs
cp release/mystic-${VER}-*.zip release/mystic-${VER}-*.tar.gz /mnt/user-data/outputs/ 2>/dev/null

# Cleanup
rm -rf release out-linux out-win32 out-dos
