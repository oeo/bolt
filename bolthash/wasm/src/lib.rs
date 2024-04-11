use wasm_bindgen::prelude::*;
use bolt_hash::custom_hash;

#[wasm_bindgen]
pub fn encode(input: &str) -> String {
  let input_bytes = input.as_bytes();
  let hash_result = custom_hash(input_bytes);
  format!("{}", hash_result)
}

