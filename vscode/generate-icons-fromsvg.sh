#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Base directory is the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

SRC_SVG="${SRC_SVG:-icons/icss-new.svg}"
OUT_DIR="${OUT_DIR:-icons/png}"

# Check if source SVG exists
if [ ! -f "$SRC_SVG" ]; then
    echo "Error: Source SVG file '$SRC_SVG' not found."
    exit 1
fi

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Sizes to generate
SIZES=(16 32 48 128 256 512)

echo "Generating icons from $SRC_SVG..."

# Check which tool is available
if command -v sips &> /dev/null; then
    echo "Using sips (macOS built-in)..."
    for SIZE in "${SIZES[@]}"; do
        OUT_PNG="$OUT_DIR/icon_${SIZE}.png"
        sips -s format png -z "$SIZE" "$SIZE" "$SRC_SVG" --out "$OUT_PNG" &> /dev/null
        echo "  Generated: $OUT_PNG (${SIZE}x${SIZE})"
    done
elif command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    for SIZE in "${SIZES[@]}"; do
        OUT_PNG="$OUT_DIR/icon_${SIZE}.png"
        rsvg-convert -w "$SIZE" -h "$SIZE" "$SRC_SVG" -o "$OUT_PNG"
        echo "  Generated: $OUT_PNG (${SIZE}x${SIZE})"
    done
elif command -v inkscape &> /dev/null; then
    echo "Using inkscape..."
    for SIZE in "${SIZES[@]}"; do
        OUT_PNG="$OUT_DIR/icon_${SIZE}.png"
        inkscape -w "$SIZE" -h "$SIZE" "$SRC_SVG" -o "$OUT_PNG"
        echo "  Generated: $OUT_PNG (${SIZE}x${SIZE})"
    done
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick convert..."
    for SIZE in "${SIZES[@]}"; do
        OUT_PNG="$OUT_DIR/icon_${SIZE}.png"
        convert -background none -size "${SIZE}x${SIZE}" "$SRC_SVG" "$OUT_PNG"
        echo "  Generated: $OUT_PNG (${SIZE}x${SIZE})"
    done
else
    echo "Error: No suitable SVG conversion tool found (sips, rsvg-convert, inkscape, or convert)."
    echo "Please install one of them to run this script."
    exit 1
fi

echo "Icon generation complete!"
