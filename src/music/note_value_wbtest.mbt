///|
test "NoteValue duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(Note(midi~, duration=Eighth).duration(bpm).to_milliseconds(), 250.0)
  assert_eq(
    Note(midi~, duration=Quarter).duration(bpm).to_milliseconds(),
    500.0,
  )
  assert_eq(Note(midi~, duration=Half).duration(bpm).to_milliseconds(), 1000.0)
  assert_eq(Rest(duration=Quarter).duration(bpm).to_milliseconds(), 500.0)
}

///|
test "Dotted notes duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(
    Note(midi~, duration=DottedEighth).duration(bpm).to_milliseconds(),
    375.0,
  )
  assert_eq(
    Note(midi~, duration=DottedQuarter).duration(bpm).to_milliseconds(),
    750.0,
  )
  assert_eq(
    Note(midi~, duration=DottedHalf).duration(bpm).to_milliseconds(),
    1500.0,
  )
  assert_eq(Rest(duration=DottedQuarter).duration(bpm).to_milliseconds(), 750.0)
}
