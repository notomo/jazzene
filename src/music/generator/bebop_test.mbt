///|
test "should_generate_bebop_ornament returns false when probability is 0" {
  let result = should_generate_bebop_ornament(5, 2.0, 0, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_bebop_ornament returns false when notes_left < 2" {
  let result = should_generate_bebop_ornament(1, 2.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_bebop_ornament returns false when remaining < 1.0 beat" {
  let result = should_generate_bebop_ornament(5, 0.5, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_bebop_ornament returns true when all conditions met" {
  let result = should_generate_bebop_ornament(5, 2.0, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "should_generate_bebop_ornament returns false when probability check fails" {
  // random_int returns 80, probability is 50 → 80 >= 50 → false
  let result = should_generate_bebop_ornament(5, 2.0, 50, fn(_) { 80 })
  assert_false(result)
}

///|
test "should_generate_bebop_ornament accepts exactly 1.0 beat remaining" {
  let result = should_generate_bebop_ornament(5, 1.0, 100, fn(_) { 0 })
  assert_true(result)
}

///|
// select_bebop_approach_midi: Dominant7

test "select_bebop_approach_midi - Dominant7 root returns major 7th (1 below)" {
  // G7: bebop PT = F# (interval 11). G root (MIDI 67): F# (66) is 1 below
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(67).unwrap() // G4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 66})") // F#4
}

///|
test "select_bebop_approach_midi - Dominant7 b7 returns major 7th (1 above)" {
  // G7: bebop PT = F# (interval 11). F b7 (MIDI 65): F# (66) is 1 above
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(65).unwrap() // F4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 66})") // F#4
}

///|
test "select_bebop_approach_midi - Dominant7 3rd returns None (not adjacent)" {
  // G7: bebop PT = F#. B 3rd (MIDI 71): F# is not ±1 → None
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(71).unwrap() // B4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="None")
}

///|
// select_bebop_approach_midi: Major7

test "select_bebop_approach_midi - Major7 5th returns sharp-5 (1 above)" {
  // Cmaj7: bebop PT = G# (interval 8). G 5th (MIDI 67): G# (68) is 1 above
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(67).unwrap() // G4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 68})") // G#4
}

///|
test "select_bebop_approach_midi - Major7 6th returns sharp-5 (1 below)" {
  // Cmaj7: bebop PT = G#. A 6th (MIDI 69): G# (68) is 1 below
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(69).unwrap() // A4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 68})") // G#4
}

///|
// select_bebop_approach_midi: Minor7

test "select_bebop_approach_midi - Minor7 b3 returns major 3rd (1 above)" {
  // Dm7: bebop PT = F# (interval 4). F b3 (MIDI 65): F# (66) is 1 above
  let chord = @music.Chord::{
    root: @music.D,
    quality: @music.Minor7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(65).unwrap() // F4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 66})") // F#4
}

///|
test "select_bebop_approach_midi - Minor7 4th returns major 3rd (1 below)" {
  // Dm7: bebop PT = F#. G 4th (MIDI 67): F# (66) is 1 below
  let chord = @music.Chord::{
    root: @music.D,
    quality: @music.Minor7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(67).unwrap() // G4
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 66})") // F#4
}

///|
// select_bebop_approach_midi: HalfDiminished

test "select_bebop_approach_midi - HalfDiminished b5 returns natural 5th (1 above)" {
  // Bm7b5: bebop PT = F# (interval 7). F b5 (MIDI 77): F# (78) is 1 above
  let chord = @music.Chord::{
    root: @music.B,
    quality: @music.HalfDiminished,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(77).unwrap() // F5
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="Some({value: 78})") // F#5
}

///|
test "select_bebop_approach_midi - chord with no bebop tones returns None" {
  // Diminished7 has no bebop passing tones defined
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Diminished7,
    bass: None,
  }
  let anchor = @music.MidiNumber::new(60).unwrap()
  let result = select_bebop_approach_midi(anchor, chord, 0, 127)
  inspect(result, content="None")
}

///|
// generate_bebop_ornament

test "generate_bebop_ornament produces exactly 2 notes" {
  let settings = ImprovisationConfig::default(42)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap() // G4 (root)
  let state = @generator.MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    @generator.Playing(5),
  )
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(0)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  assert_eq(all_notes.length(), 2)
}

///|
test "generate_bebop_ornament emits PT then CT with correct tone origins" {
  let settings = ImprovisationConfig::default(42)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap() // G4 (root)
  let state = @generator.MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    @generator.Playing(5),
  )
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(0)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  // PT: F#4 (66) with PassingTone origin
  assert_eq(all_notes[0].midi, Some(66)) // F#4
  inspect(all_notes[0].tone_origin, content="Some(PassingTone)")
  assert_eq(all_notes[0].duration, @music.Eighth)
  // CT: G4 (67) with ChordTone origin
  assert_eq(all_notes[1].midi, Some(67)) // G4
  inspect(all_notes[1].tone_origin, content="Some(ChordTone)")
}

///|
test "generate_bebop_ornament PT is ±1 semitone from anchor" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap() // G4
  let state = @generator.MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    @generator.Playing(5),
  )
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(0)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  let pt_val = all_notes[0].midi.unwrap()
  let dist = (pt_val - 67).abs()
  assert_eq(dist, 1)
}

///|
test "generate_bebop_ornament decrements notes_left by 2" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap()
  let state = @generator.MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    @generator.Playing(5),
  )
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(1)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  match result.phrase {
    @generator.Playing(n) => assert_eq(n, 3)
    @generator.Resting => fail("Expected Playing(3), got Resting")
  }
}

///|
test "generate_bebop_ornament transitions to Resting when notes_left <= 0" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap()
  let state = @generator.MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    @generator.Playing(2),
  )
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(2)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 2,
  )
  match result.phrase {
    @generator.Resting => ()
    @generator.Playing(n) => fail("Expected Resting, got Playing(\{n})")
  }
}

///|
test "generate_bebop_ornament last_midi is set to anchor after generation" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(67).unwrap() // G4
  let state = @generator.MeasureState::new(4, 50, None, @generator.Playing(5))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(0)
  let result = generate_bebop_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  inspect(result.last_midi, content="Some({value: 67})")
}
