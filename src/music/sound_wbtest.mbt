///|
test "extract_sounds_in_window extracts notes in range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let current_time = Duration::from_seconds(10.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="{value: 62}")
  inspect(sounds[0].start_time.to_seconds(), content="10")
  inspect(sounds[0].duration.to_seconds(), content="0.5")
  inspect(sounds[1].midi, content="{value: 64}")
  inspect(sounds[1].start_time.to_seconds(), content="10.5")
  inspect(sounds[1].duration.to_seconds(), content="0.5")
}

///|
test "extract_sounds_in_window skips rests" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Rest(duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let current_time = Duration::from_seconds(5.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="{value: 60}")
  inspect(sounds[1].midi, content="{value: 64}")
}

///|
test "extract_sounds_in_window excludes notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms - 2000ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let current_time = Duration::from_seconds(3.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
  )
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="{value: 62}")
  inspect(sounds[1].midi, content="{value: 64}")
}

///|
test "extract_sounds_in_window returns empty for empty input" {
  let note_values : Array[NoteValue] = []
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let current_time = Duration::from_seconds(0.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
  )
  inspect(sounds.length(), content="0")
}

///|
test "extract_sounds_in_window returns empty when all notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(1000)
  let lookahead = Duration::from_milliseconds(500)
  let current_time = Duration::from_seconds(1.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
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
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let current_time = Duration::from_seconds(2.0)
  let sounds = extract_sounds_in_window(
    sounds_list, current_pos, lookahead, current_time,
  )

  // Should only process first two notes and break early
  inspect(sounds.length(), content="2")
  inspect(sounds[0].midi, content="{value: 60}")
  inspect(sounds[1].midi, content="{value: 62}")
}
