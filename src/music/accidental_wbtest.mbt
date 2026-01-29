///|
test "create_accidental_calculator shows accidental on first occurrence" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // First C# should show Sharp
  inspect(calc(MidiNumber::{ value: 61 }), content="Some(Sharp)")
  // First Eb should show Flat
  inspect(calc(MidiNumber::{ value: 63 }), content="Some(Flat)")
}

///|
test "create_accidental_calculator no accidental on repeated pitch" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // First C# shows Sharp
  inspect(calc(MidiNumber::{ value: 61 }), content="Some(Sharp)")
  // Same C# again - no accidental needed
  inspect(calc(MidiNumber::{ value: 61 }), content="None")
  // C# in different octave - same pitch class, no accidental needed
  inspect(calc(MidiNumber::{ value: 73 }), content="None")
}

///|
test "create_accidental_calculator white keys need no accidental" {
  let calc = create_accidental_calculator(KeySignature::c_major())
  // C (pitch class 0) is white key, default Natural
  inspect(calc(MidiNumber::{ value: 60 }), content="None")
  // D (pitch class 2) is white key, default Natural
  inspect(calc(MidiNumber::{ value: 62 }), content="None")
}

///|
test "create_accidental_calculator F major Bb no accidental" {
  let calc = create_accidental_calculator(KeySignature::from_root(F))
  // Bb (MIDI 70) is in key signature, should show no accidental
  inspect(calc(MidiNumber::{ value: 70 }), content="None")
  // B natural (MIDI 71) needs Natural to cancel the key signature flat
  inspect(calc(MidiNumber::{ value: 71 }), content="Some(Natural)")
}

///|
test "create_accidental_calculator G major F# no accidental" {
  let calc = create_accidental_calculator(KeySignature::from_root(G))
  // F# (MIDI 66) is in key signature, should show no accidental
  inspect(calc(MidiNumber::{ value: 66 }), content="None")
  // F natural (MIDI 65) needs Natural to cancel the key signature sharp
  inspect(calc(MidiNumber::{ value: 65 }), content="Some(Natural)")
}
