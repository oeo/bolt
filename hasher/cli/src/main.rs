use bolt_hash::custom_hash;
use std::env;
use std::io::{self, Read};
use atty::Stream;

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    if args.contains(&"-h".to_string()) || args.contains(&"--help".to_string()) || (args.is_empty() && atty::is(Stream::Stdin)) {
        print_help();
        return;
    }

    if args.is_empty() {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer).expect("Failed to read from stdin");
        let input = buffer.trim_end();
        let hash = custom_hash(input.as_bytes());
        println!("{}", hash);
    } else if args.len() == 1 {
        let hash = custom_hash(&args[0].as_bytes());
        println!("{}", hash);
    } else {
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

