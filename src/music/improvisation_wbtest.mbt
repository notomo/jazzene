///|
test "generate improvisation from single chord" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::default()
  let notes = generate_improvisation(chords, settings)

  // Should generate 4 notes (default notes_per_measure)
  inspect(notes.length(), content="4")

  // All notes should have valid durations
  for note in notes {
    match note.duration {
      Eighth | Quarter | Half => ()
      // Compiler ensures exhaustiveness
    }
  }
}

///|
test "generate improvisation from chord progression" {
  let chords = [
    Chord::{ root: C, quality: Minor7 },
    Chord::{ root: F, quality: Dominant7 },
    Chord::{ root: B, quality: Major7 },
  ]
  let settings = ImprovisationSettings::default()
  let notes = generate_improvisation(chords, settings)

  // 3 chords * 4 notes = 12 notes
  inspect(notes.length(), content="12")
}

///|
test "improvisation with custom settings" {
  let chords = [Chord::{ root: G, quality: Dominant7 }]
  let settings = ImprovisationSettings::{ notes_per_measure: 8 }
  let notes = generate_improvisation(chords, settings)
  inspect(notes.length(), content="8")
}

///|
test "notes have varying durations" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::{ notes_per_measure: 100 }
  let notes = generate_improvisation(chords, settings)

  // Count duration types
  let mut eighth_count = 0
  let mut quarter_count = 0
  let mut half_count = 0
  for note in notes {
    match note.duration {
      Eighth => eighth_count = eighth_count + 1
      Quarter => quarter_count = quarter_count + 1
      Half => half_count = half_count + 1
    }
  }

  // With 100 notes, we should have variety (not all the same)
  // This is probabilistic, but with 100 samples it's extremely unlikely
  // to get all the same duration
  let has_variety = eighth_count > 0 && quarter_count > 0 && half_count > 0
  inspect(has_variety, content="true")
}
