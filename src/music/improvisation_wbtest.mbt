///|
test "generate improvisation from single chord" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = ImprovisationSettings::default()
  let note_values = generate_improvisation(chords, settings, 2)

  // Should generate notes that fit within 4 beats + 2 initial rests
  // Note count varies based on random durations
  inspect(note_values.length() >= 2, content="true")

  // All note values should have valid durations
  for note_value in note_values {
    match note_value.note_duration() {
      Eighth
      | Quarter
      | Half
      | Whole
      | DottedEighth
      | DottedQuarter
      | DottedHalf => ()
      // Compiler ensures exhaustiveness
    }
  }

  // Verify total beats match expected (2 measures: 1 rest + 1 chord = 8 beats)
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
  let note_values = generate_improvisation(chords, settings, 4)

  // Verify total beats approximately match expected (4 measures: 1 rest + 3 chords ≈ 16 beats)
  // May be slightly less due to random duration combinations that can't fill measure exactly
  let mut total_beats = 0.0
  for note_value in note_values {
    total_beats = total_beats + note_value.note_duration().to_beats()
  }
  inspect(total_beats >= 15.5 && total_beats <= 16.0, content="true")
}

///|
test "each measure should not exceed 4 beats" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let beats_per_measure = 4.0

  // Test multiple seeds to find patterns that overflow measures
  for seed = 0; seed < 100; {
    let settings = ImprovisationSettings::{ notes_per_measure: 4, seed }
    let note_values = generate_improvisation(chords, settings, 5)

    // Track beats per measure (measure 0 is leading rest)
    let mut measure_beats = 0.0
    let mut measure_index = 0
    for note_value in note_values {
      let beats = note_value.note_duration().to_beats()
      measure_beats = measure_beats + beats

      // Check if measure would overflow
      if measure_beats > beats_per_measure + 0.001 {
        // This is the bug: a note was added that causes overflow
        fail(
          "Measure \{measure_index} overflow at seed \{seed}: \{measure_beats} beats > \{beats_per_measure}",
        )
      }

      // Move to next measure when current one is filled (within tolerance)
      if measure_beats >= beats_per_measure - 0.001 {
        measure_index = measure_index + 1
        measure_beats = 0.0
      }
    }
    continue seed + 1
  }
}
