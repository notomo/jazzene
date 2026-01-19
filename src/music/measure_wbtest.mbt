///|
test "convert_sounds_to_measures basic case" {
  // Setup test data
  let bpm = 120

  // Create note values: leading rest (4 beats) + 2 measures of notes
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Quarter), // beat 3
    // Measure 1: C major7
    Note(midi=MidiNumber::new(60).unwrap(), duration=Quarter), // C4, beat 0
    Note(midi=MidiNumber::new(64).unwrap(), duration=Quarter), // E4, beat 1
    Note(midi=MidiNumber::new(67).unwrap(), duration=Quarter), // G4, beat 2
    Note(midi=MidiNumber::new(71).unwrap(), duration=Quarter), // B4, beat 3
    // Measure 2: F7
    Note(midi=MidiNumber::new(65).unwrap(), duration=Quarter), // F4, beat 0
    Note(midi=MidiNumber::new(69).unwrap(), duration=Quarter), // A4, beat 1
    Note(midi=MidiNumber::new(72).unwrap(), duration=Quarter), // C5, beat 2
    Note(midi=MidiNumber::new(75).unwrap(), duration=Quarter), // Eb5, beat 3
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)

  // Create chords
  let chords = [
    Chord::{ root: C, quality: Major7 },
    Chord::{ root: F, quality: Dominant7 },
  ]

  // Convert to measures (1 leading rest + 2 chord measures = 3 total)
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 3)

  // Verify number of measures (leading rest + 2 chord measures)
  assert_eq(measures.length(), 3)

  // Verify leading rest measure
  let m0 = measures[0]
  assert_eq(m0.measure_index, 0)
  assert_eq(m0.notes.length(), 4)
  // All notes should be rests
  for i = 0; i < m0.notes.length(); {
    match m0.notes[i].midi {
      Some(_) => fail("Expected rest in leading measure, got note")
      None => ()
    }
    continue i + 1
  }

  // Verify first chord measure (C major7)
  let m1 = measures[1]
  assert_eq(m1.measure_index, 1)
  inspect(m1.chord.root, content="C")
  inspect(m1.chord.quality, content="Major7")
  assert_eq(m1.notes.length(), 4)

  // Check first note in first chord measure (C4)
  let n0 = m1.notes[0]
  match n0.midi {
    Some(midi) => assert_eq(midi, 60)
    None => fail("Expected note, got rest")
  }
  inspect(n0.duration, content="Quarter")
  assert_eq(n0.start_beat, 0.0)

  // Check last note in first chord measure (B4)
  let n3 = m1.notes[3]
  match n3.midi {
    Some(midi) => assert_eq(midi, 71)
    None => fail("Expected note, got rest")
  }
  assert_eq(n3.start_beat, 3.0)

  // Verify second chord measure (F7)
  let m2 = measures[2]
  assert_eq(m2.measure_index, 2)
  inspect(m2.chord.root, content="F")
  inspect(m2.chord.quality, content="Dominant7")
  assert_eq(m2.notes.length(), 4)

  // Check first note in second chord measure (F4)
  let n4 = m2.notes[0]
  match n4.midi {
    Some(midi) => assert_eq(midi, 65)
    None => fail("Expected note, got rest")
  }
}

///|
test "convert_sounds_to_measures with mixed durations" {
  let bpm = 120

  // Leading rest + notes with different durations
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    // Measure 1
    Note(midi=MidiNumber::new(60).unwrap(), duration=Half), // 2 beats
    Note(midi=MidiNumber::new(64).unwrap(), duration=Quarter), // 1 beat
    Note(midi=MidiNumber::new(67).unwrap(), duration=Quarter), // 1 beat
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [Chord::{ root: C, quality: Major }]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 2)
  // Leading rest + 1 chord measure
  assert_eq(measures.length(), 2)
  // Check first chord measure (skip leading rest at index 0)
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 3)

  // First note should be at beat 0 with Half duration
  let n0 = m1.notes[0]
  inspect(n0.duration, content="Half")
  assert_eq(n0.start_beat, 0.0)

  // Second note should be at beat 2
  let n1 = m1.notes[1]
  assert_eq(n1.start_beat, 2.0)

  // Third note should be at beat 3
  let n2 = m1.notes[2]
  assert_eq(n2.start_beat, 3.0)
}

