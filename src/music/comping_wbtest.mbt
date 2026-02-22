///|
fn make_3beat_measure(chords : Array[Chord], start_ms : Double) -> Measure {
  Measure::{
    chords,
    beats: [
      Beat::{ count: 0, notes: [] },
      Beat::{ count: 1, notes: [] },
      Beat::{ count: 2, notes: [] },
    ],
    start_time: Duration::from_milliseconds(start_ms),
  }
}

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
fn comping_midis(sounds : Array[NoteValueSound]) -> Array[Int] {
  sounds.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
}

///|
test "CompingPattern::from_measure_index cycles every 4 measures" {
  inspect(CompingPattern::from_measure_index(0), content="Standard")
  inspect(CompingPattern::from_measure_index(1), content="Dense")
  inspect(CompingPattern::from_measure_index(2), content="TwoFour")
  inspect(CompingPattern::from_measure_index(3), content="Sparse")
  // Cycles back
  inspect(CompingPattern::from_measure_index(4), content="Standard")
  inspect(CompingPattern::from_measure_index(7), content="Sparse")
}

///|
test "generate_comping_sounds: shell voicing for Cmaj7" {
  // shell_voicing(Cmaj7, None): 3rd=E4(64), 7th=B3(59)
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // Standard (mi=0): all 3 hits present (beat1 never omitted; and-of-2, beat4 survive at seed=0)
  // 2 tones × 3 hits = 6 sounds
  inspect(comping_midis(sounds), content="[64, 59, 64, 59, 64, 59]")
  // Beat positions are stable; durations have ±20% jitter so not checked exactly
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(1500.0))
  assert_eq(sounds[4].start_time, Duration::from_milliseconds(3000.0))
}

///|
test "generate_comping_sounds: shell voicing for G7" {
  // shell_voicing(G7, None): 3rd=B3(59), 7th=F4(65)
  // closest to C4(60): B3(59) is 1 away, F4(65) is 5 away
  let measures = [
    make_4beat_measure(
      [Chord::{ root: G, quality: Dominant7, bass: None }],
      0.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  inspect(comping_midis(sounds), content="[59, 65, 59, 65, 59, 65]")
}

///|
test "generate_comping_sounds: shell voicing for Fmaj7" {
  // shell_voicing(Fmaj7, None): 3rd=A3(57), 7th=E4(64)
  // closest to C4(60): A3(57) is 3 away, E4(64) is 4 away
  let measures = [
    make_4beat_measure([Chord::{ root: F, quality: Major7, bass: None }], 0.0),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  inspect(comping_midis(sounds), content="[57, 64, 57, 64, 57, 64]")
}

///|
test "generate_comping_sounds: shell voicing for Am7" {
  // shell_voicing(Am7, None): 3rd=C4(60), 7th=G3(55)
  // closest to C4(60): C4(60) is 0 away, G3(55) is 5 away
  let measures = [
    make_4beat_measure([Chord::{ root: A, quality: Minor7, bass: None }], 0.0),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  inspect(comping_midis(sounds), content="[60, 55, 60, 55, 60, 55]")
}

///|
test "generate_comping_sounds: triad uses 3rd and 5th" {
  // shell_voicing(C Major, None): 3rd=E4(64), 5th=G3(55)
  // closest to C4(60): E4(64) is 4 away, G3(55) is 5 away
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major, bass: None }], 0.0),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  inspect(comping_midis(sounds), content="[64, 55, 64, 55, 64, 55]")
}

///|
test "generate_comping_sounds: melody avoidance lowers overlapping guide tone" {
  // D root: base=D3(50), Minor7 intervals=[0,3,7,10]
  // 3-7 voicing: raw=F3(53), C4(60)
  // melody min=C4(60): F3(53)<60 stays; C4(60)>=60 → C3(48)
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(60, 0.0, 4000.0)]
  let sounds = generate_comping_sounds(measures, 60, melody)
  inspect(comping_midis(sounds), content="[53, 48, 53, 48, 53, 48]")
}

