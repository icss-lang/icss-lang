use std::fmt::Write;
use wasm_bindgen::prelude::*;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IndentType {
    Spaces,
    Tabs,
}

#[wasm_bindgen]
pub fn compile_icss(
    input: &str,
    indent_type: Option<String>,
    indent_size: Option<usize>,
) -> Result<String, String> {
    let type_enum = match indent_type.as_deref() {
        Some("tabs") | Some("tab") => IndentType::Tabs,
        _ => IndentType::Spaces,
    };
    let size = indent_size.unwrap_or(2);
    Compiler::compile_with_options(input, type_enum, size)
}

#[derive(Debug, PartialEq, Clone)]
pub enum Node {
    /// A CSS property like `color: red`
    Property { name: String, value: String },
    /// A CSS selector like `.button` or `&:hover`
    Selector { name: String, children: Vec<Node> },
    /// An at-rule like `@media screen`
    AtRule { name: String, children: Vec<Node> },
}

/// A line parsed with its indentation level
#[derive(Debug)]
struct ParsedLine {
    indent_level: usize,
    content: String,
}

pub struct Compiler;

impl Compiler {
    /// Compiles an `.icss` string into standard CSS
    pub fn compile(input: &str) -> Result<String, String> {
        Self::compile_with_options(input, IndentType::Spaces, 2)
    }

    /// Compiles an `.icss` string into standard CSS with custom indentation
    pub fn compile_with_options(
        input: &str,
        indent_type: IndentType,
        indent_size: usize,
    ) -> Result<String, String> {
        let lines = Self::lex(input);
        let ast = Self::parse_ast(&lines)?;
        Ok(Self::render(&ast, indent_type, indent_size))
    }

    /// Step 1: Lex into lines with indentation levels
    fn lex(input: &str) -> Vec<ParsedLine> {
        let mut lines = Vec::new();
        for line in input.lines() {
            // Skip empty lines or pure whitespace lines
            if line.trim().is_empty() {
                continue;
            }
            
            let indent_level = line.chars().take_while(|c| c.is_whitespace()).count();
            let content = line.trim().to_string();
            
            lines.push(ParsedLine {
                indent_level,
                content,
            });
        }
        lines
    }

    /// Step 2: Build an AST based on indentation changes
    fn parse_ast(lines: &[ParsedLine]) -> Result<Vec<Node>, String> {
        let mut root = Vec::new();
        // A stack of (indent_level, node_being_built)
        // Since we need to modify nodes, we track indexes or use recursion.
        // Recursion is much easier. Let's use an iterator.
        let mut iter = lines.iter().peekable();
        
        while let Some(&line) = iter.peek() {
            if line.indent_level == 0 {
                if let Some(node) = Self::parse_node(&mut iter, 0) {
                    root.push(node);
                }
            } else {
                return Err(format!("Unexpected indentation at root level: '{}'", line.content));
            }
        }

        Ok(root)
    }

