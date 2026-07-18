#!/usr/bin/env bash
# ============================================================
#  make_install_data.sh — builds install_data.mys from a
#  Mystic BBS directory tree using install_make
#
#  Usage: ./make_install_data.sh /path/to/mystic
#
#  The Mystic directory must contain these subdirectories:
#    data/    — binary data files (.dat, .cfg, etc)
#    text/    — ANSI/ASCII screens (.ans, .asc)
#    menus/   — menu definitions (.mnu)
#    scripts/ — MPL scripts (.mps, .mpx)
#    docs/    — documentation files
#    (root)   — top-level files (mystic.dat, etc)
#
#  Produces: install_data.mys in the current directory
#
#  Requires: install_make binary (compiled from install_make.pas)
# ============================================================
set -eu

MYSTIC_DIR="${1:-}"
INSTALL_MAKE="${INSTALL_MAKE:-./install_make}"

if [ -z "$MYSTIC_DIR" ]; then
    echo "make_install_data.sh — builds install_data.mys from a Mystic directory"
    echo ""
    echo "Usage: $0 /path/to/mystic [install_make_path]"
    echo ""
    echo "The Mystic directory must contain: data/ text/ menus/ scripts/ docs/"
    echo ""
    echo "Example:"
    echo "  $0 /home/sysop/mystic"
    echo "  $0 /home/sysop/mystic /path/to/install_make"
    echo ""
    echo "Produces: install_data.mys in the current directory"
    exit 1
fi

if [ ! -x "$INSTALL_MAKE" ]; then
    # Try common locations
    for try in ./install_make ./out-linux/bin/install_make "$MYSTIC_DIR/install_make"; do
        if [ -x "$try" ]; then
            INSTALL_MAKE="$try"
            break
        fi
    done
fi

if [ ! -x "$INSTALL_MAKE" ]; then
    echo "ERROR: install_make not found or not executable"
    echo "Set INSTALL_MAKE=/path/to/install_make or put it in current directory"
    exit 1
fi

echo "=================================================="
echo " Building install_data.mys"
echo " Source: $MYSTIC_DIR"
echo " Tool:   $INSTALL_MAKE"
echo "=================================================="
echo ""

# Remove old archive if it exists
rm -f install_data.mys

# Verify required directories exist
MISSING=0
for dir in data text menus scripts docs; do
    if [ ! -d "$MYSTIC_DIR/$dir" ]; then
        echo "WARNING: $MYSTIC_DIR/$dir/ not found"
        MISSING=$((MISSING+1))
    fi
done

if [ "$MISSING" -gt 3 ]; then
    echo "ERROR: Too many missing directories. Is $MYSTIC_DIR a Mystic install?"
    exit 1
fi

# Section 1: DOCS — documentation
echo "--- Adding DOCS ---"
if [ -d "$MYSTIC_DIR/docs" ]; then
    "$INSTALL_MAKE" install_data "$MYSTIC_DIR/docs/*" DOCS
fi

# Section 2: DATA — binary data files
echo "--- Adding DATA ---"
if [ -d "$MYSTIC_DIR/data" ]; then
    "$INSTALL_MAKE" install_data "$MYSTIC_DIR/data/*" DATA
fi

# Section 3: TEXT — ANSI/ASCII display files
echo "--- Adding TEXT ---"
if [ -d "$MYSTIC_DIR/text" ]; then
    "$INSTALL_MAKE" install_data "$MYSTIC_DIR/text/*" TEXT
fi

# Section 4: MENUS — menu definitions
echo "--- Adding MENUS ---"
if [ -d "$MYSTIC_DIR/menus" ]; then
    "$INSTALL_MAKE" install_data "$MYSTIC_DIR/menus/*" MENUS
fi

# Section 5: SCRIPT — MPL scripts
echo "--- Adding SCRIPT ---"
if [ -d "$MYSTIC_DIR/scripts" ]; then
    "$INSTALL_MAKE" install_data "$MYSTIC_DIR/scripts/*" SCRIPT
fi

# Section 6: ROOT — top-level files
echo "--- Adding ROOT ---"
# Root files are specific — only include known BBS files, not binaries
for f in "$MYSTIC_DIR"/*.dat "$MYSTIC_DIR"/*.cfg "$MYSTIC_DIR"/*.ini \
         "$MYSTIC_DIR"/*.txt "$MYSTIC_DIR"/*.asc "$MYSTIC_DIR"/*.ans; do
    if [ -f "$f" ]; then
        "$INSTALL_MAKE" install_data "$f" ROOT
    fi
done

echo ""
if [ -f install_data.mys ]; then
    SIZE=$(stat -c%s install_data.mys 2>/dev/null || stat -f%z install_data.mys 2>/dev/null)
    echo "=================================================="
    echo " SUCCESS: install_data.mys created ($((SIZE/1024)) KB)"
    echo "=================================================="
else
    echo "ERROR: install_data.mys was not created"
    exit 1
fi
