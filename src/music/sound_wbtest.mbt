///|
test "calculate_total_duration" {
  // 1 measure at 120 bpm = 1 * 240 / 120 * 1000 = 2000 ms
  assert_eq(
    calculate_total_duration(bpm=120, measure_count=1).to_milliseconds(),
    2000.0,
  )
  // 2 measures at 120 bpm = 2 * 240 / 120 * 1000 = 4000 ms
  assert_eq(
    calculate_total_duration(bpm=120, measure_count=2).to_milliseconds(),
    4000.0,
  )
  // 1 measure at 60 bpm = 1 * 240 / 60 * 1000 = 4000 ms
  assert_eq(
    calculate_total_duration(bpm=60, measure_count=1).to_milliseconds(),
    4000.0,
  )
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
