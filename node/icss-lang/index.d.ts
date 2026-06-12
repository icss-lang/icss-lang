export * from './pkg/index.js';

export interface CompilerOptions {
  indent_type?: 'spaces' | 'tabs';
  indent_size?: number;
}

export function compile_icss(
  input: string,
  options?: CompilerOptions
): string;

export function compile_icss(
  input: string,
  indent_type?: 'spaces' | 'tabs',
  indent_size?: number
): string;
