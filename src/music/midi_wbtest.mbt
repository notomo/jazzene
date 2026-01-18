///|
test "MidiNumber validation" {
  inspect(MidiNumber::new(60), content="Some({value: 60})")
  inspect(MidiNumber::new(0), content="Some({value: 0})")
  inspect(MidiNumber::new(127), content="Some({value: 127})")
  inspect(MidiNumber::new(-1), content="None")
  inspect(MidiNumber::new(128), content="None")
}

///|
test "MidiNumber to_frequency conversion" {
  // MIDI 69 = A4 = 440 Hz (reference pitch)
  let a4 = MidiNumber::{ value: 69 }
  assert_eq(a4.to_frequency(), 440.0)

  // MIDI 60 = C4 (middle C) ≈ 261.63 Hz
  let c4 = MidiNumber::{ value: 60 }
  let c4_freq = c4.to_frequency()
  assert_true(c4_freq > 261.6 && c4_freq < 261.7)

  // MIDI 48 = C3 ≈ 130.81 Hz (one octave below C4)
  let c3 = MidiNumber::{ value: 48 }
  let c3_freq = c3.to_frequency()
  assert_true(c3_freq > 130.8 && c3_freq < 130.9)

  // Verify octave relationship: C4 should be exactly twice the frequency of C3
  assert_true(c4_freq / c3_freq > 1.99 && c4_freq / c3_freq < 2.01)
}
