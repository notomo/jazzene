///|
test "weighted_tone_candidates returns empty when weight_ratio is 0" {
  let prev = @music.MidiNumber::new(60).unwrap()
  let tones = [
    @music.MidiNumber::new(62).unwrap(),
    @music.MidiNumber::new(64).unwrap(),
  ]
  let result = weighted_tone_candidates(tones, prev, 50, 7, 0)
  assert_eq(result.length(), 0)
}

///|
test "weighted_tone_candidates returns candidates with weight_ratio 100" {
  let prev = @music.MidiNumber::new(60).unwrap()
  let tones = [
    @music.MidiNumber::new(62).unwrap(),
    @music.MidiNumber::new(64).unwrap(),
  ]
  let result = weighted_tone_candidates(tones, prev, 50, 7, 100)
  assert_eq(result.length(), 2)
  // All weights should be positive
  for pair in result {
    assert_true(pair.0 > 0)
  }
}

///|
test "weighted_tone_candidates scales weights by weight_ratio" {
  let prev = @music.MidiNumber::new(60).unwrap()
  let tones = [@music.MidiNumber::new(62).unwrap()]
  let full = weighted_tone_candidates(tones, prev, 50, 7, 100)
  let half = weighted_tone_candidates(tones, prev, 50, 7, 50)
  // Half ratio should produce lower or equal weight (both clamped to min 1)
  assert_true(half[0].0 <= full[0].0)
}

///|
test "weighted_tone_candidates filters by max_interval" {
  let prev = @music.MidiNumber::new(60).unwrap()
  // Tone at distance 12 (octave) with max_interval=7
  let tones = [@music.MidiNumber::new(72).unwrap()]
  let result = weighted_tone_candidates(tones, prev, 50, 7, 100)
  // filter_by_interval returns closest tone as fallback even if beyond max_interval
  assert_eq(result.length(), 1)
}

///|
test "weighted_tone_candidates includes correct MIDI numbers" {
  let prev = @music.MidiNumber::new(60).unwrap()
  let c = @music.MidiNumber::new(62).unwrap()
  let e = @music.MidiNumber::new(64).unwrap()
  let result = weighted_tone_candidates([c, e], prev, 50, 7, 100)
  assert_eq(result[0].1, c)
  assert_eq(result[1].1, e)
}
