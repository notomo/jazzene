///|
/// Create a mock generator that returns a fixed sequence of note values
fn fixed_generator(values : Array[NoteValue]) -> NoteValueGenerator {
  let mut index = 0
  fn() {
    let value = values[index % values.length()]
    index = index + 1
    value
  }
}

///|
test "generate improvisation with fixed sequence" {
  let midi = MidiNumber::new(60).unwrap()
  let values = [
    NoteValue::Note(midi~, duration=Quarter),
    NoteValue::Note(midi~, duration=Quarter),
    NoteValue::Note(midi~, duration=Half),
  ]
  assert_eq(generate_improvisation(fixed_generator(values), 2), [
    NoteValue::Rest(duration=Whole),
    NoteValue::Note(midi~, duration=Quarter),
    NoteValue::Note(midi~, duration=Quarter),
    NoteValue::Note(midi~, duration=Half),
  ])
}

///|
test "trimming behavior when note exceeds remaining beats" {
  let midi = MidiNumber::new(60).unwrap()
  let values = [NoteValue::Note(midi~, duration=Whole)]
  assert_eq(generate_improvisation(fixed_generator(values), 2), [
    NoteValue::Rest(duration=Whole),
    NoteValue::Note(midi~, duration=Whole),
  ])
}
