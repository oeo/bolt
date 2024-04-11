# bolthash-cli

this application uses the rust bolthash library to convert strings into hashes. 
`bolthash` follows the behavior of traditional unix programs.

## usage

`bolthash-cli` supports hashing via command line arguments or stdin. when no
arguments are provided, it expects input from stdin.

### examples

hashing a single string directly:

```
    bolthash "hello world"
```

hashing strings provided as arguments:

```
    bolthash string1 string2
```

hashing input from stdin:

```
    echo "hello world" | bolthash
```

displaying help information:

```
    bolthash -h
    bolthash --help
```

## installation

to use `bolthash`, ensure rust and cargo are installed. then:

1. clone the repo:

```
    git clone bolt
    cd bolt/bolthash/cli
    cargo build -r
```

1. the executable is now available under `./target/release/bolthash`.

## features

- **simple interface**: designed to be intuitive.
- **stdin support**: allows piping input directly.
- **argument hashing**: hashes each argument provided if multiple.

