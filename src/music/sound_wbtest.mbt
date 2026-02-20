///|
fn make_4beat_measure(chords : Array[Chord], start_ms : Double) -> Measure {
  Measure::{
    chords,
    beats: [
      Beat::{ count: 0, notes: [] },
      Beat::{ count: 1, notes: [] },
      Beat::{ count: 2, notes: [] },
      Beat::{ count: 3, notes: [] },
    ],
    start_time: Duration::from_milliseconds(start_ms),
  }
}

///|
fn make_melody_note(
  midi_val : Int,
  start_ms : Double,
  dur_ms : Double,
) -> NoteValueSound {
  NoteValueSound::{
    note_value: Note(midi=MidiNumber::{ value: midi_val }, duration=Quarter),
    duration: Duration::from_milliseconds(dur_ms),
    start_time: Duration::from_milliseconds(start_ms),
  }
}

///|
fn backing_midis(sounds : Array[NoteValueSound]) -> Array[Int] {
  sounds.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
}

///|
test "convert_measures_to_backing_sounds: 3-7 voicing for non-F/G/A root (Cmaj7)" {
  // C root: base=C3(48), Major7 intervals=[0,4,7,11]
  // 3-7 voicing: intervals[1]=4 → E3(52), intervals[3]=11 → B3(59)
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  // 3 hits per guide tone (beat 1, and-of-2, beat 4): 2 tones × 3 hits = 6 sounds
  inspect(backing_midis(sounds), content="[52, 59, 52, 59, 52, 59]")
  // BPM=60 → beat_duration_ms=1000ms; duration=beat_duration_ms*0.5=500ms
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[0].duration, Duration::from_milliseconds(500.0))
}

///|
test "convert_measures_to_backing_sounds: 7-3 voicing for G root (G7)" {
  // G root: base=G3(55), Dominant7 intervals=[0,4,7,10]
  // 7-3 voicing: intervals[3]-12=-2 → F3(53), intervals[1]=4 → B3(59)
  let measures = [
    make_4beat_measure(
      [Chord::{ root: G, quality: Dominant7, bass: None }],
      0.0,
    ),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  inspect(backing_midis(sounds), content="[53, 59, 53, 59, 53, 59]")
}

///|
test "convert_measures_to_backing_sounds: 7-3 voicing for F root (Fmaj7)" {
  // F root: base=F3(53), Major7 intervals=[0,4,7,11]
  // 7-3 voicing: intervals[3]-12=-1 → E3(52), intervals[1]=4 → A3(57)
  let measures = [
    make_4beat_measure([Chord::{ root: F, quality: Major7, bass: None }], 0.0),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  inspect(backing_midis(sounds), content="[52, 57, 52, 57, 52, 57]")
}

///|
test "convert_measures_to_backing_sounds: 7-3 voicing for A root (Am7)" {
  // A root: base=A3(57), Minor7 intervals=[0,3,7,10]
  // 7-3 voicing: intervals[3]-12=-2 → G3(55), intervals[1]=3 → C4(60)
  let measures = [
    make_4beat_measure([Chord::{ root: A, quality: Minor7, bass: None }], 0.0),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  inspect(backing_midis(sounds), content="[55, 60, 55, 60, 55, 60]")
}

///|
test "convert_measures_to_backing_sounds: triad uses 3rd and 5th" {
  // C root: base=C3(48), Major intervals=[0,4,7]
  // intervals.length()=3: intervals[1]=4 → E3(52), intervals[2]=7 → G3(55)
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major, bass: None }], 0.0),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  inspect(backing_midis(sounds), content="[52, 55, 52, 55, 52, 55]")
}

///|
test "convert_measures_to_backing_sounds: melody avoidance lowers overlapping guide tone" {
  // D root: base=D3(50), Minor7 intervals=[0,3,7,10]
  // 3-7 voicing: raw=F3(53), C4(60)
  // melody min=C4(60): F3(53)<60 stays; C4(60)>=60 → C3(48)
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(60, 0.0, 4000.0)]
  let sounds = convert_measures_to_backing_sounds(measures, 60, melody)
  inspect(backing_midis(sounds), content="[53, 48, 53, 48, 53, 48]")
}

///|
test "convert_measures_to_backing_sounds: melody below guide tones causes no shift" {
  // D root Dm7: raw=F3(53), C4(60)
  // melody min=E4(64): both 53<64 and 60<64, no shift
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(64, 0.0, 4000.0)]
  let sounds = convert_measures_to_backing_sounds(measures, 60, melody)
  inspect(backing_midis(sounds), content="[53, 60, 53, 60, 53, 60]")
}

///|
test "convert_measures_to_backing_sounds: melody outside chord time range does not affect" {
  // Dm7 at 0-4000ms; melody C4(60) starts at 4000ms (no overlap)
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(60, 4000.0, 4000.0)]
  let sounds = convert_measures_to_backing_sounds(measures, 60, melody)
  // No melody overlap → raw values used: F3(53), C4(60)
  inspect(backing_midis(sounds), content="[53, 60, 53, 60, 53, 60]")
}

///|
test "convert_measures_to_backing_sounds: two chords split timing evenly" {
  // BPM=60, 4 beats, 2 chords → 2 beats=2000ms each
  let measures = [
    make_4beat_measure(
      [
        Chord::{ root: C, quality: Major7, bass: None },
        Chord::{ root: G, quality: Dominant7, bass: None },
      ],
      0.0,
    ),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  // Cmaj7 (i=0): 1 hit at beat 1 → 2 sounds
  // G7 (i=1, last): anticipated hit + "and of 2" → 2 hits → 4 sounds; total 6
  assert_eq(sounds.length(), 6)
  // Cmaj7 at beat 1 (0ms), duration = beat_duration_ms * 0.5 = 500ms
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[0].duration, Duration::from_milliseconds(500.0))
  // G7 anticipated: 2000ms - 500ms = 1500ms
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(1500.0))
  assert_eq(sounds[2].duration, Duration::from_milliseconds(500.0))
  // Cmaj7: E3(52), B3(59) × 1 hit; G7: F3(53), B3(59) × 2 hits each
  inspect(backing_midis(sounds), content="[52, 59, 53, 59, 53, 59]")
}

///|
test "convert_measures_to_backing_sounds: measure start time is reflected in output" {
  // Measure starts at 8000ms
  let measures = [
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      8000.0,
    ),
  ]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(8000.0))
}

///|
test "convert_measures_to_backing_sounds: no chords produces no sounds" {
  let measures = [make_4beat_measure([], 0.0)]
  let sounds = convert_measures_to_backing_sounds(measures, 60, [])
  assert_eq(sounds.length(), 0)
}

///|
test "in_range" {
  let midi = MidiNumber::{ value: 60 }
  let sound = NoteValueSound::{
    note_value: Note(midi~, duration=Quarter),
    duration: Duration::from_milliseconds(500),
    start_time: Duration::from_milliseconds(0),
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
    NoteValueSound::{
      note_value: Note(midi~, duration=Quarter),
      duration: Duration::from_milliseconds(500),
      start_time: Duration::from_milliseconds(0),
    },
  ]
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(-1)), [])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(0)), [
    sounds[0],
  ])
  assert_eq(calculate_playing_notes(sounds, Duration::from_milliseconds(500)), [])
}
