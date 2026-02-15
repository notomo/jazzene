///|
test "MidiNumber validation" {
  inspect(MidiNumber::new(60), content="Some({value: 60})")
  inspect(MidiNumber::new(0), content="Some({value: 0})")
  inspect(MidiNumber::new(127), content="Some({value: 127})")
  inspect(MidiNumber::new(-1), content="None")
  inspect(MidiNumber::new(128), content="None")
}

///|
test "MidiNumber pitch_class" {
  // C4 (MIDI 60) -> pitch class 0
  inspect(MidiNumber::{ value: 60 }.pitch_class(), content="0")
  // C#4 (MIDI 61) -> pitch class 1
  inspect(MidiNumber::{ value: 61 }.pitch_class(), content="1")
  // C5 (MIDI 72) -> pitch class 0
  inspect(MidiNumber::{ value: 72 }.pitch_class(), content="0")
}

///|
test "MidiNumber accidental" {
  // White keys -> Natural
  inspect(MidiNumber::{ value: 60 }.accidental(), content="Natural") // C
  inspect(MidiNumber::{ value: 62 }.accidental(), content="Natural") // D
  // Black keys -> Sharp or Flat
  inspect(MidiNumber::{ value: 61 }.accidental(), content="Sharp") // C#
  inspect(MidiNumber::{ value: 63 }.accidental(), content="Flat") // Eb
  inspect(MidiNumber::{ value: 66 }.accidental(), content="Sharp") // F#
  inspect(MidiNumber::{ value: 68 }.accidental(), content="Flat") // Ab
  inspect(MidiNumber::{ value: 70 }.accidental(), content="Flat") // Bb
}

///|
test "MidiNumber transpose" {
  let c4 = MidiNumber::{ value: 60 }
  // Up 7 semitones: C4 -> G4
  assert_eq(c4.transpose(7), MidiNumber::{ value: 67 })
  // Down 3 semitones: C4 -> A3
  assert_eq(c4.transpose(-3), MidiNumber::{ value: 57 })
  // Clamp to upper bound
  assert_eq(MidiNumber::{ value: 125 }.transpose(10), MidiNumber::{ value: 125 })
  // Clamp to lower bound
  assert_eq(MidiNumber::{ value: 3 }.transpose(-10), MidiNumber::{ value: 3 })
}
