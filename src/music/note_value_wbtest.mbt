///|
test "NoteValue duration" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(Note(midi~, duration=Eighth).duration(bpm).to_milliseconds(), 250.0)
  assert_eq(
    Note(midi~, duration=Quarter).duration(bpm).to_milliseconds(),
    500.0,
  )
}

///|
test "NoteValue with_duration" {
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(
    Note(midi~, duration=Quarter).with_duration(Eighth),
    Note(midi~, duration=Eighth),
  )
  assert_eq(Rest(duration=Quarter).with_duration(Half), Rest(duration=Half))
}
