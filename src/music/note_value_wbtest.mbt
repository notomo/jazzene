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
