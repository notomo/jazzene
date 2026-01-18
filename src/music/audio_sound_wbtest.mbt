///|
test "AudioSound::from creates audio sounds" {
  let bpm = 120
  let midi = MidiNumber::{ value: 60 }
  let notes = [Note(midi~, duration=Quarter)] // 0-500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  assert_eq(audio_sounds.length(), 1)
  let audio_sound = audio_sounds[0]
  assert_eq(audio_sound.offset, Duration::from_milliseconds(0))
  assert_eq(audio_sound.midi, midi)
  assert_eq(audio_sound.duration, Duration::from_milliseconds(500))
}

///|
test "AudioSound::from filters out rests" {
  let bpm = 120
  let midi = MidiNumber::{ value: 60 }
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Rest(duration=Quarter), // 500-1000ms
    Note(midi~, duration=Quarter), // 1000-1500ms
    Note(midi~, duration=Quarter), // 1500-2000ms
  ]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let current_pos = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let audio_sounds = AudioSound::from(sounds, current_pos, lookahead)
  assert_eq(audio_sounds.length(), 2)
  assert_eq(audio_sounds[0].offset, Duration::from_milliseconds(0))
  assert_eq(audio_sounds[0].midi, midi)
  assert_eq(audio_sounds[1].offset, Duration::from_milliseconds(1000))
  assert_eq(audio_sounds[1].midi, midi)
}

///|
test "AudioSound::from extracts notes in lookahead range" {
  let note_values = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let bpm = 120
  let sounds = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let audio_sounds = AudioSound::from(sounds, position, lookahead)
  assert_eq(audio_sounds.length(), 2)
  assert_eq(audio_sounds[0].midi, MidiNumber::{ value: 62 })
  assert_eq(audio_sounds[1].midi, MidiNumber::{ value: 64 })
}

///|
let default_audio_sound : AudioSound = AudioSound::{
  offset: Duration::from_milliseconds(0),
  duration: Duration::from_milliseconds(100),
  midi: MidiNumber::new(60).unwrap(),
}

///|
test "AudioSound::start_time adds offset to audio_current_time" {
  let audio_sound = AudioSound::{
    ..default_audio_sound,
    offset: Duration::from_milliseconds(100),
  }
  let start_time = audio_sound.start_time(Duration::from_milliseconds(1000))
  assert_eq(start_time.to_milliseconds(), 1100.0)
}
