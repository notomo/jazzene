///|
/// Convert an integer seed to a 32-byte seed for ChaCha8 RNG
/// The seed is distributed across the 32 bytes using little-endian encoding
fn seed_to_bytes(seed : Int) -> Bytes {
  let seed_uint = seed.reinterpret_as_uint()
  Bytes::makei(32, fn(i) {
    let value = seed_uint + (i / 4).reinterpret_as_uint()
    (value >> (i % 4 * 8)).to_byte()
  })
}

///|
/// Create a random integer generator from seed
/// Returns a closure that generates random integers in range [0, n)
pub fn create_random_int(seed : Int) -> (Int) -> Int {
  let rand = @random.Rand::chacha8(seed=seed_to_bytes(seed))
  fn(n) { rand.int(limit=n) }
}
