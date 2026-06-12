import { describe, it, expect } from 'vitest';
import { icss as icssPlugin } from './index.js';

describe('vite-plugin-icss', () => {
  it('should have the correct name and enforce properties', () => {
    const plugin = icssPlugin();
    expect(plugin.name).toBe('vite-plugin-icss');
    expect(plugin.enforce).toBe('pre');
  });

  it('should ignore non-indented CSS files', () => {
    const plugin = icssPlugin();
    const result = plugin.transform('body { color: red; }', 'style.css');
    expect(result).toBeUndefined();
  });

  it('should transform .cssi files', () => {
    const plugin = icssPlugin();
    const src = `
body
  color: red
  background: blue
`;
    // Mock the context so this.error works
    const context = { error: (msg) => { throw new Error(msg); } };
    const result = plugin.transform.call(context, src, 'style.cssi');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).toContain('background: blue;');
  });

  it('should transform .icss files', () => {
    const plugin = icssPlugin();
    const src = `
body
  color: red
  background: blue
`;
    const context = { error: (msg) => { throw new Error(msg); } };
    const result = plugin.transform.call(context, src, 'style.icss');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).toContain('background: blue;');
    expect(result.code).toContain("document.createElement('style')");
  });

  // --- Tagged template literal tests ---

  it('should transform icss tagged template literals in .js files', () => {
    const plugin = icssPlugin();
    const src = `
import { icss } from '@icss-lang/vite-plugin/client';
const css = icss\`
body
  color: red
  background: blue
\`;
`;
    const result = plugin.transform(src, 'component.js');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).toContain('background: blue;');
    // The tag call should be replaced with a plain string literal
    expect(result.code).not.toContain('icss`');
  });

  it('should transform icss tagged template literals in .ts files', () => {
    const plugin = icssPlugin();
    const src = `const css = icss\`body\n  color: red\n\`;`;
    const result = plugin.transform(src, 'component.ts');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).not.toContain('icss`');
  });

  it('should leave JS files without icss template literals untouched', () => {
    const plugin = icssPlugin();
    const src = `const x = 42;`;
    const result = plugin.transform(src, 'util.js');
    expect(result).toBeUndefined();
  });

  it('should handle multiple icss template literals in a single file', () => {
    const plugin = icssPlugin();
    const src = [
      `const a = icss\`body\n  color: red\n\`;`,
      `const b = icss\`h1\n  font-size: 2rem\n\`;`,
    ].join('\n');
    const result = plugin.transform(src, 'multi.js');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).toContain('font-size: 2rem;');
    expect(result.code).not.toContain('icss`');
  });

  it('should transform cssi tagged template literals', () => {
    const plugin = icssPlugin();
    const src = `const css = cssi\`body\n  color: blue\n\`;`;
    const result = plugin.transform(src, 'component.js');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: blue;');
    expect(result.code).not.toContain('cssi`');
  });
});
