///|
/// Decide whether to generate a neighbor ornament at the current position.
/// Requires: at least 3 notes left in phrase, at least 1.5 beats remaining,
/// and probability check passes.
fn should_generate_neighbor_ornament(
  notes_left : Int,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> Bool {
  probability > 0 &&
  notes_left >= 3 &&
  remaining >= 1.5 - 0.001 &&
  random_int(100) < probability
}

///|
/// Select a neighbor MIDI note for the CT→N→CT ornament.
/// Prefers diatonic (scale tone) candidates; falls back to chromatic.
/// Excludes chord tones by pitch class. Stays within pitch_min/pitch_max.
fn select_neighbor_midi(
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  pitch_min : Int,
  pitch_max : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber {
  let chord_tone_pcs = chord.tones().map(fn(t) { t.pitch_class() })
  let scale_tone_pcs = chord.scale_tones().map(fn(t) { t.pitch_class() })
  let offsets = [-2, -1, 1, 2]
  // All valid MIDI neighbors within range
  let chromatic_candidates : Array[@music.MidiNumber] = offsets
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .filter(fn(m) { m.value >= pitch_min && m.value <= pitch_max })
    .collect()
  guard not(chromatic_candidates.is_empty()) else { return anchor_midi }
  // Exclude chord tones (they would defeat the ornament purpose)
  let non_chord_candidates : Array[@music.MidiNumber] = chromatic_candidates
    .iter()
    .filter(fn(m) { not(chord_tone_pcs.contains(m.pitch_class())) })
    .collect()
  let pool = if non_chord_candidates.is_empty() {
    chromatic_candidates
  } else {
    // Prefer diatonic (scale tone) candidates
    let diatonic : Array[@music.MidiNumber] = non_chord_candidates
      .iter()
      .filter(fn(m) { scale_tone_pcs.contains(m.pitch_class()) })
      .collect()
    if diatonic.is_empty() {
      non_chord_candidates
    } else {
      diatonic
    }
  }
  pool[random_int(pool.length())]
}

///|
/// Generate a CT→N→CT neighbor ornament (3 notes).
/// CT1: anchor chord tone, N: neighbor ±1-2 semitones, CT2: same anchor.
fn generate_neighbor_ornament(
  state : MeasureState,
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  remaining : Double,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let neighbor_midi = select_neighbor_midi(
    anchor_midi,
    chord,
    settings.pitch_min,
    settings.pitch_max,
    random_int,
  )

  // CT1 duration: leave at least 1.0 beats for N (0.5) + CT2 (0.5)
  let ct1_duration = match
    random_duration_within(
      remaining - 1.0,
      settings.note_duration_weights,
      random_int,
    ) {
    Some(d) => d
    None => @music.Eighth
  }
  let pos_after_ct1 = state.measure_pos + ct1_duration.to_beats()

  // CT2 duration: fill remaining space after N
  let ct2_remaining = remaining - ct1_duration.to_beats() - 0.5
  let ct2_duration = match
    random_duration_within(
      ct2_remaining,
      settings.note_duration_weights,
      random_int,
    ) {
    Some(d) => d
    None => @music.Eighth
  }

  // Emit CT1
  let beat_index1 = state.measure_pos.to_int()
  let cost1 = match state.last_midi {
    Some(prev) => interval_cost(prev, anchor_midi)
    None => 0
  }
  let stamina1 = @cmp.maximum(
    0,
    @cmp.minimum(
      state.stamina - cost1 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index1].push(@music.MeasureNote::{
    midi: Some(anchor_midi.value),
    duration: ct1_duration,
    accidental: update_accidental(anchor_midi),
    tie: None,
    tone_origin: Some(@music.ChordTone),
  })

  // Emit N
  let beat_index2 = pos_after_ct1.to_int()
  let cost2 = interval_cost(anchor_midi, neighbor_midi)
  let stamina2 = @cmp.maximum(
    0,
    @cmp.minimum(
      stamina1 - cost2 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index2].push(@music.MeasureNote::{
    midi: Some(neighbor_midi.value),
    duration: @music.Eighth,
    accidental: update_accidental(neighbor_midi),
    tie: None,
    tone_origin: Some(@music.NeighborTone),
  })

  // Emit CT2
  let pos_after_n = pos_after_ct1 + 0.5
  let beat_index3 = pos_after_n.to_int()
  let cost3 = interval_cost(neighbor_midi, anchor_midi)
  let stamina3 = @cmp.maximum(
    0,
    @cmp.minimum(
      stamina2 - cost3 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index3].push(@music.MeasureNote::{
    midi: Some(anchor_midi.value),
    duration: ct2_duration,
    accidental: update_accidental(anchor_midi),
    tie: None,
    tone_origin: Some(@music.ChordTone),
  })

  let remaining_notes = notes_left - 3
  let next_phrase = if remaining_notes <= 0 {
    Resting
  } else {
    Playing(remaining_notes)
  }
  MeasureState::{
    measure_pos: pos_after_n + ct2_duration.to_beats(),
    beat_notes: state.beat_notes,
    stamina: stamina3,
    last_midi: Some(anchor_midi),
    last_was_rest: false,
    phrase: next_phrase,
  }
}

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
  let state = MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    Playing(5),
  )
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
  let state = MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    Playing(5),
  )
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
  let state = MeasureState::new(
    4,
    50,
    Some(anchor_midi),
    Playing(3),
  )
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
    let state = MeasureState::new(
      4,
      50,
      Some(anchor_midi),
      Playing(5),
    )
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
    let is_non_chord = not(chord_tone_pcs.contains(neighbor_pc))
    assert_true(is_non_chord)
  }
}
