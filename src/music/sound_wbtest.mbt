///|
test "calculate_total_duration" {
  let bpm = 120
  let midi = MidiNumber::{ value: 60 }
  let notes = [
    Note(midi~, duration=Half),
    Note(midi~, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi~, duration=Eighth),
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  assert_eq(calculate_total_duration(sounds).to_milliseconds(), 2250.0)
}

///|
test "in_range" {
  let bpm = 120
  let midi = MidiNumber::{ value: 60 }
  let notes = [Note(midi~, duration=Quarter)] // 0ms~500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]
  assert_false(sound.in_range(Duration::from_milliseconds(-1)))
  assert_true(sound.in_range(Duration::from_milliseconds(0)))
  assert_true(sound.in_range(Duration::from_milliseconds(499)))
  assert_false(sound.in_range(Duration::from_milliseconds(500)))
}

///|
test "calculate_playing_notes" {
  let bpm = 120
  let midi = MidiNumber::{ value: 60 }
  let notes = [Note(midi~, duration=Quarter)] // 0ms~500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(-1)), [])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(0)), [
    sounds[0],
  ])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(500)), [])
}
