import { describe, it, expect } from 'vitest';
import { indentedCSS } from './index.js';

describe('vite-plugin-icss', () => {
  it('should have the correct name and enforce properties', () => {
    const plugin = indentedCSS();
    expect(plugin.name).toBe('vite-plugin-icss');
    expect(plugin.enforce).toBe('pre');
  });

  it('should ignore non-.icss files', () => {
    const plugin = indentedCSS();
    const result = plugin.transform('body { color: red; }', 'style.css');
    expect(result).toBeUndefined();
  });

  it('should transform .icss files', () => {
    const plugin = indentedCSS();
    const src = `
body
  color: red
  background: blue
`;
    const result = plugin.transform(src, 'style.icss');
    expect(result).toBeDefined();
    expect(result.code).toContain('color: red;');
    expect(result.code).toContain('background: blue;');
    expect(result.code).toContain("document.createElement('style')");
  });
});
