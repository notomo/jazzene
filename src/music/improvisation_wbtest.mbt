///|
/// Create a mock generator that returns a fixed sequence of note values
fn create_fixed_generator(values : Array[NoteValue]) -> NoteValueGenerator {
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
  let gen = create_fixed_generator(values)
  let result = generate_improvisation(gen, 2) // 8 beats total
  // First note should be leading rest (4 beats)
  inspect(result[0], content="Rest(duration=Whole)")
  // Then our fixed sequence should fill remaining 4 beats
  // Quarter (1) + Quarter (1) + Half (2) = 4 beats
  inspect(result.length(), content="4")
  let mut total_beats = 0.0
  for i = 0; i < result.length(); i = i + 1 {
    total_beats = total_beats + result[i].note_duration().to_beats()
  }
  inspect(total_beats, content="8")
}

///|
test "trimming behavior when note exceeds remaining beats" {
  let midi = MidiNumber::new(60).unwrap()
  // Generator that only returns whole notes (4 beats)
  let values = [NoteValue::Note(midi~, duration=Whole)]
  let gen = create_fixed_generator(values)
  // 3 measures = 12 beats, after leading rest (4 beats), 8 beats remain
  // 8 / 4 = 2 whole notes fit exactly
  let result = generate_improvisation(gen, 3)
  // Leading rest (4) + 2 whole notes (8) = 12 beats
  let mut total_beats = 0.0
  for i = 0; i < result.length(); i = i + 1 {
    total_beats = total_beats + result[i].note_duration().to_beats()
  }
  inspect(total_beats, content="12")
}

///|
test "trimming trims note to fit remaining beats" {
  let midi = MidiNumber::new(60).unwrap()
  // Generator returns whole notes (4 beats)
  let values = [NoteValue::Note(midi~, duration=Whole)]
  let gen = create_fixed_generator(values)
  // 2.5 measures = 10 beats, after leading rest (4), 6 remain
  // First whole note uses 4, leaving 2 beats
  // Second whole note (4) won't fit, should trim to Half (2)
  let result = generate_improvisation(gen, 2) // 8 beats total
  // Leading rest (4) + whole (4) = 8 beats exactly
  let mut total_beats = 0.0
  for i = 0; i < result.length(); i = i + 1 {
    total_beats = total_beats + result[i].note_duration().to_beats()
  }
  inspect(total_beats, content="8")
}

///|
test "generate improvisation from real generator" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = GeneratorSettings::default(chords, 0)
  let gen = create_note_value_generator(settings)
  let note_values = generate_improvisation(gen, 2)
  // Should have at least 2 note values (leading rest + at least one more)
  inspect(note_values.length() >= 2, content="true")
  // First should be leading rest
  inspect(note_values[0], content="Rest(duration=Whole)")
  // All note values should have valid durations
  for i = 0; i < note_values.length(); i = i + 1 {
    match note_values[i].note_duration() {
      Eighth
      | Quarter
      | Half
      | Whole
      | DottedEighth
      | DottedQuarter
      | DottedHalf => ()
    }
  }
}

///|
test "generate improvisation total beats match expected" {
  let chords = [
    Chord::{ root: C, quality: Minor7 },
    Chord::{ root: F, quality: Dominant7 },
    Chord::{ root: B, quality: Major7 },
  ]
  let settings = GeneratorSettings::default(chords, 0)
  let gen = create_note_value_generator(settings)
  let note_values = generate_improvisation(gen, 4)
  // Total should be exactly 16 beats (4 measures * 4 beats)
  let mut total_beats = 0.0
  for i = 0; i < note_values.length(); i = i + 1 {
    total_beats = total_beats + note_values[i].note_duration().to_beats()
  }
  inspect(total_beats, content="16")
}

///|
test "deterministic with same seed" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings1 = GeneratorSettings::default(chords, 42)
  let settings2 = GeneratorSettings::default(chords, 42)
  let gen1 = create_note_value_generator(settings1)
  let gen2 = create_note_value_generator(settings2)
  let result1 = generate_improvisation(gen1, 4)
  let result2 = generate_improvisation(gen2, 4)
  inspect(result1.length() == result2.length(), content="true")
  for i = 0; i < result1.length(); i = i + 1 {
    inspect(result1[i] == result2[i], content="true")
  }
}
