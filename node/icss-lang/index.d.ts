export * from './pkg/index.js';

export interface icssCompilerOptions {
  indent_type?: 'spaces' | 'tabs';
  indent_size?: number;
}

export function compile_icss(
  input: string,
  options?: icssCompilerOptions
): string;

export function compile_icss(
  input: string,
  indent_type?: 'spaces' | 'tabs',
  indent_size?: number
): string;

declare module '*.icss' {
  const content: string;
  export default content;
}

declare module '*.cssi' {
  const content: string;
  export default content;
}

/**
 * Tagged template literal that compiles Indented CSS to regular CSS.
 *
 * At build time the Vite plugin replaces all usages with pre-compiled
 * string literals (zero runtime cost). Outside of Vite this calls
 * compile_icss at runtime.
 *
 * @example
 * import { icss } from 'icss-lang';
 * const css = icss`
 *   body
 *     color: red
 * `;
 */
export declare function icss(
  strings: TemplateStringsArray,
  ...values: unknown[]
): string;

/** Alias for {@link icss}. */
export declare const cssi: typeof icss;
