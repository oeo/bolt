use blake2::{Blake2b512, Digest};
use rand::{Rng, SeedableRng};
use rand::rngs::StdRng;

pub fn custom_hash(input: &[u8]) -> String {
    let seed: [u8; 32] = Blake2b512::digest(input)[..32].try_into().unwrap();
    let mut rng = StdRng::from_seed(seed);
    let memory_size = rng.gen_range(1024..2048);
    let mut memory = vec![0u8; memory_size];
    for i in 0..memory.len() {
        memory[i] = rng.gen();
    }

    let mut hash_result = Blake2b512::digest(input);
    for _ in 0..1000 {
        hash_result = Blake2b512::digest(&hash_result);
    }

    for i in 0..memory.len() {
        let hash_step = Blake2b512::digest(&[memory[i], hash_result[(i % hash_result.len()) as usize]]);
        memory[i] = hash_step[(i % hash_step.len()) as usize];
    }

    let final_hash = Blake2b512::digest(&memory);

    // convert to a hexadecimal string, return
    final_hash.iter().map(|byte| format!("{:02x}", byte)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_custom_hash() {
        let input = b"hello world";
        let hash_value = custom_hash(input);
        println!("Hash for 'hello world': {}", hash_value);

        let input2 = b"hello rust";
        let hash_value2 = custom_hash(input2);
        println!("Hash for 'hello rust': {}", hash_value2);

        assert_ne!(hash_value, hash_value2, "Hashes should not match");
    }
}

