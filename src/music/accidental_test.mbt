///|
test "create_accidental_calculator shows accidental on first occurrence" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // First C# should show Sharp
  inspect(calc(MidiNumber::new(61).unwrap()), content="Some(Sharp)")
  // First Eb should show Flat
  inspect(calc(MidiNumber::new(63).unwrap()), content="Some(Flat)")
}

///|
test "create_accidental_calculator no accidental on repeated pitch in same octave" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // First C# shows Sharp
  inspect(calc(MidiNumber::new(61).unwrap()), content="Some(Sharp)")
  // Same C# again - no accidental needed
  inspect(calc(MidiNumber::new(61).unwrap()), content="None")
}

///|
test "create_accidental_calculator accidental required in different octave" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // C#4 shows Sharp
  inspect(calc(MidiNumber::new(61).unwrap()), content="Some(Sharp)")
  // C#5 in different octave - accidental needed (accidentals don't cross octaves)
  inspect(calc(MidiNumber::new(73).unwrap()), content="Some(Sharp)")
}

///|
test "create_accidental_calculator white keys need no accidental" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // C (pitch class 0) is white key, default Natural
  inspect(calc(MidiNumber::new(60).unwrap()), content="None")
  // D (pitch class 2) is white key, default Natural
  inspect(calc(MidiNumber::new(62).unwrap()), content="None")
}

///|
test "create_accidental_calculator F major Bb no accidental" {
  let calc = create_accidental_calculator(KeySignature::from_root(F))
  // Bb (MIDI 70) is in key signature, should show no accidental
  inspect(calc(MidiNumber::new(70).unwrap()), content="None")
  // B natural (MIDI 71) needs Natural to cancel the key signature flat
  inspect(calc(MidiNumber::new(71).unwrap()), content="Some(Natural)")
}

///|
test "create_accidental_calculator G major F# no accidental" {
  let calc = create_accidental_calculator(KeySignature::from_root(G))
  // F# (MIDI 66) is in key signature, should show no accidental
  inspect(calc(MidiNumber::new(66).unwrap()), content="None")
  // F natural (MIDI 65) needs Natural to cancel the key signature sharp
  inspect(calc(MidiNumber::new(65).unwrap()), content="Some(Natural)")
}

///|
test "create_accidental_calculator key signature applies across octaves" {
  let calc = create_accidental_calculator(KeySignature::from_root(G))
  // F#4 (MIDI 66) - key signature, no accidental
  inspect(calc(MidiNumber::new(66).unwrap()), content="None")
  // F#5 (MIDI 78) - key signature applies in all octaves
  inspect(calc(MidiNumber::new(78).unwrap()), content="None")
}

///|
test "create_accidental_calculator cancellation does not cross octaves" {
  let calc = create_accidental_calculator(KeySignature::from_root(G))
  // F natural 4 (MIDI 65) cancels key signature F# in octave 4
  inspect(calc(MidiNumber::new(65).unwrap()), content="Some(Natural)")
  // F#5 (MIDI 78) - key signature still applies in octave 5 (unaffected by octave 4)
  inspect(calc(MidiNumber::new(78).unwrap()), content="None")
  // F#4 (MIDI 66) - needs Sharp to restore after the F natural in octave 4
  inspect(calc(MidiNumber::new(66).unwrap()), content="Some(Sharp)")
}
