.PHONY: default icss-rs icss-rs.wasm icss-language.vsix

default:
	@echo "Available options:"
	@echo "  make icss-rs             - Build the Rust CLI engine"
	@echo "  make icss-rs.wasm        - Build the WebAssembly version of the Rust engine for Node/Vite"
	@echo "  make icss-language.vsix  - Package the VS Code extension"

icss-rs.test:
	cd icss-rs && cargo test

icss-rs:
	cd icss-rs && cargo build --release

icss-rs.wasm:
	cd icss-rs && wasm-pack build --target nodejs

icss-language.vsix:
	cd vscode && npx vsce package

vite-plugin.test:
	cd node/vite-plugin && npm test

