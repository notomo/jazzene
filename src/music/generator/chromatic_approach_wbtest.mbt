///|
test "should_generate_chromatic_approach_ornament returns false when probability is 0" {
  let result = should_generate_chromatic_approach_ornament(5, 2.0, 0, fn(_) {
    0
  })
  assert_false(result)
}

///|
test "should_generate_chromatic_approach_ornament returns false when notes_left < 2" {
  let result = should_generate_chromatic_approach_ornament(1, 2.0, 100, fn(_) {
    0
  })
  assert_false(result)
}

///|
test "should_generate_chromatic_approach_ornament returns false when remaining < 1.0 beat" {
  let result = should_generate_chromatic_approach_ornament(5, 0.5, 100, fn(_) {
    0
  })
  assert_false(result)
}

///|
test "should_generate_chromatic_approach_ornament returns true when all conditions met" {
  let result = should_generate_chromatic_approach_ornament(5, 2.0, 100, fn(_) {
    0
  })
  assert_true(result)
}

///|
test "should_generate_chromatic_approach_ornament returns false when probability check fails" {
  // random_int returns 80, probability is 50 → 80 >= 50 → false
  let result = should_generate_chromatic_approach_ornament(5, 2.0, 50, fn(_) {
    80
  })
  assert_false(result)
}

///|
test "should_generate_chromatic_approach_ornament accepts exactly 1.0 beat remaining" {
  let result = should_generate_chromatic_approach_ornament(5, 1.0, 100, fn(_) {
    0
  })
  assert_true(result)
}

///|
test "select_chromatic_approach_midi returns non-chord tone when available" {
  // C major7 chord: C(0), E(4), G(7), B(11)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap() // C4
  // +1 = Db(1) not chord tone, -1 = B(11) IS chord tone → must pick Db
  for seed in 0..<20 {
    let rng = create_random_int(seed)
    let result = select_chromatic_approach_midi(anchor_midi, chord, 0, 127, rng)
    let pc = result.value % 12
    // B(11) is chord tone, Db(1) is not — must not select B
    assert_true(pc != 11)
  }
}

///|
test "select_chromatic_approach_midi result is ±1 semitone from anchor" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  for anchor_val in [60, 64, 67, 71] {
    let anchor_midi = @music.MidiNumber::new(anchor_val).unwrap()
    for seed in 0..<10 {
      let rng = create_random_int(seed)
      let result = select_chromatic_approach_midi(anchor_midi, chord, 0, 127, rng)
      let dist = (result.value - anchor_val).abs()
      assert_eq(dist, 1)
    }
  }
}

///|
test "generate_chromatic_approach_ornament produces exactly 2 notes with correct tone origins" {
  let settings = ImprovisationConfig::default(42)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap() // C4
  let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(5))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(0)
  let result = generate_chromatic_approach_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  assert_eq(all_notes.length(), 2)
  // First note: approach tone (ChromaticApproach)
  inspect(all_notes[0].tone_origin, content="Some(ChromaticApproach)")
  // Second note: chord tone (ChordTone)
  inspect(all_notes[1].tone_origin, content="Some(ChordTone)")
  assert_eq(all_notes[1].midi, Some(60))
}

///|
test "generate_chromatic_approach_ornament AT is Eighth duration" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap()
  let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(5))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(1)
  let result = generate_chromatic_approach_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  inspect(all_notes[0].duration, content="Eighth")
}

///|
test "generate_chromatic_approach_ornament decrements notes_left by 2" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap()
  let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(5))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(2)
  let result = generate_chromatic_approach_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  match result.phrase {
    Playing(n) => assert_eq(n, 3)
    Resting => fail("Expected Playing(3), got Resting")
  }
}

///|
test "generate_chromatic_approach_ornament transitions to Resting when notes_left becomes <= 0" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap()
  let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(2))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(3)
  let result = generate_chromatic_approach_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 2,
  )
  match result.phrase {
    Resting => ()
    Playing(n) => fail("Expected Resting, got Playing(\{n})")
  }
}
