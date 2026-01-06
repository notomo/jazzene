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
      Eighth | Quarter | Half => ()
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

///|
test "improvisation with custom settings" {
  let chords = [Chord::{ root: G, quality: Dominant7 }]
  let settings = ImprovisationSettings::{ notes_per_measure: 8 }
  let note_values = generate_improvisation(chords, settings)

  // Verify total beats match expected (8 beats per measure + 4 beats of initial rests = 12 beats)
  let mut total_beats = 0.0
  for note_value in note_values {
    total_beats = total_beats + note_value.note_duration().to_beats()
  }
  inspect(total_beats, content="12")
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
    match note_value.note_duration() {
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