///|
test "convert_sounds_to_measures with empty measure" {
  let bpm = 120

  // Leading rest + only notes in second measure
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    // Measure 1: empty (all rests)
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    // Measure 2: has notes
    Note(midi=MidiNumber::new(60).unwrap(), duration=Quarter),
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [
    Chord::{ root: C, quality: Major },
    Chord::{ root: G, quality: Major },
  ]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 3)
  // Leading rest + 2 chord measures
  assert_eq(measures.length(), 3)

  // Leading rest measure (index 0) should have 4 rests
  let m0 = measures[0]
  assert_eq(m0.notes.length(), 4)

  // First chord measure (index 1) should have 4 rests (rests are included with midi=None)
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 4)
  // Verify all notes in first chord measure are rests
  for i = 0; i < m1.notes.length(); {
    match m1.notes[i].midi {
      Some(_) => fail("Expected rest in measure 1, got note")
      None => ()
    }
    continue i + 1
  }

  // Second chord measure (index 2) should have one note
  let m2 = measures[2]
  assert_eq(m2.notes.length(), 1)
  match m2.notes[0].midi {
    Some(midi) => assert_eq(midi, 60)
    None => fail("Expected note in measure 2, got rest")
  }
}

///|
test "convert_sounds_to_measures with no chords" {
  let bpm = 120
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::new(60).unwrap(), duration=Quarter),
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords : Array[Chord] = []
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 1)

  // Should return only leading rest measure with dummy chord
  assert_eq(measures.length(), 1)
  let m0 = measures[0]
  assert_eq(m0.measure_index, 0)
  // Leading rest should contain the note since it falls within the first measure
  assert_eq(m0.notes.length(), 1)
}

///|
test "convert_sounds_to_measures with chord cycling for more measures than chords" {
  let bpm = 120

  // Create sounds for 5 measures total (1 leading rest + 4 chord measures)
  // This represents the output from generate_improvisation with measure_count=5
  let note_values : Array[NoteValue] = [
    // Leading rest measure (measure 0)
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    Rest(duration=Quarter),
    // Measure 1: Cm7
    Note(midi=MidiNumber::new(60).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(63).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(67).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(70).unwrap(), duration=Quarter),
    // Measure 2: F7
    Note(midi=MidiNumber::new(65).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(69).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(72).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(75).unwrap(), duration=Quarter),
    // Measure 3: Cm7 (cycling)
    Note(midi=MidiNumber::new(60).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(63).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(67).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(70).unwrap(), duration=Quarter),
    // Measure 4: F7 (cycling)
    Note(midi=MidiNumber::new(65).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(69).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(72).unwrap(), duration=Quarter),
    Note(midi=MidiNumber::new(75).unwrap(), duration=Quarter),
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)

  // Only 2 chords in the progression, but we want 5 measures total
  let chords = [
    Chord::{ root: C, quality: Minor7 },
    Chord::{ root: F, quality: Dominant7 },
  ]

  // Convert to measures with measure_count=5
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 5)

  // Should create 5 measures (1 leading rest + 4 chord measures)
  assert_eq(measures.length(), 5)

  // Verify measure indices
  assert_eq(measures[0].measure_index, 0)
  assert_eq(measures[1].measure_index, 1)
  assert_eq(measures[2].measure_index, 2)
  assert_eq(measures[3].measure_index, 3)
  assert_eq(measures[4].measure_index, 4)

  // Verify chord cycling: [Cm7, F7, Cm7, F7]
  inspect(measures[1].chord.root, content="C")
  inspect(measures[1].chord.quality, content="Minor7")
  inspect(measures[2].chord.root, content="F")
  inspect(measures[2].chord.quality, content="Dominant7")
  inspect(measures[3].chord.root, content="C")
  inspect(measures[3].chord.quality, content="Minor7")
  inspect(measures[4].chord.root, content="F")
  inspect(measures[4].chord.quality, content="Dominant7")

  // Verify each measure has notes
  assert_eq(measures[1].notes.length(), 4)
  assert_eq(measures[2].notes.length(), 4)
  assert_eq(measures[3].notes.length(), 4)
  assert_eq(measures[4].notes.length(), 4)
}

///|
test "convert_sounds_to_measures splits note across measure boundary" {
  let bpm = 120

  // Create a note that spans across measure boundaries
  // Leading rest (4 beats) + note starting at beat 3 with Half duration (2 beats)
  // This should split: beat 3 of measure 1 (1 beat) + beat 0 of measure 2 (1 beat)
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Quarter), // beat 3
    // Measure 1: note starts at beat 3
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Note(midi=MidiNumber::new(60).unwrap(), duration=Half), // beat 3, spans to next measure
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [
    Chord::{ root: C, quality: Major },
    Chord::{ root: G, quality: Major },
  ]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 3)

  // Verify we have 3 measures
  assert_eq(measures.length(), 3)

  // Measure 1 should have 4 notes (3 rests + 1 split note with TieStart)
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 4)

  // Last note in measure 1 should be the split note with TieStart
  let n1_last = m1.notes[3]
  match n1_last.midi {
    Some(midi) => assert_eq(midi, 60)
    None => fail("Expected note, got rest")
  }
  assert_eq(n1_last.start_beat, 3.0)
  assert_eq(n1_last.tie_state, TieStart)
  // Duration should be 1 beat (Quarter, since it's split at measure boundary)
  inspect(n1_last.duration, content="Quarter")

  // Measure 2 should have 1 note (the continuation with TieEnd)
  let m2 = measures[2]
  assert_eq(m2.notes.length(), 1)
  let n2_first = m2.notes[0]
  match n2_first.midi {
    Some(midi) => assert_eq(midi, 60)
    None => fail("Expected note, got rest")
  }
  assert_eq(n2_first.start_beat, 0.0)
  assert_eq(n2_first.tie_state, TieEnd)
  // Duration should be 1 beat (Quarter, the remaining beat)
  inspect(n2_first.duration, content="Quarter")
}

