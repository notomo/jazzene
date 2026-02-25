///|
fn make_eighth(midi : Int) -> MeasureNote {
  MeasureNote::{
    midi: Some(midi),
    duration: Eighth,
    accidental: None,
    tie: None,
    tone_origin: None,
  }
}

///|
fn make_eighth_pair_measure(on_midi : Int, off_midi : Int, beat : Int) -> Beat {
  Beat::{ count: beat, notes: [make_eighth(on_midi), make_eighth(off_midi)] }
}

///|
fn assert_ms_near(
  actual : Duration,
  expected_ms : Double,
) -> Unit raise Failure {
  let epsilon = 0.5
  let actual_ms = actual.to_milliseconds()
  if (actual_ms - expected_ms).abs() > epsilon {
    fail("expected ~\{expected_ms}ms, got \{actual_ms}ms")
  }
}

///|
// Triplet swing at 120 BPM: beat = 500ms, swing_delay = 500/6 ≈ 83.33ms
// On-beat eighth  → 250 + 83.33 = 333.33ms (2/3 beat)
// Off-beat eighth → 250 - 83.33 = 166.67ms (1/3 beat)
test "convert_measures_to_sounds: triplet swing eighth pair has 2:1 ratio" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [make_eighth_pair_measure(60, 62, 0)],
  }
  let sounds = convert_measures_to_sounds(
    [measure],
    120,
    swing=SwingConfig::triplet(),
  )
  assert_eq(sounds.length(), 2)
  let beat_ms = 500.0
  assert_ms_near(sounds[0].duration, beat_ms * 2.0 / 3.0) // on-beat: 2/3 beat
  assert_ms_near(sounds[1].duration, beat_ms * 1.0 / 3.0) // off-beat: 1/3 beat
}

///|
// Off-beat note must end at exactly the next beat, preventing overlap
test "convert_measures_to_sounds: triplet swing notes tile without gap or overlap" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [make_eighth_pair_measure(60, 62, 0)],
  }
  let sounds = convert_measures_to_sounds(
    [measure],
    120,
    swing=SwingConfig::triplet(),
  )
  let on_end = sounds[0].start_time.to_milliseconds() +
    sounds[0].duration.to_milliseconds()
  let off_start = sounds[1].start_time.to_milliseconds()
  assert_ms_near(Duration::from_milliseconds(on_end), off_start) // no gap between on/off
  let off_end = sounds[1].start_time.to_milliseconds() +
    sounds[1].duration.to_milliseconds()
  assert_ms_near(Duration::from_milliseconds(off_end), 500.0) // off-beat ends at beat 2 (500ms)
}

///|
// Same pitch consecutive: off-beat must not reach into next on-beat note's start time
test "convert_measures_to_sounds: triplet swing same-pitch notes do not overlap" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      make_eighth_pair_measure(60, 60, 0), // beat 0: C then C
      make_eighth_pair_measure(60, 62, 1), // beat 1: C then D
    ],
  }
  let sounds = convert_measures_to_sounds(
    [measure],
    120,
    swing=SwingConfig::triplet(),
  )
  assert_eq(sounds.length(), 4)
  let off_beat_end = sounds[1].start_time.to_milliseconds() +
    sounds[1].duration.to_milliseconds()
  let next_on_start = sounds[2].start_time.to_milliseconds()
  assert_true(off_beat_end <= next_on_start)
}

///|
// Straight feel: all eighth notes keep equal (250ms) duration
test "convert_measures_to_sounds: straight swing preserves equal eighth durations" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [make_eighth_pair_measure(60, 62, 0)],
  }
  let sounds = convert_measures_to_sounds(
    [measure],
    120,
    swing=SwingConfig::straight(),
  )
  assert_eq(sounds.length(), 2)
  assert_ms_near(sounds[0].duration, 250.0)
  assert_ms_near(sounds[1].duration, 250.0)
}

///|
// On-beat note with no following off-beat: duration unchanged (no extension)
test "convert_measures_to_sounds: on-beat note not extended when next note is also on-beat" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 1,
        notes: [
          MeasureNote::{
            midi: Some(62),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
  }
  let sounds = convert_measures_to_sounds(
    [measure],
    120,
    swing=SwingConfig::triplet(),
  )
  assert_eq(sounds.length(), 2)
  assert_ms_near(sounds[0].duration, 500.0) // quarter note: no extension
  assert_ms_near(sounds[1].duration, 500.0)
}

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
