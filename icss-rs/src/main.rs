use icss_lang::Compiler;
use std::env;
use std::fs;
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: i-css <file.icss> [--indent-type <spaces|tabs>] [--indent-size <number>]");
        process::exit(1);
    }

    let mut input_path = None;
    let mut indent_type = icss_lang::IndentType::Spaces;
    let mut indent_size = 2;

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--indent-type" => {
                if i + 1 < args.len() {
                    match args[i + 1].as_str() {
                        "tabs" | "tab" => indent_type = icss_lang::IndentType::Tabs,
                        "spaces" | "space" => indent_type = icss_lang::IndentType::Spaces,
                        other => {
                            eprintln!("Invalid indent type: {}. Use 'spaces' or 'tabs'.", other);
                            process::exit(1);
                        }
                    }
                    i += 2;
                } else {
                    eprintln!("Missing value for --indent-type");
                    process::exit(1);
                }
            }
            "--indent-size" => {
                if i + 1 < args.len() {
                    if let Ok(size) = args[i + 1].parse::<usize>() {
                        indent_size = size;
                    } else {
                        eprintln!("Invalid indent size: {}", args[i + 1]);
                        process::exit(1);
                    }
                    i += 2;
                } else {
                    eprintln!("Missing value for --indent-size");
                    process::exit(1);
                }
            }
            path => {
                if input_path.is_none() {
                    input_path = Some(path.to_string());
                } else {
                    eprintln!("Unexpected argument: {}", path);
                    process::exit(1);
                }
                i += 1;
            }
        }
    }

    let Some(input_path) = input_path else {
        eprintln!("Usage: i-css <file.icss> [--indent-type <spaces|tabs>] [--indent-size <number>]");
        process::exit(1);
    };

    let input = fs::read_to_string(&input_path).unwrap_or_else(|err| {
        eprintln!("Error reading file {}: {}", input_path, err);
        process::exit(1);
    });

    match Compiler::compile_with_options(&input, indent_type, indent_size) {
        Ok(css) => {
            print!("{}", css);
        }
        Err(err) => {
            eprintln!("Compilation error: {}", err);
            process::exit(1);
        }
    }
}
