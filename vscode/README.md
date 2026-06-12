# Indented CSS VS Code Extension

This is a Visual Studio Code extension that provides language support and syntax highlighting for **Indented CSS** files (`.icss` and `.cssi`).

## Features

- **Syntax Highlighting**: Provides robust colorization for selectors, properties, pseudo-classes, and media queries in the indentation-based CSS format.
- **File Association**: Automatically associates `.icss` and `.cssi` file extensions with the Indented CSS language mode.

## Development

To test the extension:
1. Open this folder in VS Code.
2. Press `F5` to launch a new Extension Development Host window.
3. Open an `.icss` file in the new window to see the syntax highlighting in action.

## Packaging

To package the extension into a `.vsix` file for distribution or manual installation:
```bash
npx vsce package
```

## Usage

```icss
body
  color: red
```

```css
body {
  color: red;
}
```