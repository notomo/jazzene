///|
/// Decide whether to generate an enclosure ornament at the current position.
/// Requires: at least 3 notes left in phrase, at least 1.5 beats remaining,
/// and probability check passes.
fn should_generate_enclosure_ornament(
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
/// Select upper and lower enclosure MIDI notes for the EN→EN→CT ornament.
/// upper: +1 or +2 semitones from anchor (chord tones excluded when possible)
/// lower: -1 or -2 semitones from anchor (chord tones excluded when possible)
/// Stays within pitch_min/pitch_max; falls back to anchor if no candidates fit.
fn select_enclosure_midis(
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  pitch_min : Int,
  pitch_max : Int,
  random_int : (Int) -> Int,
) -> (@music.MidiNumber, @music.MidiNumber) {
  let chord_tone_pcs = chord.tones().map(fn(t) { t.pitch_class() })
  let in_range = fn(m : @music.MidiNumber) {
    m.value >= pitch_min && m.value <= pitch_max
  }

  // Upper candidates: +1, +2 semitones
  let upper_all : Array[@music.MidiNumber] = [1, 2]
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .filter(in_range)
    .collect()
  let upper_pool = if upper_all.is_empty() {
    [anchor_midi]
  } else {
    let upper_non_chord : Array[@music.MidiNumber] = upper_all
      .iter()
      .filter(fn(m) { not(chord_tone_pcs.contains(m.pitch_class())) })
      .collect()
    if upper_non_chord.is_empty() {
      upper_all
    } else {
      upper_non_chord
    }
  }

  // Lower candidates: -1, -2 semitones
  let lower_all : Array[@music.MidiNumber] = [-1, -2]
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .filter(in_range)
    .collect()
  let lower_pool = if lower_all.is_empty() {
    [anchor_midi]
  } else {
    let lower_non_chord : Array[@music.MidiNumber] = lower_all
      .iter()
      .filter(fn(m) { not(chord_tone_pcs.contains(m.pitch_class())) })
      .collect()
    if lower_non_chord.is_empty() {
      lower_all
    } else {
      lower_non_chord
    }
  }

  (
    upper_pool[random_int(upper_pool.length())],
    lower_pool[random_int(lower_pool.length())],
  )
}

///|
/// Generate an EN→EN→CT enclosure ornament (3 notes).
/// Randomly selects above-first or below-first ordering.
/// EN1: Eighth (0.5 beats), EN2: Eighth (0.5 beats), CT: remaining duration.
fn generate_enclosure_ornament(
  state : MeasureState,
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  remaining : Double,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let (upper_midi, lower_midi) = select_enclosure_midis(
    anchor_midi,
    chord,
    settings.pitch_min,
    settings.pitch_max,
    random_int,
  )

  // Randomly choose above-first or below-first
  let (en1_midi, en2_midi) = if random_int(2) == 0 {
    (upper_midi, lower_midi)
  } else {
    (lower_midi, upper_midi)
  }

  let pos_after_en1 = state.measure_pos + 0.5
  let pos_after_en2 = pos_after_en1 + 0.5

  // CT duration: fill remaining space after EN1 (0.5) + EN2 (0.5)
  let ct_remaining = remaining - 1.0
  let ct_duration = match
    random_duration_within(
      ct_remaining,
      settings.note_duration_weights,
      random_int,
    ) {
    Some(d) => d
    None => @music.Eighth
  }

  // Emit EN1
  let beat_index1 = state.measure_pos.to_int()
  let cost1 = match state.last_midi {
    Some(prev) => interval_cost(prev, en1_midi)
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
    midi: Some(en1_midi.value),
    duration: @music.Eighth,
    accidental: update_accidental(en1_midi),
    tie: None,
    tone_origin: Some(@music.Enclosure),
  })

  // Emit EN2
  let beat_index2 = pos_after_en1.to_int()
  let cost2 = interval_cost(en1_midi, en2_midi)
  let stamina2 = @cmp.maximum(
    0,
    @cmp.minimum(
      stamina1 - cost2 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index2].push(@music.MeasureNote::{
    midi: Some(en2_midi.value),
    duration: @music.Eighth,
    accidental: update_accidental(en2_midi),
    tie: None,
    tone_origin: Some(@music.Enclosure),
  })

  // Emit CT
  let beat_index3 = pos_after_en2.to_int()
  let cost3 = interval_cost(en2_midi, anchor_midi)
  let stamina3 = @cmp.maximum(
    0,
    @cmp.minimum(
      stamina2 - cost3 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index3].push(@music.MeasureNote::{
    midi: Some(anchor_midi.value),
    duration: ct_duration,
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
    measure_pos: pos_after_en2 + ct_duration.to_beats(),
    beat_notes: state.beat_notes,
    stamina: stamina3,
    last_midi: Some(anchor_midi),
    last_was_rest: false,
    phrase: next_phrase,
  }
}

///|
/// Verify ImprovisationConfig has enclosure_ornament_probability field with default 20
test "ImprovisationConfig::default has enclosure_ornament_probability" {
  let s = ImprovisationConfig::default(0)
  assert_true(s.enclosure_ornament_probability > 0)
  assert_eq(s.enclosure_ornament_probability, 20)
}

///|
/// Verify Techniques has enclosure flag enabled by default
test "@music.Techniques::default has enclosure enabled" {
  let t = @music.Techniques::default()
  assert_true(t.enclosure)
}

///|
/// Verify ImprovisationConfig::with_techniques zeros enclosure when disabled
test "ImprovisationConfig::with_techniques zeros enclosure when disabled" {
  let s = ImprovisationConfig::default(0)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    enclosure: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.enclosure_ornament_probability, 0)
}

///|
/// Verify generated notes can have Enclosure origin from the ornament
test "generated notes can include Enclosure origin" {
  let settings = ImprovisationConfig::default(7)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let generator = create_measure_generator(settings)
  let ctx = MeasureContext::{
    chords: create_chord_segments([chord], 4.0),
    incoming_tie: None,
    key: @music.KeySignature::c_major(),
    time_signature: @music.TimeSignature::default(),
    beats_per_measure: 4.0,
    incoming_stamina: 50,
    incoming_last_midi: None,
    incoming_phrase: None,
  }
  // Generate many measures and check that origins are always valid
  for _ in 0..<5 {
    let result = generator(ctx)
    for beat in result.beats {
      for note in beat.notes {
        match (note.midi, note.tone_origin) {
          (Some(_), Some(_)) => () // note with origin
          (None, None) => () // rest
          (Some(_), None) => fail("Note missing tone_origin")
          (None, Some(_)) => fail("Rest has unexpected tone_origin")
        }
      }
    }
  }
}

///|
test "should_generate_enclosure_ornament returns false when probability is 0" {
  let result = should_generate_enclosure_ornament(5, 2.0, 0, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_enclosure_ornament returns false when notes_left < 3" {
  let result = should_generate_enclosure_ornament(2, 2.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_enclosure_ornament returns false when remaining < 1.5 beats" {
  let result = should_generate_enclosure_ornament(5, 1.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_enclosure_ornament returns true when all conditions met" {
  let result = should_generate_enclosure_ornament(5, 2.0, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "should_generate_enclosure_ornament returns false when probability check fails" {
  // random_int returns 99, probability is 50 → 99 >= 50 → false
  let result = should_generate_enclosure_ornament(5, 2.0, 50, fn(_) { 99 })
  assert_false(result)
}

///|
test "should_generate_enclosure_ornament accepts exactly 1.5 beats remaining" {
  let result = should_generate_enclosure_ornament(5, 1.5, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "generate_enclosure_ornament produces exactly 3 notes with correct tone origins" {
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
  let result = generate_enclosure_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  // Collect all notes from beat_notes
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  assert_eq(all_notes.length(), 3)
  // First note: Enclosure
  inspect(all_notes[0].tone_origin, content="Some(Enclosure)")
  // Second note: Enclosure
  inspect(all_notes[1].tone_origin, content="Some(Enclosure)")
  // Third note: ChordTone (the resolved anchor)
  inspect(all_notes[2].tone_origin, content="Some(ChordTone)")
  assert_eq(all_notes[2].midi, Some(60))
}

///|
test "generate_enclosure_ornament decrements notes_left by 3" {
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
  let result = generate_enclosure_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  // notes_left was 5, should now be Playing(2)
  match result.phrase {
    Playing(n) => assert_eq(n, 2)
    Resting => fail("Expected Playing(2), got Resting")
  }
}

///|
test "generate_enclosure_ornament transitions to Resting when notes_left becomes <= 0" {
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
  let result = generate_enclosure_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 3,
  )
  // notes_left was 3, after -3 = 0 → Resting
  match result.phrase {
    Resting => ()
    Playing(n) => fail("Expected Resting, got Playing(\{n})")
  }
}

///|
test "generate_enclosure_ornament EN notes surround anchor by 1-2 semitones" {
  let settings = ImprovisationConfig::default(7)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let anchor_midi = @music.MidiNumber::new(60).unwrap() // C4
  let update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  for seed in 0..<20 {
    let state = MeasureState::new(
      4,
      50,
      Some(anchor_midi),
      Playing(5),
    )
    let rng = create_random_int(seed)
    let result = generate_enclosure_ornament(
      state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
    )
    let all_notes : Array[@music.MeasureNote] = result.beat_notes
      .iter()
      .flat_map(fn(notes) { notes.iter() })
      .collect()
    let en1_val = all_notes[0].midi.unwrap()
    let en2_val = all_notes[1].midi.unwrap()
    // Both EN notes must be within 1-2 semitones of anchor
    let dist1 = (en1_val - 60).abs()
    let dist2 = (en2_val - 60).abs()
    assert_true(dist1 >= 1 && dist1 <= 2)
    assert_true(dist2 >= 1 && dist2 <= 2)
    // EN1 and EN2 must be on opposite sides of the anchor
    let en1_above = en1_val > 60
    let en2_above = en2_val > 60
    assert_true(en1_above != en2_above)
  }
}

///|
test "select_enclosure_midis excludes chord tones when alternatives exist" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  // C major 7 chord tones: C(0), E(4), G(7), B(11) by pitch class
  let anchor_midi = @music.MidiNumber::new(60).unwrap() // C4
  // anchor+1 = Db(1) not chord tone, anchor+2 = D(2) not chord tone
  // anchor-1 = B(11) IS chord tone, anchor-2 = Bb(10) not chord tone
  let chord_tone_pcs = [0, 4, 7, 11]
  for seed in 0..<20 {
    let rng = create_random_int(seed)
    let (upper, lower) = select_enclosure_midis(anchor_midi, chord, 0, 127, rng)
    let upper_pc = upper.value % 12
    let lower_pc = lower.value % 12
    // Upper (+1 or +2): Db(1) and D(2) are not chord tones → must be non-chord
    assert_true(not(chord_tone_pcs.contains(upper_pc)))
    // Lower (-1 = B(11) is chord tone, -2 = Bb(10) is not) → falls back to Bb
    assert_true(not(chord_tone_pcs.contains(lower_pc)))
  }
}

///|
test "generate_enclosure_ornament EN notes are Eighth duration" {
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
  let rng = create_random_int(3)
  let result = generate_enclosure_ornament(
    state, anchor_midi, chord, 2.0, settings, update_accidental, rng, 5,
  )
  let all_notes : Array[@music.MeasureNote] = result.beat_notes
    .iter()
    .flat_map(fn(notes) { notes.iter() })
    .collect()
  // EN1 and EN2 must be Eighth notes (0.5 beats each)
  inspect(all_notes[0].duration, content="Eighth")
  inspect(all_notes[1].duration, content="Eighth")
}
