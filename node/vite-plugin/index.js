import { compile_icss } from '@icss-lang/node';

// Matches: icss`...` or cssi`...` (including multi-line, non-greedy)
// Group 1: the raw template content (no expressions supported)
const ICSS_TAG_RE = /\b(?:icss|cssi)`((?:[^`\\]|\\.)*)`/gs;

export function icss() {
  return {
    name: 'vite-plugin-icss',
    enforce: 'pre',
    transform(src, id) {
      // --- Vue / Svelte style block mode ---
      const isVueOrSvelteStyle = (id.includes('?vue') || id.includes('?svelte')) && 
                                 id.includes('type=style') && 
                                 (id.includes('lang.icss') || id.includes('lang.cssi'));
      
      // --- File mode: .icss / .cssi imports ---
      const isIcssFile = id.endsWith('.icss') || id.endsWith('.cssi');

      if (isVueOrSvelteStyle || isIcssFile) {
        try {
          const css = compile_icss(src);
          
          if (isVueOrSvelteStyle) {
            // Vue and Svelte compilers expect raw CSS from the style block
            return { code: css, map: null };
          }

          // Return a JS module that dynamically injects the compiled CSS
          const code = `
            if (typeof document !== 'undefined') {
              const style = document.createElement('style');
              style.innerHTML = ${JSON.stringify(css)};
              document.head.appendChild(style);
            }
          `;
          return { code, map: null };
        } catch (e) {
          this.error(`Failed to compile indented css file: ${e}`);
        }
      }

      // --- Tagged template mode: icss`...` inside JS/TS ---
      if (/\.[cm]?[jt]sx?$/.test(id) && ICSS_TAG_RE.test(src)) {
        ICSS_TAG_RE.lastIndex = 0;
        let transformed = false;
        const code = src.replace(ICSS_TAG_RE, (_match, raw) => {
          // Unescape template literal escape sequences
          const input = raw.replace(/\\`/g, '`').replace(/\\\\/g, '\\');
          try {
            const css = compile_icss(input);
            transformed = true;
            return JSON.stringify(css);
          } catch (e) {
            this.error(`Failed to compile icss template literal: ${e}`);
          }
        });
        if (transformed) {
          return { code, map: null };
        }
      }
    }
  };
}