    fn parse_node<'a, I>(iter: &mut std::iter::Peekable<I>, current_indent: usize) -> Option<Node>
    where
        I: Iterator<Item = &'a ParsedLine>,
    {
        let line = iter.next()?;
        let content = &line.content;

        // Is it a property or a block?
        // A property typically contains a colon and doesn't start with '&' or '@' or '.'
        // A safer heuristic: check if the NEXT line is indented relative to THIS line.
        // If the next line is indented deeper, this line MUST be a Selector/AtRule.
        let mut is_block = false;
        if let Some(&next_line) = iter.peek() {
            if next_line.indent_level > current_indent {
                is_block = true;
            }
        }

        if is_block {
            let mut children = Vec::new();
            // Consume all children that have a higher indentation
            let child_indent = iter.peek().unwrap().indent_level;
            while let Some(&next_line) = iter.peek() {
                if next_line.indent_level >= child_indent {
                    // Only parse if it exactly matches the expected child indent,
                    // but we pass `child_indent` so nested blocks can handle their own
                    if next_line.indent_level == child_indent {
                        if let Some(child) = Self::parse_node(iter, child_indent) {
                            children.push(child);
                        }
                    } else {
                        // This shouldn't happen if properly formatted, but we can recurse anyway
                        if let Some(child) = Self::parse_node(iter, next_line.indent_level) {
                            children.push(child);
                        }
                    }
                } else {
                    break;
                }
            }

            if content.starts_with('@') {
                Some(Node::AtRule {
                    name: content.clone(),
                    children,
                })
            } else {
                Some(Node::Selector {
                    name: content.clone(),
                    children,
                })
            }
        } else {
            // Leaf node. Determine if it's a property or empty selector.
            // If it contains a ':' that isn't at the very beginning (like pseudo-selectors), treat as property
            if let Some(colon_idx) = content.find(':') {
                if colon_idx > 0 && !content.starts_with('&') && !content.starts_with('.') && !content.starts_with('#') {
                    let parts: Vec<&str> = content.splitn(2, ':').collect();
                    return Some(Node::Property {
                        name: parts[0].trim().to_string(),
                        value: parts[1].trim().to_string(),
                    });
                }
            }
            
            // Otherwise, it's an empty selector
            Some(Node::Selector {
                name: content.clone(),
                children: Vec::new(),
            })
        }
    }

    /// Step 3: Render AST to standard CSS
    fn render(nodes: &[Node], indent_type: IndentType, indent_size: usize) -> String {
        let mut output = String::new();
        let indent_char = match indent_type {
            IndentType::Spaces => " ",
            IndentType::Tabs => "\t",
        };
        let indent_str = indent_char.repeat(indent_size);
        Self::render_nodes(nodes, &mut output, 0, &indent_str);
        output
    }

    fn render_nodes(nodes: &[Node], output: &mut String, depth: usize, indent_str: &str) {
        let indent = indent_str.repeat(depth);
        
        for node in nodes {
            match node {
                Node::Property { name, value } => {
                    writeln!(output, "{}{}: {};", indent, name, value).unwrap();
                }
                Node::Selector { name, children } => {
                    writeln!(output, "{}{} {{", indent, name).unwrap();
                    Self::render_nodes(children, output, depth + 1, indent_str);
                    writeln!(output, "{}}}", indent).unwrap();
                }
                Node::AtRule { name, children } => {
                    writeln!(output, "{}{} {{", indent, name).unwrap();
                    Self::render_nodes(children, output, depth + 1, indent_str);
                    writeln!(output, "{}}}", indent).unwrap();
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_compilation() {
        let input = "
.button
  color: red
  background: blue

  &:hover
    color: white
        ";

        let result = Compiler::compile(input).unwrap();
        let expected = ".button {\n  color: red;\n  background: blue;\n  &:hover {\n    color: white;\n  }\n}\n";
        assert_eq!(result, expected);
    }
    
    #[test]
    fn test_at_rule() {
        let input = "
@media (max-width: 600px)
  .container
    padding: 10px
        ";
        let result = Compiler::compile(input).unwrap();
        let expected = "@media (max-width: 600px) {\n  .container {\n    padding: 10px;\n  }\n}\n";
        assert_eq!(result, expected);
    }

    #[test]
    fn test_custom_indentation() {
        let input = "
.button
  color: red
        ";
        // Default spaces:2
        let result_default = Compiler::compile(input).unwrap();
        assert_eq!(result_default, ".button {\n  color: red;\n}\n");

        // Spaces: 4
        let result_spaces_4 = Compiler::compile_with_options(input, IndentType::Spaces, 4).unwrap();
        assert_eq!(result_spaces_4, ".button {\n    color: red;\n}\n");

        // Tabs: 1
        let result_tabs_1 = Compiler::compile_with_options(input, IndentType::Tabs, 1).unwrap();
        assert_eq!(result_tabs_1, ".button {\n\tcolor: red;\n}\n");
    }
}
