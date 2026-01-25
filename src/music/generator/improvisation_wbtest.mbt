///|
/// Create a mock generator that returns a fixed sequence of note values
fn fixed_generator(values : Array[@music.NoteValue]) -> NoteValueGenerator {
  let mut index = 0
  fn() {
    let value = values[index % values.length()]
    index = index + 1
    value
  }
}

///|
test "generate improvisation with fixed sequence" {
  let midi = @music.MidiNumber::new(60).unwrap()
  let values = [
    @music.NoteValue::Note(midi~, duration=@music.Quarter),
    @music.NoteValue::Note(midi~, duration=@music.Quarter),
    @music.NoteValue::Note(midi~, duration=@music.Half),
  ]
  assert_eq(improvisation(fixed_generator(values), 2), [
    @music.NoteValue::Rest(duration=@music.Whole),
    @music.NoteValue::Note(midi~, duration=@music.Quarter),
    @music.NoteValue::Note(midi~, duration=@music.Quarter),
    @music.NoteValue::Note(midi~, duration=@music.Half),
  ])
}

///|
test "trimming behavior when note exceeds remaining beats" {
  let midi = @music.MidiNumber::new(60).unwrap()
  let values = [@music.NoteValue::Note(midi~, duration=@music.Whole)]
  assert_eq(improvisation(fixed_generator(values), 2), [
    @music.NoteValue::Rest(duration=@music.Whole),
    @music.NoteValue::Note(midi~, duration=@music.Whole),
  ])
}
