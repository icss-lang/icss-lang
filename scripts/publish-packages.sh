#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to the repository root (parent of script/)
cd "$(dirname "$0")/.."

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Load local environment variables from .env.local file if it exists (extending/overriding .env)
if [ -f .env.local ]; then
  set -a
  source .env.local
  set +a
fi

# Ensure PROJECTS is defined and not empty
if [ -z "$PROJECTS" ]; then
  echo "Error: PROJECTS environment variable is empty or not defined."
  exit 1
fi
DRY_RUN=false
CONFIRM=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --confirm)
      CONFIRM=true
      ;;
    *)
      # Ignore other arguments
      ;;
  esac
done

# Ensure either --confirm or --dry-run is specified
if [ "$DRY_RUN" = "false" ] && [ "$CONFIRM" = "false" ]; then
  echo "Error: You must specify either --confirm (to execute live publishing) or --dry-run (to simulate)."
  exit 1
fi

# Ensure they are not used together
if [ "$DRY_RUN" = "true" ] && [ "$CONFIRM" = "true" ]; then
  echo "Error: --confirm and --dry-run are mutually exclusive. Choose only one."
  exit 1
fi

# Helper to check if project is in the list
should_publish() {
  local proj=$1
  for p in $PROJECTS; do
    if [ "$p" = "$proj" ]; then
      return 0
    fi
  done
  return 1
}

# Block separator utility for clean output
WAS_PRINTED=false
print_block_separator() {
  if [ "$WAS_PRINTED" = "true" ]; then
    echo ""
  fi
  WAS_PRINTED=true
}

# Retrieve package/crate names dynamically for clean logging
read_cargo_name() {
  local file=$1
  node -e 'const fs = require("fs"); const m = fs.readFileSync(process.argv[1], "utf8").match(/^name\s*=\s*"([^"]+)"/m); console.log(m ? m[1] : "");' "$file"
}

read_npm_name() {
  local file=$1
  node -e 'const fs = require("fs"); const m = fs.readFileSync(process.argv[1], "utf8").match(/"name"\s*:\s*"([^"]+)"/); console.log(m ? m[1] : "");' "$file"
}

NAME_ICSS_RS="icss-lang.rs"
NAME_NODE_ICSS_LANG=$(read_npm_name "node/icss-lang/package.json")
NAME_NODE_VITE_PLUGIN=$(read_npm_name "node/vite-plugin/package.json")
NAME_VSCODE="icss-lang.vsix"

# Helper to run npm publish --dry-run and ignore "already exists" errors
run_npm_publish_dry_run() {
  local dir=$1
  local name=$2
  echo "  [Dry Run] Running verification: npm publish --dry-run"
  
  local tmp_file="./.tmp-publish-dry-run"
  
  # Run the command and stream output in real-time
  set +e
  (cd "$dir" && npm publish --dry-run) 2>&1 | tee "$tmp_file"
  local exit_code=${PIPESTATUS[0]}
  set -e
  
  if [ $exit_code -ne 0 ]; then
    if grep -q "previously published versions" "$tmp_file"; then
      echo "  [Dry Run] Note: $name version already exists (expected/tolerated)."
      rm -f "$tmp_file"
    else
      echo "Error: npm publish --dry-run in $dir failed."
      rm -f "$tmp_file"
      exit $exit_code
    fi
  else
    rm -f "$tmp_file"
  fi
}

if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY RUN (Simulating publishing commands) ==="
fi
echo "Projects to publish: $PROJECTS"
echo "----------------------------------------"

# 1. Publish icss-rs
if should_publish "icss-rs"; then
  print_block_separator
  echo "Publishing $NAME_ICSS_RS..."
  if [ "$DRY_RUN" = "true" ]; then
    echo "  [Dry Run] Running verification: cargo publish --dry-run"
    (cd icss-rs && cargo publish --dry-run)
  else
    (cd icss-rs && cargo publish)
  fi
fi

# 2. Publish node/icss-lang
if should_publish "node/icss-lang"; then
  print_block_separator
  echo "Publishing $NAME_NODE_ICSS_LANG..."
  if [ "$DRY_RUN" = "true" ]; then
    run_npm_publish_dry_run "node/icss-lang" "$NAME_NODE_ICSS_LANG"
  else
    (cd node/icss-lang && npm publish)
  fi
fi

# 3. Publish node/vite-plugin
if should_publish "node/vite-plugin"; then
  print_block_separator
  echo "Publishing $NAME_NODE_VITE_PLUGIN..."
  if [ "$DRY_RUN" = "true" ]; then
    run_npm_publish_dry_run "node/vite-plugin" "$NAME_NODE_VITE_PLUGIN"
  else
    (cd node/vite-plugin && npm publish)
  fi
fi

# 4. Publish vscode
if should_publish "vscode"; then
  print_block_separator
  echo "Publishing $NAME_VSCODE..."
  if [ "$DRY_RUN" = "true" ]; then
    echo "  [Dry Run] Running verification: npx vsce package"
    (cd vscode && npx vsce package)
    echo "  [Dry Run] Would run: npx vsce publish"
    # Clean up generated vsix file during dry run
    rm -f vscode/*.vsix
  else
    (cd vscode && npx vsce publish)
  fi
fi

echo "----------------------------------------"
if [ "$DRY_RUN" = "true" ]; then
  echo "Dry run publishing checks completed successfully!"
else
  echo "All packages published successfully!"
fi
