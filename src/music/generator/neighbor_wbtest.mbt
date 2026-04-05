///|
test "should_generate_neighbor_ornament returns false when probability is 0" {
  let result = should_generate_neighbor_ornament(5, 2.0, 0, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_neighbor_ornament returns false when notes_left < 3" {
  let result = should_generate_neighbor_ornament(2, 2.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_neighbor_ornament returns false when remaining < 1.5 beats" {
  let result = should_generate_neighbor_ornament(5, 1.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_neighbor_ornament returns true when all conditions met" {
  let result = should_generate_neighbor_ornament(5, 2.0, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "should_generate_neighbor_ornament returns false when probability check fails" {
  // random_int returns 99, probability is 50 → 99 >= 50 → false
  let result = should_generate_neighbor_ornament(5, 2.0, 50, fn(_) { 99 })
  assert_false(result)
}

///|
test "should_generate_neighbor_ornament accepts exactly 1.5 beats remaining" {
  let result = should_generate_neighbor_ornament(5, 1.5, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "generate_neighbor_ornament produces exactly 3 notes with correct tone origins" {
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
  let result = generate_neighbor_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  // Collect all notes from beat_notes
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  assert_eq(all_notes.length(), 3)
  // First note: ChordTone
  inspect(all_notes[0].tone_origin, content="Some(ChordTone)")
  assert_eq(all_notes[0].midi, Some(60))
  // Second note: NeighborTone
  inspect(all_notes[1].tone_origin, content="Some(NeighborTone)")
  // Neighbor must be ±1 or ±2 from anchor
  let neighbor_val = all_notes[1].midi.unwrap()
  let dist = (neighbor_val - 60).abs()
  assert_true(dist >= 1 && dist <= 2)
  // Third note: ChordTone (same anchor)
  inspect(all_notes[2].tone_origin, content="Some(ChordTone)")
  assert_eq(all_notes[2].midi, Some(60))
}

///|
test "generate_neighbor_ornament decrements notes_left by 3" {
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
  let result = generate_neighbor_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  // notes_left was 5, should now be Playing(2)
  match result.phrase {
    Playing(n) => assert_eq(n, 2)
    Resting => fail("Expected Playing(2), got Resting")
  }
}

///|
test "generate_neighbor_ornament transitions to Resting when notes_left becomes <= 0" {
  let settings = ImprovisationConfig::default(0)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap()
  let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(3))
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let rng = create_random_int(2)
  let result = generate_neighbor_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 3,
  )
  // notes_left was 3, after -3 = 0 → Resting
  match result.phrase {
    Resting => ()
    Playing(n) => fail("Expected Resting, got Playing(\{n})")
  }
}

///|
test "generate_neighbor_ornament neighbor is not a chord tone pitch class" {
  let settings = ImprovisationConfig::default(7)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  // C major 7 chord tones: C(0), E(4), G(7), B(11) by pitch class
  let anchor_midi = @music.MidiNumber::new(60).unwrap() // C4
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  // Run multiple seeds and verify neighbor is never a chord tone pitch class
  let chord_tone_pcs = [0, 4, 7, 11] // C, E, G, B
  for seed in 0..<20 {
    // Create a fresh state per iteration (beat_notes is mutated in place)
    let state = MeasureState::new(4, 50, Some(anchor_midi), Playing(5))
    let rng = create_random_int(seed)
    let result = generate_neighbor_ornament(
      state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
    )
    let all_notes : Array[@music.MeasureNote] = result.beat_notes
      .iter()
      .flat_map(fn(notes) { notes.iter() })
      .collect()
    let neighbor_val = all_notes[1].midi.unwrap()
    let neighbor_pc = neighbor_val % 12
    // Neighbor should not be a chord tone pitch class (when alternatives exist)
    // For C4 (±1,±2) = B3(11), Db4(1), D4(2), Eb4(3) — B(11) is chord tone,
    // but Db(1), D(2), Eb(3) are not, so neighbor should be one of those
    let is_non_chord = !chord_tone_pcs.contains(neighbor_pc)
    assert_true(is_non_chord)
  }
}
