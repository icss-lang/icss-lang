# Indented CSS Vite Plugin

This is a Vite plugin that automatically compiles **Indented CSS** (`.icss`) files into standard CSS during your Vite development and build processes.

## How it works

The plugin imports the WebAssembly build of the Rust engine (`icss-rs`) and registers a custom transform hook in Vite. Whenever you import an `.icss` or `.cssi` file in your application, this plugin intercepts the request, passes the raw indented CSS to the WebAssembly compiler, and returns the standard CSS to Vite.

## Setup

1. Ensure the Rust engine is compiled to WebAssembly:
   ```bash
   cd ../icss-rs
   wasm-pack build --target nodejs
   ```
2. Include the plugin in your `vite.config.js` or `vite.config.ts`:
   ```javascript
   import { icss } from '@icss-lang/vite-plugin';

   export default {
     plugins: [
       icss()
     ]
   }
   ```

## TypeScript Setup

If you are using TypeScript and importing `.icss` or `.cssi` files directly in your code, TypeScript may complain about missing module declarations.

To fix this, you can reference the types provided by this plugin. Add the following to your `vite-env.d.ts` or `app.d.ts`:

```typescript
/// <reference types="@icss-lang/icss-lang" />
```

Alternatively, you can manually declare the modules in your project's `d.ts` files:

```typescript
declare module '*.icss' {
  const content: string;
  export default content;
}

declare module '*.cssi' {
  const content: string;
  export default content;
}
```
