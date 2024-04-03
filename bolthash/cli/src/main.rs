use bolt_hash::custom_hash;
use std::env;

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    if args.is_empty() || args.contains(&"-h".to_string()) || args.contains(&"--help".to_string()) {
        print_help();
        return;
    }

    // Process a single argument without echoing it back
    if args.len() == 1 {
        let hash = custom_hash(&args[0].as_bytes());
        println!("{}", hash);
    } else {
        // Process multiple arguments, echoing each back with its hash
        for arg in args {
            let hash = custom_hash(&arg.as_bytes());
            println!("{} {}", hash, arg);
        }
    }
}

fn print_help() {
    let help_message = r#"
Usage: bolthash [OPTIONS] [INPUTS]
Hashes input strings using the custom_hash function and prints the hashes.

Options:
  -h, --help       Print this help message and exit.

If no INPUTS are provided, reads from standard input (stdin).

Examples:
  echo "hello" | bolthash
  bolthash "hello world"
  bolthash -h
"#;
    println!("{}", help_message);
}

