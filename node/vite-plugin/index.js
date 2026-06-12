import { compile_icss } from '@icss-lang/node';

export function indentedCSS() {
  return {
    name: 'vite-plugin-icss',
    enforce: 'pre',
    transform(src, id) {
      if (id.endsWith('.icss')) {
        try {
          const css = compile_icss(src);
          // Return a JS module that dynamically injects the compiled CSS
          const code = `
            if (typeof document !== 'undefined') {
              const style = document.createElement('style');
              style.innerHTML = ${JSON.stringify(css)};
              document.head.appendChild(style);
            }
          `;
          return {
            code,
            map: null
          };
        } catch (e) {
          this.error(`Failed to compile indented css file: ${e}`);
        }
      }
    }
  };
}
