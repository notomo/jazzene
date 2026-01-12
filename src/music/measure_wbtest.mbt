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

  // Convert to measures
  let measures = convert_sounds_to_measures(sounds, chords, bpm)

  // Verify number of measures
  inspect(measures.length(), content="2")

  // Verify first measure (C major7)
  let m0 = measures[0]
  inspect(m0.measure_index, content="0")
  inspect(m0.chord.root, content="C")
  inspect(m0.chord.quality, content="Major7")
  inspect(m0.notes.length(), content="4")

  // Check first note in first measure (C4)
  let n0 = m0.notes[0]
  match n0.midi {
    Some(midi) => inspect(midi, content="60")
    None => abort("Expected note, got rest")
  }
  inspect(n0.duration, content="Quarter")
  inspect(n0.start_beat, content="0")

  // Check last note in first measure (B4)
  let n3 = m0.notes[3]
  match n3.midi {
    Some(midi) => inspect(midi, content="71")
    None => abort("Expected note, got rest")
  }
  inspect(n3.start_beat, content="3")

  // Verify second measure (F7)
  let m1 = measures[1]
  inspect(m1.measure_index, content="1")
  inspect(m1.chord.root, content="F")
  inspect(m1.chord.quality, content="Dominant7")
  inspect(m1.notes.length(), content="4")

  // Check first note in second measure (F4)
  let n4 = m1.notes[0]
  match n4.midi {
    Some(midi) => inspect(midi, content="65")
    None => abort("Expected note, got rest")
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
  let measures = convert_sounds_to_measures(sounds, chords, bpm)
  inspect(measures.length(), content="1")
  let m0 = measures[0]
  inspect(m0.notes.length(), content="3")

  // First note should be at beat 0 with Half duration
  let n0 = m0.notes[0]
  inspect(n0.duration, content="Half")
  inspect(n0.start_beat, content="0")

  // Second note should be at beat 2
  let n1 = m0.notes[1]
  inspect(n1.start_beat, content="2")

  // Third note should be at beat 3
  let n2 = m0.notes[2]
  inspect(n2.start_beat, content="3")
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
  let measures = convert_sounds_to_measures(sounds, chords, bpm)
  inspect(measures.length(), content="2")

  // First measure should have 4 rests (rests are included with midi=None)
  let m0 = measures[0]
  inspect(m0.notes.length(), content="4")
  // Verify all notes in measure 1 are rests
  for i = 0; i < m0.notes.length(); {
    match m0.notes[i].midi {
      Some(_) => abort("Expected rest in measure 1, got note")
      None => ()
    }
    continue i + 1
  }

  // Second measure should have one note
  let m1 = measures[1]
  inspect(m1.notes.length(), content="1")
  match m1.notes[0].midi {
    Some(midi) => inspect(midi, content="60")
    None => abort("Expected note in measure 2, got rest")
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
  let measures = convert_sounds_to_measures(sounds, chords, bpm)

  // Should return empty array
  inspect(measures.length(), content="0")
}