///|
test "generate_comping_sounds: melody near guide tone triggers octave shift" {
  // shell_voicing(Dm7, None): 3rd=F4(65), 7th=C4(60)
  // melody min=G4(67): F4(65) is only 2 semitones below → shifts to F3(53)
  //                    C4(60) is 7 semitones below → stays at C4(60)
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(67, 0.0, 4000.0)]
  let sounds = generate_comping_sounds(measures, 60, melody)
  inspect(comping_midis(sounds), content="[53, 60, 53, 60, 53, 60]")
}

///|
test "generate_comping_sounds: melody within 4 semitones triggers octave shift" {
  // D root Dm7: raw=F3(53), C4(60)
  // melody min=E4(64): gap(C4,E4)=4 < 5 → C4 shifts to C3(48); gap(F3,E4)=11 → stays
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(64, 0.0, 4000.0)]
  let sounds = generate_comping_sounds(measures, 60, melody)
  inspect(comping_midis(sounds), content="[53, 48, 53, 48, 53, 48]")
}

///|
test "generate_comping_sounds: melody outside chord time range does not affect" {
  // Dm7 at 0-4000ms; melody C4(60) starts at 4000ms (no overlap)
  // shell_voicing(Dm7, None): 3rd=F4(65), 7th=C4(60)
  let measures = [
    make_4beat_measure([Chord::{ root: D, quality: Minor7, bass: None }], 0.0),
  ]
  let melody = [make_melody_note(60, 4000.0, 4000.0)]
  let sounds = generate_comping_sounds(measures, 60, melody)
  // No melody overlap → shell voicing values used: F4(65), C4(60)
  inspect(comping_midis(sounds), content="[65, 60, 65, 60, 65, 60]")
}

///|
test "generate_comping_sounds: two chords split timing evenly" {
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
  let sounds = generate_comping_sounds(measures, 60, [])
  // Cmaj7 (i=0): 1 hit at beat 1 → 2 sounds
  // G7 (i=1, last): anticipated hit always present; and-of-2 may be omitted (seed=0 omits it)
  // total = 4 (2 per chord × 2 chords, and-of-2 omitted at seed=0)
  assert_eq(sounds.length(), 4)
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  // G7 anticipated: 2000ms - 500ms = 1500ms
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(1500.0))
  // Cmaj7: E4(64), B3(59) × 1 hit; G7 with smooth VL: B3(59), F3(53) × 1 hit (and-of-2 omitted)
  inspect(comping_midis(sounds), content="[64, 59, 59, 53]")
}

///|
test "generate_comping_sounds: measure start time is reflected in output" {
  // Measure starts at 8000ms
  let measures = [
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      8000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(8000.0))
}

///|
test "generate_comping_sounds: no chords produces no sounds" {
  let measures = [make_4beat_measure([], 0.0)]
  let sounds = generate_comping_sounds(measures, 60, [])
  assert_eq(sounds.length(), 0)
}

///|
test "generate_comping_sounds: Dense pattern (measure index 1)" {
  // BPM=60 → beat_duration_ms=1000ms; Cmaj7: E3(52), B3(59)
  // Dense hits at 4-beat chord: beat1(4000), and-2(5500), beat3(6000), and-4(7500)
  // → 4 hits × 2 tones = 8 sounds
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      4000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // Standard(6) + Dense(some hits omitted at seed=0) = 10
  assert_eq(sounds.length(), 10)
  // Dense beat1 (hi=0, never omitted) is at 4000ms
  assert_eq(sounds[6].start_time, Duration::from_milliseconds(4000.0))
}

///|
test "generate_comping_sounds: TwoFour pattern (measure index 2)" {
  // BPM=60; Cmaj7: E3(52), B3(59)
  // TwoFour hits at 4-beat chord: beat2(9000), beat4(11000) → 2 hits × 2 = 4 sounds
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      4000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      8000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // Standard(6) + Dense(4) + TwoFour(beat2 present, beat4 omitted at seed=0) = 12
  assert_eq(sounds.length(), 12)
  // TwoFour beat2 (hi=0, never omitted) is at chord_start + 1 beat = 9000ms
  assert_eq(sounds[10].start_time, Duration::from_milliseconds(9000.0))
  // After 3 consecutive Cmaj7 measures, voice leading keeps E4(64), B3(59)
  inspect(comping_midis(sounds[10:12].iter().collect()), content="[64, 59]")
}

