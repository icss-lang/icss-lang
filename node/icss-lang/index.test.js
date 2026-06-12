import { describe, it, expect } from 'vitest';
import { compile_icss } from './index.js';

describe('icss-lang', () => {
  it('should compile basic properties and blocks', () => {
    const input = `
.button
  color: red
  background: blue

  &:hover
    color: white
`;
    const expected = `.button {
  color: red;
  background: blue;
  &:hover {
    color: white;
  }
}
`;
    expect(compile_icss(input)).toBe(expected);
  });

  it('should compile at-rules', () => {
    const input = `
@media (max-width: 600px)
  .container
    padding: 10px
`;
    const expected = `@media (max-width: 600px) {
  .container {
    padding: 10px;
  }
}
`;
    expect(compile_icss(input)).toBe(expected);
  });

  it('should ignore empty lines and handle indentation', () => {
    const input = `
body

  margin: 0
  padding: 0
`;
    const expected = `body {
  margin: 0;
  padding: 0;
}
`;
    expect(compile_icss(input)).toBe(expected);
  });

  it('should support custom indent type and size using options object', () => {
    const input = `
.button
  color: red
`;
    // Spaces: 4
    const expectedSpaces4 = `.button {
    color: red;
}
`;
    expect(compile_icss(input, { indent_type: 'spaces', indent_size: 4 })).toBe(expectedSpaces4);

    // Tabs: 1
    const expectedTabs1 = `.button {
\tcolor: red;
}
`;
    expect(compile_icss(input, { indent_type: 'tabs', indent_size: 1 })).toBe(expectedTabs1);
  });

  it('should support custom indent type and size using separate arguments', () => {
    const input = `
.button
  color: red
`;
    const expectedTabs2 = `.button {
\t\tcolor: red;
}
`;
    expect(compile_icss(input, 'tabs', 2)).toBe(expectedTabs2);
  });
});
