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
  let a4 = MidiNumber::{ value: 69 }
  assert_eq(a4.to_frequency(), 440.0)
}