///|
test "generate_comping_sounds: Sparse pattern (measure index 3)" {
  // BPM=60; Cmaj7: E3(52), B3(59)
  // Sparse: beat1 only → 1 hit × 2 = 2 sounds
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      4000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      8000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      12000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // Standard(6) + Dense(4) + TwoFour(2) + Sparse(2) = 14
  assert_eq(sounds.length(), 14)
  // Sparse beat1 (hi=0, never omitted) at 12000ms
  assert_eq(sounds[12].start_time, Duration::from_milliseconds(12000.0))
  assert_eq(sounds[13].start_time, Duration::from_milliseconds(12000.0))
}

///|
test "generate_comping_sounds: pattern cycles back at index 4" {
  // Index 4 mod 4 = 0 → Standard again; same hit count as index 0
  let measures = [
    make_4beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      4000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      8000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      12000.0,
    ),
    make_4beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      16000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // Standard(6) + Dense(4) + TwoFour(2) + Sparse(2) + Standard(6) = 20
  assert_eq(sounds.length(), 20)
  // mi=4 Standard: all 3 hits present at seed=0 (different rand_keys from mi=0)
  // beat1(16000), and-2(17500), beat4(19000); guide tones interleaved: 2 per hit
  assert_eq(sounds[14].start_time, Duration::from_milliseconds(16000.0))
  assert_eq(sounds[16].start_time, Duration::from_milliseconds(17500.0))
  assert_eq(sounds[18].start_time, Duration::from_milliseconds(19000.0))
}

///|
test "generate_comping_sounds: 3/4 Standard includes beat 3" {
  // BPM=60 → 1000ms/beat; 3/4 measure: beats_per_chord=3.0
  // Standard(mi=0): beat-1(0ms), and-of-2(1500ms), beat-3(2000ms) - all survive at seed=0
  // shell_voicing(Cmaj7, None): E4(64), B3(59) × 3 hits = 6 sounds
  let measures = [
    make_3beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  assert_eq(sounds.length(), 6)
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(1500.0))
  // beat-3 at 2000ms (NEW for 3/4; was missing before)
  assert_eq(sounds[4].start_time, Duration::from_milliseconds(2000.0))
  inspect(comping_midis(sounds), content="[64, 59, 64, 59, 64, 59]")
}

///|
test "generate_comping_sounds: 3/4 TwoFour beat-2 duration fits before beat-3" {
  // BPM=60; 3/4 TwoFour: beat-2 at 1000ms with duration 0.75 beats (not 1.5).
  // Max jitter=1.2 → beat-2 ends at 1000+750*1.2=1900ms < 2000ms (beat-3 start).
  // beat-3(hi=1) is omitted at seed=0 (rand_key=2019 < 0.25 threshold).
  let measures = [
    make_3beat_measure([Chord::{ root: C, quality: Major7, bass: None }], 0.0),
    make_3beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      3000.0,
    ),
    make_3beat_measure(
      [Chord::{ root: C, quality: Major7, bass: None }],
      6000.0,
    ),
  ]
  let sounds = generate_comping_sounds(measures, 60, [])
  // TwoFour beat-2 (hi=0) is always present; beat-3 (hi=1) omitted at seed=0
  let twofour_start = sounds
    .iter()
    .filter(fn(s) { s.start_time == Duration::from_milliseconds(7000.0) })
    .collect()
  assert_eq(twofour_start.length(), 2) // beat-2 only: 2 tones
  // Verify beat-2 duration doesn't reach beat-3 start (2000ms offset in measure)
  for s in twofour_start {
    let end_ms = s.start_time.to_milliseconds() + s.duration.to_milliseconds()
    assert_true(end_ms <= 8000.0) // must end before beat-3 at 6000+2000=8000ms
  }
}
