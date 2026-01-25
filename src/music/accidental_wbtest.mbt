///|
test "create_accidental_calculator shows accidental on first occurrence" {
  let calc = create_accidental_calculator()
  // First C# should show Sharp
  inspect(calc(MidiNumber::{ value: 61 }), content="Some(Sharp)")
  // First Eb should show Flat
  inspect(calc(MidiNumber::{ value: 63 }), content="Some(Flat)")
}

///|
test "create_accidental_calculator no accidental on repeated pitch" {
  let calc = create_accidental_calculator()
  // First C# shows Sharp
  inspect(calc(MidiNumber::{ value: 61 }), content="Some(Sharp)")
  // Same C# again - no accidental needed
  inspect(calc(MidiNumber::{ value: 61 }), content="None")
  // C# in different octave - same pitch class, no accidental needed
  inspect(calc(MidiNumber::{ value: 73 }), content="None")
}

///|
test "create_accidental_calculator white keys need no accidental" {
  let calc = create_accidental_calculator()
  // C (pitch class 0) is white key, default Natural
  inspect(calc(MidiNumber::{ value: 60 }), content="None")
  // D (pitch class 2) is white key, default Natural
  inspect(calc(MidiNumber::{ value: 62 }), content="None")
}
