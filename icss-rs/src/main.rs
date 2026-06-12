use indented_css::Compiler;
use std::env;
use std::fs;
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: i-css <file.icss>");
        process::exit(1);
    }

    let input_path = &args[1];
    let input = fs::read_to_string(input_path).unwrap_or_else(|err| {
        eprintln!("Error reading file {}: {}", input_path, err);
        process::exit(1);
    });

    match Compiler::compile(&input) {
        Ok(css) => {
            println!("{}", css);
        }
        Err(err) => {
            eprintln!("Compilation error: {}", err);
            process::exit(1);
        }
    }
}
