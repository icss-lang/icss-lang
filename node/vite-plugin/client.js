/**
 * Runtime tagged template literal helper for ICSS.
 *
 * In a Vite project the plugin replaces all `icss\`...\`` usages with
 * pre-compiled CSS strings at build time, so this function is never
 * called in production bundles.
 *
 * Outside of Vite (SSR, unit tests, plain Node scripts) this falls back
 * to calling compile_icss at runtime.
 *
 * Usage:
 *   import { icss } from '@icss-lang/vite-plugin/client';
 *   const css = icss`
 *     body
 *       color: red
 *   `;
 */
import { compile_icss } from '@icss-lang/node';

/**
 * @param {TemplateStringsArray} strings
 * @param {...unknown} values
 * @returns {string} compiled CSS
 */
export function icss(strings, ...values) {
  // Reconstruct the raw template string (interpolations are stringified)
  const raw = strings.reduce((acc, str, i) => acc + str + (values[i] ?? ''), '');
  return compile_icss(raw);
}

/** Alias for {@link icss}. */
export const cssi = icss;
