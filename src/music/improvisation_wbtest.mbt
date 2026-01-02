///|
test "generate improvisation from single chord" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::default()
  let note_values = generate_improvisation(chords, settings)

  // Should generate 4 notes + 2 initial rests = 6 total
  inspect(note_values.length(), content="6")

  // All note values should have valid durations
  for note_value in note_values {
    match note_value.duration() {
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
  let note_values = generate_improvisation(chords, settings)

  // 3 chords * 4 notes + 2 initial rests = 14 total
  inspect(note_values.length(), content="14")
}

///|
test "improvisation with custom settings" {
  let chords = [Chord::{ root: G, quality: Dominant7 }]
  let settings = ImprovisationSettings::{ notes_per_measure: 8 }
  let note_values = generate_improvisation(chords, settings)
  // 8 notes + 2 initial rests = 10 total
  inspect(note_values.length(), content="10")
}

///|
test "notes have varying durations" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::{ notes_per_measure: 100 }
  let note_values = generate_improvisation(chords, settings)

  // Count duration types (including 2 initial Half rests)
  let mut eighth_count = 0
  let mut quarter_count = 0
  let mut half_count = 0
  for note_value in note_values {
    match note_value.duration() {
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
