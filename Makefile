.PHONY: default icss-rs icss-rs.wasm icss-lang.vsix

default:
	@echo "Available options:"
	@echo "  make icss-rs             - Build the Rust CLI engine"
	@echo "  make icss-rs.wasm        - Build the WebAssembly version of the Rust engine for Node/Vite"
	@echo "  make icss-lang.vsix  - Package the VS Code extension"

icss-rs.test:
	cd icss-rs && cargo test

icss-rs:
	cd icss-rs && cargo build --release

icss-rs.wasm:
	cd icss-rs && wasm-pack build --target nodejs

icss-lang.vsix:
	cd vscode && npx vsce package

node/vite-plugin.test:
	cd node/vite-plugin && npm test

node/icss-lang.test:
	cd node/icss-lang && npm test

node/icss-lang.build:
	cd node/icss-lang && npm run build


vscode.icons:
	cd vscode && ./generate-icons-fromsvg.sh