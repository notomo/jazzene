///|
test "extract_sounds_in_window extracts notes in range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let tempo_bpm = 120
  let current_pos_ms = 500
  let lookahead_ms = 1000
  let current_time = 10.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="62")
  inspect(sounds[0].audio_start_time, content="10")
  inspect(sounds[0].duration_sec, content="0.5")
  inspect(sounds[1].midi, content="64")
  inspect(sounds[1].audio_start_time, content="10.5")
  inspect(sounds[1].duration_sec, content="0.5")
}

///|
test "extract_sounds_in_window skips rests" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Rest(duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let tempo_bpm = 120
  let current_pos_ms = 0
  let lookahead_ms = 1500
  let current_time = 5.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="60")
  inspect(sounds[1].midi, content="64")
}

///|
test "extract_sounds_in_window excludes notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms - 2000ms
  ]
  let tempo_bpm = 120
  let current_pos_ms = 500
  let lookahead_ms = 1000
  let current_time = 3.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="62")
  inspect(sounds[1].midi, content="64")
}

///|
test "extract_sounds_in_window returns empty for empty input" {
  let note_values : Array[NoteValue] = []
  let tempo_bpm = 120
  let current_pos_ms = 0
  let lookahead_ms = 1000
  let current_time = 0.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )
  inspect(sounds.length(), content="0")
}

///|
test "extract_sounds_in_window returns empty when all notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
  ]
  let tempo_bpm = 120
  let current_pos_ms = 1000
  let lookahead_ms = 500
  let current_time = 1.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )
  inspect(sounds.length(), content="0")
}

///|
test "extract_sounds_in_window stops early when past window" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms - 2000ms
    Note(midi=MidiNumber::{ value: 67 }, duration=Quarter), // 2000ms - 2500ms
  ]
  let tempo_bpm = 120
  let current_pos_ms = 0
  let lookahead_ms = 1000
  let current_time = 2.0
  let sounds = extract_sounds_in_window(
    note_values, tempo_bpm, current_pos_ms, lookahead_ms, current_time,
  )

  // Should only process first two notes and break early
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="60")
  inspect(sounds[1].midi, content="62")
}
