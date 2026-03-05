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
/// RootFifth produces one note per beat, alternating root and 5th
test "generate_walking_bass_sounds: RootFifth - root and fifth" {
  let measures = [make_4beat_bass_measure([make_cmaj7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, RootFifth)
  // 4/4 with 1 chord → 4 beats → 4 notes (one per beat)
  assert_eq(sounds.length(), 4)
  assert_eq(sounds[0].start_time, Duration::from_milliseconds(0.0))
  assert_eq(sounds[1].start_time, Duration::from_milliseconds(1000.0))
  assert_eq(sounds[2].start_time, Duration::from_milliseconds(2000.0))
  assert_eq(sounds[3].start_time, Duration::from_milliseconds(3000.0))
  // Alternates root(C) and 5th(G): C G C G
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C (root, beat_in_chord=0)
  assert_eq(sounds[1].midi().unwrap().pitch_class(), 7) // G (5th,  beat_in_chord=1)
  assert_eq(sounds[2].midi().unwrap().pitch_class(), 0) // C (root, beat_in_chord=2)
  assert_eq(sounds[3].midi().unwrap().pitch_class(), 7) // G (5th,  beat_in_chord=3)
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
fn make_3beat_bass_measure(chords : Array[Chord], start_ms : Double) -> Measure {
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
/// WalkingBass in 3/4 with 1 chord: root, 5th, approach
test "generate_walking_bass_sounds: WalkingBass - 3/4 one chord" {
  let measures = [
    make_3beat_bass_measure([make_cmaj7()], 0.0),
    make_3beat_bass_measure([make_g7()], 3000.0),
  ]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  // 3 beats × 2 measures = 6 notes
  assert_eq(sounds.length(), 6)
  // Measure 1: C(root), G(5th), F#(approach to G)
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C root
  assert_eq(sounds[1].midi().unwrap().pitch_class(), 7) // G 5th
  assert_eq(sounds[2].midi().unwrap().pitch_class(), 6) // F# approach to G
  // Measure 2 beat 1: root of G7 = G
  assert_eq(sounds[3].midi().unwrap().pitch_class(), 7) // G root
}

///|
/// WalkingBass in 3/4 with 2 chords: second chord root must appear on beat 3
test "generate_walking_bass_sounds: WalkingBass - 3/4 two chords" {
  // 2 chords in 3/4: Dm7 for beats 1-1.5, G7 for beats 1.5-3
  // beat 0 → Dm7 root, beat 1 → Dm7 5th, beat 2 → G7 root (NOT approach, it's chord start)
  let measures = [
    make_3beat_bass_measure([make_dm7(), make_g7()], 0.0),
    make_3beat_bass_measure([make_cmaj7()], 3000.0),
  ]
  let sounds = generate_walking_bass_sounds(measures, 60, WalkingBass)
  assert_eq(sounds.length(), 6)
  // Beat 1 (idx 0): root of Dm7 = D(2)
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 2) // D
  // Beat 3 (idx 2): first beat of G7 chord → root G(7), not approach
  assert_eq(sounds[2].midi().unwrap().pitch_class(), 7) // G root
}

///|
/// RootFifth in 3/4 with 1 chord: root, 5th, root (alternating per beat)
test "generate_walking_bass_sounds: RootFifth - 3/4 one chord" {
  let measures = [make_3beat_bass_measure([make_cmaj7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, RootFifth)
  // 3/4 with 1 chord → 3 beats → 3 notes
  assert_eq(sounds.length(), 3)
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 0) // C root  (beat_in_chord=0)
  assert_eq(sounds[1].midi().unwrap().pitch_class(), 7) // G 5th   (beat_in_chord=1)
  assert_eq(sounds[2].midi().unwrap().pitch_class(), 0) // C root  (beat_in_chord=2)
}

///|
/// RootFifth in 3/4 with 2 chords: each chord gets its beats correctly
test "generate_walking_bass_sounds: RootFifth - 3/4 two chords" {
  let measures = [make_3beat_bass_measure([make_dm7(), make_g7()], 0.0)]
  let sounds = generate_walking_bass_sounds(measures, 60, RootFifth)
  // 3 beats → 3 notes
  assert_eq(sounds.length(), 3)
  // beat 0: Dm7 root = D(2)
  assert_eq(sounds[0].midi().unwrap().pitch_class(), 2) // D
  // beat 2: G7 root = G(7) (beat_in_chord=0 for second chord)
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
