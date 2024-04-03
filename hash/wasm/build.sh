#!/bin/bash
echo "building wasm package using wasm-pack"
wasm-pack build --release --target web
