#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Default values
VERSION_LEVEL="${VERSION_LEVEL:-patch}"
DEFAULT_PROJECTS="icss-rs node/icss-lang node/vite-plugin vscode"
PROJECTS="${PROJECTS:-$DEFAULT_PROJECTS}"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      # Ignore other arguments
      ;;
  esac
done

# Validate VERSION_LEVEL
if [[ "$VERSION_LEVEL" != "major" && "$VERSION_LEVEL" != "minor" && "$VERSION_LEVEL" != "patch" ]]; then
  echo "Error: Invalid VERSION_LEVEL '$VERSION_LEVEL'. Use 'major', 'minor', or 'patch'."
  exit 1
fi

# Helper function to increment version
increment_version() {
  local version=$1
  local level=$2
  
  IFS='.' read -r major minor patch <<< "$version"
  
  case "$level" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch|*)
      patch=$((patch + 1))
      ;;
  esac
  
  echo "${major}.${minor}.${patch}"
}

# Function to read Cargo.toml version
read_cargo_version() {
  local file=$1
  node -e 'const fs = require("fs"); const m = fs.readFileSync(process.argv[1], "utf8").match(/^version\s*=\s*"([^"]+)"/m); console.log(m ? m[1] : "");' "$file"
}

# Function to write Cargo.toml version
write_cargo_version() {
  local file=$1
  local new_ver=$2
  if [ "$DRY_RUN" = "true" ]; then
    return
  fi
  node -e '
    const fs = require("fs");
    const content = fs.readFileSync(process.argv[1], "utf8");
    const updated = content.replace(/^version\s*=\s*"[^"]+"/m, "version = \"" + process.argv[2] + "\"");
    fs.writeFileSync(process.argv[1], updated);
  ' "$file" "$new_ver"
}

# Function to read package.json version
read_npm_version() {
  local file=$1
  node -e 'const fs = require("fs"); const m = fs.readFileSync(process.argv[1], "utf8").match(/"version"\s*:\s*"([^"]+)"/); console.log(m ? m[1] : "");' "$file"
}

# Function to write package.json version
write_npm_version() {
  local file=$1
  local new_ver=$2
  if [ "$DRY_RUN" = "true" ]; then
    return
  fi
  node -e '
    const fs = require("fs");
    const content = fs.readFileSync(process.argv[1], "utf8");
    const updated = content.replace(/"version"\s*:\s*"[^"]+"/, "\"version\": \"" + process.argv[2] + "\"");
    fs.writeFileSync(process.argv[1], updated);
  ' "$file" "$new_ver"
}

# Helper to check if project is in the list of projects to bump
should_bump() {
  local proj=$1
  for p in $PROJECTS; do
    if [ "$p" = "$proj" ]; then
      return 0
    fi
  done
  return 1
}

# Change tracker for the summary
SUMMARY=""
add_summary() {
  SUMMARY="${SUMMARY}\n$1"
}

if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY RUN (No files will be modified) ==="
fi
echo "Version level: $VERSION_LEVEL"
echo "Projects to update: $PROJECTS"
echo "----------------------------------------"

# 1. Update icss-rs
if should_bump "icss-rs"; then
  CARGO_FILE="icss-rs/Cargo.toml"
  OLD_VER=$(read_cargo_version "$CARGO_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping icss-rs: $OLD_VER -> $NEW_VER"
  add_summary "  - icss-rs: $OLD_VER -> $NEW_VER"
  write_cargo_version "$CARGO_FILE" "$NEW_VER"
  
  # Update dependency in node/icss-lang/Cargo.toml
  WRAPPER_CARGO="node/icss-lang/Cargo.toml"
  if [ -f "$WRAPPER_CARGO" ]; then
    echo "  Updating dependency reference icss-lang -> $NEW_VER in $WRAPPER_CARGO"
    add_summary "    ↳ node/icss-lang dependency: icss-lang -> $NEW_VER"
    if [ "$DRY_RUN" != "true" ]; then
      node -e '
        const fs = require("fs");
        const content = fs.readFileSync(process.argv[1], "utf8");
        const updated = content.replace(/(icss-lang\s*=\s*\{\s*path\s*=\s*"[^"]+"\s*,\s*version\s*=\s*")[^"]+("\s*\})/, "$1" + process.argv[2] + "$2");
        fs.writeFileSync(process.argv[1], updated);
      ' "$WRAPPER_CARGO" "$NEW_VER"
    fi
  fi
fi

# 2. Update node/icss-lang
if should_bump "node/icss-lang"; then
  NPM_FILE="node/icss-lang/package.json"
  CARGO_FILE="node/icss-lang/Cargo.toml"
  
  # Update package.json version
  OLD_VER=$(read_npm_version "$NPM_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping node/icss-lang (npm): $OLD_VER -> $NEW_VER"
  add_summary "  - node/icss-lang (npm): $OLD_VER -> $NEW_VER"
  write_npm_version "$NPM_FILE" "$NEW_VER"
  
  # Also keep the wrapper Cargo.toml version in sync
  if [ -f "$CARGO_FILE" ]; then
    OLD_CARGO_VER=$(read_cargo_version "$CARGO_FILE")
    NEW_CARGO_VER=$(increment_version "$OLD_CARGO_VER" "$VERSION_LEVEL")
    echo "  Syncing Cargo.toml version for wrapper: $OLD_CARGO_VER -> $NEW_CARGO_VER"
    add_summary "    ↳ node/icss-lang wrapper (Cargo.toml): $OLD_CARGO_VER -> $NEW_CARGO_VER"
    write_cargo_version "$CARGO_FILE" "$NEW_CARGO_VER"
  fi
  
  # Update dependency in node/vite-plugin/package.json
  VITE_PKG="node/vite-plugin/package.json"
  if [ -f "$VITE_PKG" ]; then
    echo "  Updating dependency reference @icss-lang/node -> ^$NEW_VER in $VITE_PKG"
    add_summary "    ↳ node/vite-plugin dependency: @icss-lang/node -> ^$NEW_VER"
    if [ "$DRY_RUN" != "true" ]; then
      node -e '
        const fs = require("fs");
        const content = fs.readFileSync(process.argv[1], "utf8");
        const updated = content.replace(/"@icss-lang\/node"\s*:\s*"[^"]+"/, "\"@icss-lang/node\": \"^" + process.argv[2] + "\"");
        fs.writeFileSync(process.argv[1], updated);
      ' "$VITE_PKG" "$NEW_VER"
    fi
  fi
fi

# 3. Update node/vite-plugin
if should_bump "node/vite-plugin"; then
  NPM_FILE="node/vite-plugin/package.json"
  OLD_VER=$(read_npm_version "$NPM_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping node/vite-plugin: $OLD_VER -> $NEW_VER"
  add_summary "  - node/vite-plugin: $OLD_VER -> $NEW_VER"
  write_npm_version "$NPM_FILE" "$NEW_VER"
fi

# 4. Update vscode
if should_bump "vscode"; then
  NPM_FILE="vscode/package.json"
  OLD_VER=$(read_npm_version "$NPM_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping vscode: $OLD_VER -> $NEW_VER"
  add_summary "  - vscode: $OLD_VER -> $NEW_VER"
  write_npm_version "$NPM_FILE" "$NEW_VER"
fi

echo "----------------------------------------"
if [ "$DRY_RUN" = "true" ]; then
  echo -e "Dry run summary of changes:$SUMMARY"
  echo "----------------------------------------"
  echo "Dry run completed. No files were modified."
else
  echo -e "Summary of changes made:$SUMMARY"
  echo "----------------------------------------"
  echo "Version increase completed successfully!"
fi
