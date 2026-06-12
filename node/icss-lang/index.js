import pkg from './pkg/index.js';

export function compile_icss(input, optionsOrIndentType, indentSize) {
  let indentType = undefined;
  let size = undefined;

  if (typeof optionsOrIndentType === 'object' && optionsOrIndentType !== null) {
    indentType = optionsOrIndentType.indent_type;
    size = optionsOrIndentType.indent_size;
  } else {
    indentType = optionsOrIndentType;
    size = indentSize;
  }

  return pkg.compile_icss_node(input, indentType, size);
}
