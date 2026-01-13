///|
test "generate improvisation from single chord" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::default()
  let note_values = generate_improvisation(chords, settings)

  // Should generate notes that fit within 4 beats + 2 initial rests
  // Note count varies based on random durations
  inspect(note_values.length() >= 2, content="true")

  // All note values should have valid durations
  for note_value in note_values {
    match note_value.note_duration() {
      Eighth | Quarter | Half | DottedEighth | DottedQuarter | DottedHalf => ()
      // Compiler ensures exhaustiveness
    }
  }

  // Verify total beats match expected (4 beats per measure + 4 beats of initial rests)
  let mut total_beats = 0.0
  for note_value in note_values {
    total_beats = total_beats + note_value.note_duration().to_beats()
  }
  inspect(total_beats, content="8")
}

///|
test "generate improvisation from chord progression" {
  let chords = [
    Chord::{ root: C, quality: Minor7 },
    Chord::{ root: F, quality: Dominant7 },
    Chord::{ root: B, quality: Major7 },
  ]
  let settings = ImprovisationSettings::default()
  let note_values = generate_improvisation(chords, settings)

  // Verify total beats match expected (3 chords * 4 beats + 4 beats of initial rests = 16 beats)
  let mut total_beats = 0.0
  for note_value in note_values {
    total_beats = total_beats + note_value.note_duration().to_beats()
  }
  inspect(total_beats, content="16")
}
