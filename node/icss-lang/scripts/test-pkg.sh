#!/usr/bin/env bash
set -e

# Navigate to the root of the icss-lang package (parent of scripts/)
cd "$(dirname "$0")/.."

echo "Testing package generation..."

# Create a temporary directory inside the workspace to avoid OS differences in mktemp
TEMP_DIR="./.tmp-pack-test"
mkdir -p "$TEMP_DIR"

# Ensure cleanup on exit
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Run npm pack into the temporary directory
echo "Running npm pack..."
npm pack --ignore-scripts --pack-destination "$TEMP_DIR"

# Locate the generated tarball
TARBALL=$(find "$TEMP_DIR" -name "*.tgz" | head -n 1)
if [ -z "$TARBALL" ]; then
    echo "Error: Failed to generate package tarball."
    exit 1
fi

echo "Package generated: $(basename "$TARBALL")"

# Define the files that must exist in the tarball
EXPECTED_FILES=(
  "package/package.json"
  "package/index.js"
  "package/index.d.ts"
  "package/pkg/package.json"
  "package/pkg/index.js"
  "package/pkg/index.d.ts"
  "package/pkg/index_bg.wasm"
  "package/pkg/index_bg.wasm.d.ts"
)

# Get the list of actual files in the tarball
echo "Verifying package contents..."
ACTUAL_FILES=$(tar -tf "$TARBALL")

MISSING_FILES=()
for file in "${EXPECTED_FILES[@]}"; do
    if ! echo "$ACTUAL_FILES" | grep -q "^$file$"; then
        MISSING_FILES+=("$file")
    fi
done

# Check if any files were missing
if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo "Error: The following expected files are missing from the package tarball:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

echo "Success: All expected files are present in the package tarball!"
