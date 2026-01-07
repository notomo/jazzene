///|
test "calculate_active_notes - note playing at exact start position" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration at 120 BPM
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position at exact start (0ms) should be playing
  let active = calculate_active_midi_notes(sounds_list, 0)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - note playing in middle of duration" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position in middle (250ms) should be playing
  let active = calculate_active_midi_notes(sounds_list, 250)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - note just before end" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position just before end (499ms) should still be playing
  let active = calculate_active_midi_notes(sounds_list, 499)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - position at note end boundary" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position at exact end (500ms) should NOT be playing (exclusive end)
  let active = calculate_active_midi_notes(sounds_list, 500)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - position after note ends" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position after note ends should not be playing
  let active = calculate_active_midi_notes(sounds_list, 600)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - position before note starts" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Negative position should not be playing
  let active = calculate_active_midi_notes(sounds_list, -100)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - rest notes are ignored" {
  let bpm = 120
  let notes = [Rest(duration=Quarter)] // 500ms rest
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // Position during rest should return empty array
  let active = calculate_active_midi_notes(sounds_list, 250)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - multiple sequential notes" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Note 1: 0-500ms, Note 2: 500-1000ms, Note 3: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Note(midi=midi2, duration=Quarter),
    Note(midi=midi3, duration=Quarter),
  ]
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // First note playing
  inspect(calculate_active_midi_notes(sounds_list, 250), content="[60]")

  // Second note playing
  inspect(calculate_active_midi_notes(sounds_list, 750), content="[64]")

  // Third note playing
  inspect(calculate_active_midi_notes(sounds_list, 1250), content="[67]")
}

///|
test "calculate_active_notes - notes with rests in between" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  // Note 1: 0-500ms, Rest: 500-1000ms, Note 2: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi=midi2, duration=Quarter),
  ]
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // First note playing
  inspect(calculate_active_midi_notes(sounds_list, 250), content="[60]")

  // During rest, nothing playing
  inspect(calculate_active_midi_notes(sounds_list, 750), content="[]")

  // Second note playing
  inspect(calculate_active_midi_notes(sounds_list, 1250), content="[64]")
}

///|
test "calculate_active_notes - empty note array" {
  let notes : Array[NoteValue] = []
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, 120)
  })
  let active = calculate_active_midi_notes(sounds_list, 100)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - different bpm" {
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)]

  // bpm 120: Quarter note = 500ms
  let sounds_120 = notes.map(fn(nv) { NoteValueSound::from_note_value(nv, 120) })
  inspect(calculate_active_midi_notes(sounds_120, 250.0), content="[60]")
  inspect(calculate_active_midi_notes(sounds_120, 500.0), content="[]")

  // bpm 90: Quarter note = 666.666...ms
  let sounds_90 = notes.map(fn(nv) { NoteValueSound::from_note_value(nv, 90) })
  inspect(calculate_active_midi_notes(sounds_90, 250.0), content="[60]")
  inspect(
    calculate_active_midi_notes(sounds_90, 666.6666666666666),
    content="[]",
  )
}

///|
test "calculate_active_notes - mixed note durations" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Half (1000ms) + Quarter (500ms) + Eighth (250ms)
  let notes = [
    Note(midi=midi1, duration=Half), // 0-1000ms
    Note(midi=midi2, duration=Quarter), // 1000-1500ms
    Note(midi=midi3, duration=Eighth), // 1500-1750ms
  ]
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })
  inspect(calculate_active_midi_notes(sounds_list, 500), content="[60]")
  inspect(calculate_active_midi_notes(sounds_list, 1250), content="[64]")
  inspect(calculate_active_midi_notes(sounds_list, 1625), content="[67]")
}

///|
test "calculate_active_notes - multiple notes with same MIDI number" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  // Same note repeated
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Note(midi~, duration=Quarter),
  ] // 500-1000ms
  let sounds_list = notes.map(fn(nv) {
    NoteValueSound::from_note_value(nv, bpm)
  })

  // First occurrence
  inspect(calculate_active_midi_notes(sounds_list, 250), content="[60]")

  // Second occurrence
  inspect(calculate_active_midi_notes(sounds_list, 750), content="[60]")
}
