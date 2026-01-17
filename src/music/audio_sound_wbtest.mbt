///|
test "AudioSound::from creates audio sounds with correct offset" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Note(midi~, duration=Quarter),
  ] // 500-1000ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds.length(), content="2")
  inspect(audio_sounds[0].offset.to_milliseconds(), content="0")
  inspect(audio_sounds[1].offset.to_milliseconds(), content="500")
}

///|
test "AudioSound::from calculates offset from current_pos" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Note(midi~, duration=Quarter), // 500-1000ms
    Note(midi~, duration=Quarter), // 1000-1500ms
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  // offset = start_time - current_pos
  inspect(audio_sounds[0].offset.to_milliseconds(), content="0")
  inspect(audio_sounds[1].offset.to_milliseconds(), content="500")
  inspect(audio_sounds[2].offset.to_milliseconds(), content="1000")
}

///|
test "AudioSound::from filters out rests" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Rest(duration=Quarter), // 500-1000ms (filtered out)
    Note(midi~, duration=Quarter), // 1000-1500ms
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds.length(), content="2")
  inspect(audio_sounds[0].offset.to_milliseconds(), content="0")
  inspect(audio_sounds[1].offset.to_milliseconds(), content="1000")
}

///|
test "AudioSound::from preserves duration" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [
    Note(midi~, duration=Quarter), // 500ms duration
    Note(midi~, duration=Half), // 1000ms duration
    Note(midi~, duration=Eighth), // 250ms duration
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(2000)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds[0].duration.to_milliseconds(), content="500")
  inspect(audio_sounds[1].duration.to_milliseconds(), content="1000")
  inspect(audio_sounds[2].duration.to_milliseconds(), content="250")
}

///|
test "AudioSound::from preserves midi" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Note(midi=midi2, duration=Quarter),
    Note(midi=midi3, duration=Quarter),
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds[0].midi.value, content="60")
  inspect(audio_sounds[1].midi.value, content="64")
  inspect(audio_sounds[2].midi.value, content="67")
}

///|
test "AudioSound::from returns empty for empty input" {
  let sounds : Array[NoteValueSound] = []
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds.length(), content="0")
}

///|
test "AudioSound::from returns empty for only rests" {
  let bpm = 120
  let notes = [Rest(duration=Quarter), Rest(duration=Quarter)]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  inspect(audio_sounds.length(), content="0")
}

///|
test "AudioSound::start_time adds offset to audio_current_time" {
  let audio_sound = AudioSound::{
    offset: Duration::from_milliseconds(100),
    duration: Duration::from_milliseconds(500),
    midi: MidiNumber::new(60).unwrap(),
  }
  let audio_current_time = Duration::from_milliseconds(1000)
  let start_time = audio_sound.start_time(audio_current_time)
  inspect(start_time.to_milliseconds(), content="1100")
}

///|
test "AudioSound::start_time with zero offset" {
  let audio_sound = AudioSound::{
    offset: Duration::from_milliseconds(0),
    duration: Duration::from_milliseconds(500),
    midi: MidiNumber::new(60).unwrap(),
  }
  let audio_current_time = Duration::from_milliseconds(500)
  let start_time = audio_sound.start_time(audio_current_time)
  inspect(start_time.to_milliseconds(), content="500")
}

///|
test "AudioSound::start_time with negative offset" {
  let audio_sound = AudioSound::{
    offset: Duration::from_milliseconds(-200),
    duration: Duration::from_milliseconds(500),
    midi: MidiNumber::new(60).unwrap(),
  }
  let audio_current_time = Duration::from_milliseconds(1000)
  let start_time = audio_sound.start_time(audio_current_time)
  inspect(start_time.to_milliseconds(), content="800")
}

///|
test "AudioSound integration - from and start_time together" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [
    Note(midi~, duration=Quarter), // starts at 0ms
    Note(midi~, duration=Quarter), // starts at 500ms
    Note(midi~, duration=Quarter), // starts at 1000ms
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  // audio_sounds offsets: 0, 500, 1000
  let audio_current_time = Duration::from_seconds(5.0)
  // start_times should be: 5000ms, 5500ms, 6000ms
  inspect(
    audio_sounds[0].start_time(audio_current_time).to_milliseconds(),
    content="5000",
  )
  inspect(
    audio_sounds[1].start_time(audio_current_time).to_milliseconds(),
    content="5500",
  )
  inspect(
    audio_sounds[2].start_time(audio_current_time).to_milliseconds(),
    content="6000",
  )
}

///|
test "AudioSound::from extracts notes in lookahead range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds_list, position, lookahead)
  inspect(audio_sounds.length(), content="2")
  inspect(audio_sounds[0].midi.value, content="62")
  inspect(audio_sounds[0].offset.to_milliseconds(), content="0")
  inspect(audio_sounds[1].midi.value, content="64")
  inspect(audio_sounds[1].offset.to_milliseconds(), content="500")
}

///|
test "AudioSound::from excludes notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds_list, position, lookahead)
  inspect(audio_sounds.length(), content="2")
  inspect(audio_sounds[0].midi.value, content="62")
  inspect(audio_sounds[1].midi.value, content="64")
}

///|
test "AudioSound::from returns empty when all notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(1000)
  let lookahead = Duration::from_milliseconds(500)
  let audio_sounds = AudioSound::from(sounds_list, position, lookahead)
  inspect(audio_sounds.length(), content="0")
}

///|
test "AudioSound::from stops early when past window" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms
    Note(midi=MidiNumber::{ value: 67 }, duration=Quarter), // 2000ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds_list, position, lookahead)
  // Should only process first two notes and break early
  inspect(audio_sounds.length(), content="2")
  inspect(audio_sounds[0].midi.value, content="60")
  inspect(audio_sounds[1].midi.value, content="62")
}
