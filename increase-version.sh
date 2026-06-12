#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Default values
VERSION_LEVEL="${VERSION_LEVEL:-patch}"
DEFAULT_PROJECTS="icss-rs node/icss-lang node/vite-plugin vscode"
PROJECTS="${PROJECTS:-$DEFAULT_PROJECTS}"

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

echo "Version level: $VERSION_LEVEL"
echo "Projects to update: $PROJECTS"
echo "----------------------------------------"

# 1. Update icss-rs
if should_bump "icss-rs"; then
  CARGO_FILE="icss-rs/Cargo.toml"
  OLD_VER=$(read_cargo_version "$CARGO_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping icss-rs: $OLD_VER -> $NEW_VER"
  write_cargo_version "$CARGO_FILE" "$NEW_VER"
  
  # Update dependency in node/icss-lang/Cargo.toml
  WRAPPER_CARGO="node/icss-lang/Cargo.toml"
  if [ -f "$WRAPPER_CARGO" ]; then
    echo "  Updating dependency reference icss-lang -> $NEW_VER in $WRAPPER_CARGO"
    node -e '
      const fs = require("fs");
      const content = fs.readFileSync(process.argv[1], "utf8");
      const updated = content.replace(/(icss-lang\s*=\s*\{\s*path\s*=\s*"[^"]+"\s*,\s*version\s*=\s*")[^"]+("\s*\})/, "$1" + process.argv[2] + "$2");
      fs.writeFileSync(process.argv[1], updated);
    ' "$WRAPPER_CARGO" "$NEW_VER"
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
  write_npm_version "$NPM_FILE" "$NEW_VER"
  
  # Also keep the wrapper Cargo.toml version in sync
  if [ -f "$CARGO_FILE" ]; then
    OLD_CARGO_VER=$(read_cargo_version "$CARGO_FILE")
    NEW_CARGO_VER=$(increment_version "$OLD_CARGO_VER" "$VERSION_LEVEL")
    echo "  Syncing Cargo.toml version for wrapper: $OLD_CARGO_VER -> $NEW_CARGO_VER"
    write_cargo_version "$CARGO_FILE" "$NEW_CARGO_VER"
  fi
  
  # Update dependency in node/vite-plugin/package.json
  VITE_PKG="node/vite-plugin/package.json"
  if [ -f "$VITE_PKG" ]; then
    echo "  Updating dependency reference @icss-lang/node -> ^$NEW_VER in $VITE_PKG"
    node -e '
      const fs = require("fs");
      const content = fs.readFileSync(process.argv[1], "utf8");
      const updated = content.replace(/"@icss-lang\/node"\s*:\s*"[^"]+"/, "\"@icss-lang/node\": \"^" + process.argv[2] + "\"");
      fs.writeFileSync(process.argv[1], updated);
    ' "$VITE_PKG" "$NEW_VER"
  fi
fi

# 3. Update node/vite-plugin
if should_bump "node/vite-plugin"; then
  NPM_FILE="node/vite-plugin/package.json"
  OLD_VER=$(read_npm_version "$NPM_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping node/vite-plugin: $OLD_VER -> $NEW_VER"
  write_npm_version "$NPM_FILE" "$NEW_VER"
fi

# 4. Update vscode
if should_bump "vscode"; then
  NPM_FILE="vscode/package.json"
  OLD_VER=$(read_npm_version "$NPM_FILE")
  NEW_VER=$(increment_version "$OLD_VER" "$VERSION_LEVEL")
  echo "Bumping vscode: $OLD_VER -> $NEW_VER"
  write_npm_version "$NPM_FILE" "$NEW_VER"
fi

echo "----------------------------------------"
echo "Version increase completed successfully!"
