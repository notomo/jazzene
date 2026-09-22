///|
test "AudioSound::from creates audio sounds" {
  let midi = @music.MidiNumber::new(60).unwrap()
  let sounds = [
    @music.ScheduledSound::{
      sound_event: Note(midi~, duration=Quarter),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(0),
      tone_origin: None,
      beat_position: 0.0,
    },
  ]
  let current_pos = @music.Duration::from_milliseconds(0)
  let lookahead = @music.Duration::from_milliseconds(1000)
  let audio_sounds = @music.AudioSound::from(sounds, current_pos, lookahead)
  assert_eq(audio_sounds.length(), 1)
  let audio_sound = audio_sounds[0]
  assert_eq(audio_sound.offset, @music.Duration::from_milliseconds(0))
  assert_eq(audio_sound.midi, midi)
  assert_eq(audio_sound.duration, @music.Duration::from_milliseconds(500))
  assert_eq(audio_sound.volume, 0.85) // None tone_origin → default intensity
}

///|
test "AudioSound::from filters out rests" {
  let midi = @music.MidiNumber::new(60).unwrap()
  let sounds = [
    @music.ScheduledSound::{
      sound_event: Note(midi~, duration=Quarter),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(0),
      tone_origin: None,
      beat_position: 0.0,
    },
    @music.ScheduledSound::{
      sound_event: Rest(duration=Quarter),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(500),
      tone_origin: None,
      beat_position: 0.0,
    },
    @music.ScheduledSound::{
      sound_event: Note(midi~, duration=Quarter),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(1000),
      tone_origin: None,
      beat_position: 0.0,
    },
    @music.ScheduledSound::{
      sound_event: Note(midi~, duration=Quarter),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(1500),
      tone_origin: None,
      beat_position: 0.0,
    },
  ]
  let current_pos = @music.Duration::from_milliseconds(0)
  let lookahead = @music.Duration::from_milliseconds(1500)
  let audio_sounds = @music.AudioSound::from(sounds, current_pos, lookahead)
  assert_eq(audio_sounds.length(), 2)
  assert_eq(audio_sounds[0].offset, @music.Duration::from_milliseconds(0))
  assert_eq(audio_sounds[0].midi, midi)
  assert_eq(audio_sounds[1].offset, @music.Duration::from_milliseconds(1000))
  assert_eq(audio_sounds[1].midi, midi)
}

///|
test "AudioSound::from extracts notes in lookahead range" {
  let sounds = [
    @music.ScheduledSound::{
      sound_event: Note(
        midi=@music.MidiNumber::new(60).unwrap(),
        duration=Quarter,
      ),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(0),
      tone_origin: None,
      beat_position: 0.0,
    },
    @music.ScheduledSound::{
      sound_event: Note(
        midi=@music.MidiNumber::new(62).unwrap(),
        duration=Quarter,
      ),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(500),
      tone_origin: None,
      beat_position: 0.0,
    },
    @music.ScheduledSound::{
      sound_event: Note(
        midi=@music.MidiNumber::new(64).unwrap(),
        duration=Quarter,
      ),
      duration: @music.Duration::from_milliseconds(500),
      start_time: @music.Duration::from_milliseconds(1000),
      tone_origin: None,
      beat_position: 0.0,
    },
  ]
  let position = @music.Duration::from_milliseconds(500)
  let lookahead = @music.Duration::from_milliseconds(1000)
  let audio_sounds = @music.AudioSound::from(sounds, position, lookahead)
  assert_eq(audio_sounds.length(), 2)
  assert_eq(audio_sounds[0].midi, @music.MidiNumber::new(62).unwrap())
  assert_eq(audio_sounds[1].midi, @music.MidiNumber::new(64).unwrap())
}

///|
let default_audio_sound : @music.AudioSound = @music.AudioSound::{
  offset: @music.Duration::from_milliseconds(0),
  duration: @music.Duration::from_milliseconds(100),
  midi: @music.MidiNumber::new(60).unwrap(),
  volume: 0.85,
}

///|
test "AudioSound::start_time adds offset to audio_current_time" {
  let audio_sound = @music.AudioSound::{
    ..default_audio_sound,
    offset: @music.Duration::from_milliseconds(100),
  }
  let start_time = audio_sound.start_time(
    @music.Duration::from_milliseconds(1000),
  )
  assert_eq(start_time.to_milliseconds(), 1100.0)
}
