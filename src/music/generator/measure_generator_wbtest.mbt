///|
test "midi_to_required_state returns correct accidentals" {
  // C - natural (white key)
  assert_eq(midi_to_required_state(60), @music.Accidental::Natural)
  // C# - sharp (black key)
  assert_eq(midi_to_required_state(61), @music.Sharp)
  // D - natural (white key)
  assert_eq(midi_to_required_state(62), @music.Accidental::Natural)
  // Eb - flat (black key)
  assert_eq(midi_to_required_state(63), @music.Flat)
  // E - natural (white key)
  assert_eq(midi_to_required_state(64), @music.Accidental::Natural)
  // F - natural (white key)
  assert_eq(midi_to_required_state(65), @music.Accidental::Natural)
  // F# - sharp (black key)
  assert_eq(midi_to_required_state(66), @music.Sharp)
  // G - natural (white key)
  assert_eq(midi_to_required_state(67), @music.Accidental::Natural)
  // Ab - flat (black key)
  assert_eq(midi_to_required_state(68), @music.Flat)
  // A - natural (white key)
  assert_eq(midi_to_required_state(69), @music.Accidental::Natural)
  // Bb - flat (black key)
  assert_eq(midi_to_required_state(70), @music.Flat)
  // B - natural (white key)
  assert_eq(midi_to_required_state(71), @music.Accidental::Natural)
}

///|
test "calculate_accidental shows accidental only when pitch state changes" {
  let pitch_states : Map[Int, @music.Accidental] = {}

  // First C natural - should show nothing (default is natural)
  let c_acc = calculate_accidental(60, pitch_states)
  assert_eq(c_acc, None)

  // First C# - should show sharp (changes from natural to sharp)
  let cs_acc = calculate_accidental(61, pitch_states)
  assert_eq(cs_acc, Some(@music.Sharp))

  // Update pitch state
  pitch_states[1] = @music.Sharp

  // Second C# - should show nothing (already sharp)
  let cs_acc2 = calculate_accidental(61, pitch_states)
  assert_eq(cs_acc2, None)

  // C natural again - should show natural (changes from sharp back to natural)
  pitch_states[0] = @music.Sharp // Pretend we played C# in same octave before
  let c_acc2 = calculate_accidental(60, pitch_states)
  assert_eq(c_acc2, Some(@music.Accidental::Natural))
}
