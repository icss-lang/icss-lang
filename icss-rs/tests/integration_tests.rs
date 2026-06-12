use std::fs;
use std::path::PathBuf;
use indented_css::Compiler;

fn compile_sample(filename: &str) {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("tests");
    path.push("samples");
    path.push(filename);

    let input = fs::read_to_string(&path)
        .unwrap_or_else(|err| panic!("Failed to read sample {}: {}", filename, err));

    match Compiler::compile(&input) {
        Ok(css) => {
            // Ensure compilation succeeded and produced a non-empty string (unless the input was empty)
            assert!(!css.is_empty(), "Compiled CSS should not be empty for {}", filename);
            println!("Successfully compiled {}:\n{}", filename, css);
        }
        Err(err) => {
            panic!("Failed to compile sample {}: {}", filename, err);
        }
    }
}

#[test]
fn test_basic_nesting() {
    compile_sample("basic_nesting.icss");
}

#[test]
fn test_forms_and_states() {
    compile_sample("forms_and_states.icss");
}

#[test]
fn test_media_queries() {
    compile_sample("media_queries.icss");
}
