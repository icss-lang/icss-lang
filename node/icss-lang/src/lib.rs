use wasm_bindgen::prelude::*;
use icss_lang::Compiler;

#[wasm_bindgen]
pub fn compile_icss_node(input: &str) -> Result<String, String> {
    Compiler::compile(input)
}
