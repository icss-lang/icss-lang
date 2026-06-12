# Indented CSS (Rust Engine)

This directory contains the core compiler for **Indented CSS** (`.icss`), written in Rust. The compiler converts indentation-based CSS syntax into standard, valid CSS.

## Features

- **Lexer & Parser**: Converts whitespace-significant syntax into an Abstract Syntax Tree (AST).
- **Renderer**: Transforms the AST into standard CSS.
- **WebAssembly Support**: Can be compiled to WebAssembly via `wasm-pack` to run natively in Node.js or the browser.

## Usage

To run the compiler via the CLI:
```bash
cargo run -- path/to/file.icss
```

To run the integration tests:
```bash
cargo test
```

## Structure
- `src/lib.rs`: The core compiler logic and WASM bindings (`compile_icss`).
- `src/main.rs`: The CLI wrapper.
- `tests/`: Integration tests and `.icss` sample files.