///|
test "convert_sounds_to_measures splits note spanning 3 measures" {
  let bpm = 120

  // Create a note that spans 3 measures (Whole note starting at beat 2 = 6 beats total needed)
  // This should split: 2 beats in measure 1 + 4 beats in measure 2 + 0 beats in measure 3
  // Actually a Whole note is 4 beats. Starting at beat 2 means:
  // - Measure 1: 2 beats (TieStart)
  // - Measure 2: 2 beats (TieEnd)
  // Let's use DottedHalf (3 beats) starting at beat 2:
  // - Measure 1: 2 beats (TieStart)
  // - Measure 2: 1 beat (TieEnd)
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Quarter), // beat 3
    // Measure 1:
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Note(midi=MidiNumber::new(64).unwrap(), duration=DottedHalf), // beat 2, 3 beats total
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [Chord::{ root: C, quality: Major }]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 3)

  // Verify we have 3 measures
  assert_eq(measures.length(), 3)

  // Measure 1 should have 3 notes (2 rests + 1 split note with TieStart)
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 3)

  // Last note in measure 1 should be the split note with TieStart
  let n1_last = m1.notes[2]
  match n1_last.midi {
    Some(midi) => assert_eq(midi, 64)
    None => fail("Expected note, got rest")
  }
  assert_eq(n1_last.start_beat, 2.0)
  assert_eq(n1_last.tie_state, TieStart)
  // Duration should be 2 beats (Half)
  inspect(n1_last.duration, content="Half")

  // Measure 2 should have 1 note (the continuation with TieEnd)
  let m2 = measures[2]
  assert_eq(m2.notes.length(), 1)
  let n2_first = m2.notes[0]
  match n2_first.midi {
    Some(midi) => assert_eq(midi, 64)
    None => fail("Expected note, got rest")
  }
  assert_eq(n2_first.start_beat, 0.0)
  assert_eq(n2_first.tie_state, TieEnd)
  // Duration should be 1 beat (Quarter)
  inspect(n2_first.duration, content="Quarter")
}

///|
test "convert_sounds_to_measures does not split rests" {
  let bpm = 120

  // Create a rest that would span across measure boundaries if it were a note
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Quarter), // beat 3
    // Measure 1:
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Half), // beat 3, would span if it were a note
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [Chord::{ root: C, quality: Major }]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 3)

  // Verify we have 3 measures
  assert_eq(measures.length(), 3)

  // Measure 1 should have 4 notes (all rests, no splitting)
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 4)

  // Last note in measure 1 should be a rest with TieState::None
  let n1_last = m1.notes[3]
  match n1_last.midi {
    Some(_) => fail("Expected rest, got note")
    None => ()
  }
  assert_eq(n1_last.tie_state, TieState::None)

  // Measure 2 should have no notes (rest wasn't split)
  let m2 = measures[2]
  assert_eq(m2.notes.length(), 0)
}

///|
test "convert_sounds_to_measures note fitting exactly in measure has no tie" {
  let bpm = 120

  // Create a note that fits exactly in the measure (no splitting needed)
  let note_values : Array[NoteValue] = [
    Rest(duration=Quarter), // beat 0
    Rest(duration=Quarter), // beat 1
    Rest(duration=Quarter), // beat 2
    Rest(duration=Quarter), // beat 3
    // Measure 1:
    Note(midi=MidiNumber::new(60).unwrap(), duration=Whole), // beat 0, exactly 4 beats
  ]
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let chords = [Chord::{ root: C, quality: Major }]
  let measures = convert_sounds_to_measures(sounds, chords, bpm, 2)

  // Verify we have 2 measures
  assert_eq(measures.length(), 2)

  // Measure 1 should have 1 note with TieState::None
  let m1 = measures[1]
  assert_eq(m1.notes.length(), 1)
  let n1 = m1.notes[0]
  match n1.midi {
    Some(midi) => assert_eq(midi, 60)
    None => fail("Expected note, got rest")
  }
  assert_eq(n1.tie_state, TieState::None)
  inspect(n1.duration, content="Whole")
}
