///|
test "MidiNumber validation" {
  debug_inspect(@music.MidiNumber::new(60), content="Some({ value: 60 })")
  debug_inspect(@music.MidiNumber::new(0), content="Some({ value: 0 })")
  debug_inspect(@music.MidiNumber::new(127), content="Some({ value: 127 })")
  debug_inspect(@music.MidiNumber::new(-1), content="None")
  debug_inspect(@music.MidiNumber::new(128), content="None")
}

///|
test "MidiNumber pitch_class" {
  // C4 (MIDI 60) -> pitch class 0
  inspect(@music.MidiNumber::new(60).unwrap().pitch_class(), content="0")
  // C#4 (MIDI 61) -> pitch class 1
  inspect(@music.MidiNumber::new(61).unwrap().pitch_class(), content="1")
  // C5 (MIDI 72) -> pitch class 0
  inspect(@music.MidiNumber::new(72).unwrap().pitch_class(), content="0")
}

///|
test "MidiNumber accidental" {
  // White keys -> Natural
  inspect(@music.MidiNumber::new(60).unwrap().accidental(), content="Natural") // C
  inspect(@music.MidiNumber::new(62).unwrap().accidental(), content="Natural") // D
  // Black keys -> Sharp or Flat
  inspect(@music.MidiNumber::new(61).unwrap().accidental(), content="Sharp") // C#
  inspect(@music.MidiNumber::new(63).unwrap().accidental(), content="Flat") // Eb
  inspect(@music.MidiNumber::new(66).unwrap().accidental(), content="Sharp") // F#
  inspect(@music.MidiNumber::new(68).unwrap().accidental(), content="Flat") // Ab
  inspect(@music.MidiNumber::new(70).unwrap().accidental(), content="Flat") // Bb
}

///|
test "MidiNumber transpose" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  // Up 7 semitones: C4 -> G4
  assert_eq(c4.transpose(7), @music.MidiNumber::new(67).unwrap())
  // Down 3 semitones: C4 -> A3
  assert_eq(c4.transpose(-3), @music.MidiNumber::new(57).unwrap())
  // Clamp to upper bound
  assert_eq(
    @music.MidiNumber::new(125).unwrap().transpose(10),
    @music.MidiNumber::new(125).unwrap(),
  )
  // Clamp to lower bound
  assert_eq(
    @music.MidiNumber::new(3).unwrap().transpose(-10),
    @music.MidiNumber::new(3).unwrap(),
  )
}
