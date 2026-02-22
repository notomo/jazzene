///|
test "in_range" {
  let midi = MidiNumber::{ value: 60 }
  let sound = ScheduledSound::{
    sound_event: Note(midi~, duration=Quarter),
    duration: Duration::from_milliseconds(500),
    start_time: Duration::from_milliseconds(0),
    tone_origin: None,
  }
  assert_false(sound.in_range(Duration::from_milliseconds(-1)))
  assert_true(sound.in_range(Duration::from_milliseconds(0)))
  assert_true(sound.in_range(Duration::from_milliseconds(499)))
  assert_false(sound.in_range(Duration::from_milliseconds(500)))
}

///|
test "calculate_playing_notes" {
  let midi = MidiNumber::{ value: 60 }
  let sounds = [
    ScheduledSound::{
      sound_event: Note(midi~, duration=Quarter),
      duration: Duration::from_milliseconds(500),
      start_time: Duration::from_milliseconds(0),
      tone_origin: None,
    },
  ]
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(-1)), [])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(0)), [
    sounds[0],
  ])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(500)), [])
}
