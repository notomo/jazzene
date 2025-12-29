///|
test "generate improvisation with default settings" {
  let chords = [Chord::{ root: "C", quality: "maj7" }]
  let settings = ImprovisationSettings::default()
  let notes = generate_improvisation(chords, settings)
  assert_eq(notes.length(), 4) // 1 chord × 4 notes
}

///|
test "generate improvisation for multiple chords" {
  let chords = [
    Chord::{ root: "C", quality: "m7" },
    Chord::{ root: "F", quality: "7" },
    Chord::{ root: "Bb", quality: "maj7" },
  ]
  let settings = ImprovisationSettings::{ notes_per_measure: 4 }
  let notes = generate_improvisation(chords, settings)
  assert_eq(notes.length(), 12) // 3 chords × 4 notes
}

///|
test "generate improvisation with custom notes per measure" {
  let chords = [Chord::{ root: "C", quality: "maj7" }]
  let settings = ImprovisationSettings::{ notes_per_measure: 8 }
  let notes = generate_improvisation(chords, settings)
  assert_eq(notes.length(), 8)
}

///|
test "generate improvisation with empty chords" {
  let chords : Array[Chord] = []
  let settings = ImprovisationSettings::default()
  let notes = generate_improvisation(chords, settings)
  assert_eq(notes.length(), 0)
}

///|
test "generated notes are within valid range" {
  let chords = [Chord::{ root: "C", quality: "maj7" }]
  let settings = ImprovisationSettings::{ notes_per_measure: 10 }
  let notes = generate_improvisation(chords, settings)
  for note in notes {
    assert_true(note.midi_number >= 48) // C3
    assert_true(note.midi_number <= 84) // C6
  }
}

///|
test "Note::name returns correct name" {
  let c4 = Note::from_midi(60)
  assert_eq(c4.name(), "C4")
  let eb5 = Note::from_midi(75)
  assert_eq(eb5.name(), "D#5")
}
