///|
fn make_cmaj7() -> Chord {
  Chord::{ root: C, quality: Major7, bass: None }
}

///|
fn make_g7() -> Chord {
  Chord::{ root: G, quality: Dominant7, bass: None }
}

///|
fn make_dm7() -> Chord {
  Chord::{ root: D, quality: Minor7, bass: None }
}

///|
fn make_4beat_bass_measure(chords : Array[Chord], start_ms : Double) -> Measure {
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
fn bass_midis(sounds : Array[ScheduledSound]) -> Array[Int] {
  sounds.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
}

///|
/// RootOnly produces exactly one note per chord, on beat 1
test "generate_walking_bass_sounds: RootOnly - one note per chord" {
  let measures = [
    make_4beat_bass_measure([make_cmaj7()], 0.0),
    make_4beat_bass_measure([make_g7()], 4000.0),
  ]
  let sounds = generate_walking_bass_sounds(measures, 60, RootOnly)
  assert_eq(sounds.length(), 2)
  // Roots at beat 1 of each measure
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[1].start_time, Duration::from_milliseconds(4000.0))
  // Pitch classes: C=0, G=7
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C
  assert_eq(sounds[1].midi().unwrap().pitch_class(), 7) // G
}

///|
/// RootFifth produces root on beat 1, 5th on beat 3 for 4/4
test "generate_walking_bass_sounds: RootFifth - root and fifth" {
  let measures = [make_4beat_bass_measure([make_cmaj7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, RootFifth)
  assert_eq(sounds.length(), 2)
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[1].start_time, Duration::from_milliseconds(2000.0)) // beat 3
  // C root and G 5th
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C
  assert_eq(sounds[1].midi().unwrap().pitch_class(), 7) // G (5th of Cmaj7)
}

///|
/// WalkingBass produces one note per beat in 4/4
test "generate_walking_bass_sounds: WalkingBass - one note per beat" {
  let measures = [make_4beat_bass_measure([make_cmaj7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  assert_eq(sounds.length(), 4)
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[1].start_time, Duration::from_milliseconds(1000.0))
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(2000.0))
  assert_eq(sounds[3].start_time, Duration::from_milliseconds(3000.0))
}

///|
/// WalkingBass beat 1 is always root of active chord
test "generate_walking_bass_sounds: WalkingBass - beat 1 is root" {
  let measures = [make_4beat_bass_measure([make_cmaj7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  // Beat 1 (idx 0) = root of Cmaj7 = C
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C
}

///|
/// WalkingBass last beat approaches next measure's root by half-step below
test "generate_walking_bass_sounds: WalkingBass - last beat approaches next root" {
  // Cmaj7 → G7: last beat should approach G (7) from F# (6)
  let measures = [
    make_4beat_bass_measure([make_cmaj7()], 0.0),
    make_4beat_bass_measure([make_g7()], 4000.0),
  ]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  // 4 notes per measure × 2 measures = 8 notes
  assert_eq(sounds.length(), 8)
  // Last beat of measure 1 (beat 4, index 3) should be F#(6) = half-step below G(7)
  assert_eq(sounds[3].midi().unwrap().pitch_class(), 6) // F# (approach to G)
  // Beat 1 of measure 2 = root of G7 = G
  assert_eq(sounds[4].midi().unwrap().pitch_class(), 7) // G
}

///|
/// All bass notes stay in comfortable bass range
test "generate_walking_bass_sounds: WalkingBass - notes in bass range" {
  let measures = [
    make_4beat_bass_measure([make_cmaj7()], 0.0),
    make_4beat_bass_measure([make_dm7()], 4000.0),
    make_4beat_bass_measure([make_g7()], 8000.0),
  ]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  for s in sounds {
    match s.midi() {
      Some(m) => {
        assert_true(m.value >= 28) // >= E1
        assert_true(m.value <= 52) // <= E3
      }
      None => ()
    }
  }
}

///|
/// WalkingBass two chords per measure - each chord gets its beats
test "generate_walking_bass_sounds: WalkingBass - two chords per measure" {
  // 2 chords in 4/4: each gets 2 beats
  let measures = [make_4beat_bass_measure([make_dm7(), make_g7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  assert_eq(sounds.length(), 4)
  // Beat 1: root of Dm7 = D(2)
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 2) // D
  // Beat 3: root of G7 = G(7)
  assert_eq(sounds[2].midi().unwrap().pitch_class(), 7) // G
}

///|
/// Empty measures produce no sounds
test "generate_walking_bass_sounds: empty measures produce no sounds" {
  let measure = Measure::{
    chords: [],
    beats: [Beat::{ count: 0, notes: [] }, Beat::{ count: 1, notes: [] }],
    start_time: Duration::from_milliseconds(0.0),
  }
  let sounds = generate_walking_bass_sounds([measure], 60, WalkingBass)
  assert_eq(sounds.length(), 0)
}
