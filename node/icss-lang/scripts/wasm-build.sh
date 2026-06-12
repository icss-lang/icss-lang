#!/usr/bin/env bash
set -e

# Navigate to the root of the icss-lang package (parent of scripts/)
cd "$(dirname "$0")/.."

echo "Building WebAssembly module..."

# Check if rustup is available to install the target natively
if command -v rustup &> /dev/null; then
    echo "Found rustup! Ensuring wasm32-unknown-unknown target is installed..."
    # Force the use of the rustup toolchain over Homebrew's rust by modifying PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    rustup target add wasm32-unknown-unknown
    
    if ! command -v wasm-pack &> /dev/null; then
        echo "wasm-pack not found. Installing wasm-pack..."
        cargo install wasm-pack
    fi

    echo "Running wasm-pack locally..."
    wasm-pack build --target nodejs --out-name index --out-dir pkg

# If no rustup, check if Docker is available to containerize the build
elif command -v docker &> /dev/null; then
    echo "rustup not found. Falling back to Docker for a system-independent build..."
    
    # We use a Rust image, install wasm-pack, and build it inside the container
    docker run --rm -v "$(pwd):/app" -w /app rust:latest bash -c "
        echo 'Installing wasm-pack inside container...'
        cargo install wasm-pack
        echo 'Building with wasm-pack...'
        wasm-pack build --target nodejs --out-name index --out-dir pkg
        # Fix permissions so the host user can access the generated files
        chown -R $(id -u):$(id -g) pkg
    "
else
    echo "Error: Neither 'rustup' nor 'docker' could be found."
    echo "To build this project, please either:"
    echo "1. Install rustup (https://rustup.rs) to manage Rust targets locally, OR"
    echo "2. Install Docker to build it in an isolated container."
    exit 1
fi

# Remove pkg/.gitignore so npm pack includes the pkg/ directory
rm -f pkg/.gitignore

echo "Build complete! The pkg/ directory is ready."
