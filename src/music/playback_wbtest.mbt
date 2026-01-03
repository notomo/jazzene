///|
test "calculate_active_notes - note playing at exact start position" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration at 120 BPM

  // Position at exact start (0ms) should be playing
  let active = calculate_active_midi_notes(notes, 0, tempo)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - note playing in middle of duration" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration

  // Position in middle (250ms) should be playing
  let active = calculate_active_midi_notes(notes, 250, tempo)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - note just before end" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration

  // Position just before end (499ms) should still be playing
  let active = calculate_active_midi_notes(notes, 499, tempo)
  inspect(active, content="[60]")
}

///|
test "calculate_active_notes - position at note end boundary" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration

  // Position at exact end (500ms) should NOT be playing (exclusive end)
  let active = calculate_active_midi_notes(notes, 500, tempo)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - position after note ends" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration

  // Position after note ends should not be playing
  let active = calculate_active_midi_notes(notes, 600, tempo)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - position before note starts" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms

  // Negative position should not be playing
  let active = calculate_active_midi_notes(notes, -100, tempo)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - rest notes are ignored" {
  let tempo = 120
  let notes = [Rest(duration=Quarter)] // 500ms rest

  // Position during rest should return empty array
  let active = calculate_active_midi_notes(notes, 250, tempo)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - multiple sequential notes" {
  let tempo = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Note 1: 0-500ms, Note 2: 500-1000ms, Note 3: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Note(midi=midi2, duration=Quarter),
    Note(midi=midi3, duration=Quarter),
  ]

  // First note playing
  inspect(calculate_active_midi_notes(notes, 250, tempo), content="[60]")

  // Second note playing
  inspect(calculate_active_midi_notes(notes, 750, tempo), content="[64]")

  // Third note playing
  inspect(calculate_active_midi_notes(notes, 1250, tempo), content="[67]")
}

///|
test "calculate_active_notes - notes with rests in between" {
  let tempo = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  // Note 1: 0-500ms, Rest: 500-1000ms, Note 2: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi=midi2, duration=Quarter),
  ]

  // First note playing
  inspect(calculate_active_midi_notes(notes, 250, tempo), content="[60]")

  // During rest, nothing playing
  inspect(calculate_active_midi_notes(notes, 750, tempo), content="[]")

  // Second note playing
  inspect(calculate_active_midi_notes(notes, 1250, tempo), content="[64]")
}

///|
test "calculate_active_notes - empty note array" {
  let notes : Array[NoteValue] = []
  let active = calculate_active_midi_notes(notes, 100, 120)
  inspect(active, content="[]")
}

///|
test "calculate_active_notes - different tempos" {
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)]

  // Tempo 120: Quarter note = 500ms
  inspect(calculate_active_midi_notes(notes, 250, 120), content="[60]")
  inspect(calculate_active_midi_notes(notes, 500, 120), content="[]")

  // Tempo 90: Quarter note = 666ms
  inspect(calculate_active_midi_notes(notes, 250, 90), content="[60]")
  inspect(calculate_active_midi_notes(notes, 666, 90), content="[]")
}

///|
test "calculate_active_notes - mixed note durations" {
  let tempo = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Half (1000ms) + Quarter (500ms) + Eighth (250ms)
  let notes = [
    Note(midi=midi1, duration=Half), // 0-1000ms
    Note(midi=midi2, duration=Quarter), // 1000-1500ms
    Note(midi=midi3, duration=Eighth), // 1500-1750ms
  ]
  inspect(calculate_active_midi_notes(notes, 500, tempo), content="[60]")
  inspect(calculate_active_midi_notes(notes, 1250, tempo), content="[64]")
  inspect(calculate_active_midi_notes(notes, 1625, tempo), content="[67]")
}

///|
test "calculate_active_notes - multiple notes with same MIDI number" {
  let tempo = 120
  let midi = MidiNumber::new(60).unwrap()
  // Same note repeated
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Note(midi~, duration=Quarter),
  ] // 500-1000ms

  // First occurrence
  inspect(calculate_active_midi_notes(notes, 250, tempo), content="[60]")

  // Second occurrence
  inspect(calculate_active_midi_notes(notes, 750, tempo), content="[60]")
}
