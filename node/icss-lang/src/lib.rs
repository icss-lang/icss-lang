use wasm_bindgen::prelude::*;
use icss_lang::{Compiler, IndentType};

#[wasm_bindgen]
pub fn compile_icss_node(
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
