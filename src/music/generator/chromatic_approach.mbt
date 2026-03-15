///|
/// Decide whether to generate a chromatic approach ornament at the current position.
/// Requires: at least 2 notes left in phrase, at least 1.0 beats remaining,
/// and probability check passes.
pub fn should_generate_chromatic_approach_ornament(
  notes_left : Int,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> Bool {
  probability > 0 &&
  notes_left >= 2 &&
  remaining >= 1.0 - 0.001 &&
  random_int(100) < probability
}

///|
/// Select a chromatic approach MIDI note (±1 semitone) for the AT→CT ornament.
/// Prefers notes that are not chord tones; falls back to any ±1 neighbor.
/// Stays within pitch_min/pitch_max.
pub fn select_chromatic_approach_midi(
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  pitch_min : Int,
  pitch_max : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber {
  let chord_tone_pcs = chord.tones().map(fn(t) { t.pitch_class() })
  let all_candidates : Array[@music.MidiNumber] = [-1, 1]
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .filter(fn(m) { m.value >= pitch_min && m.value <= pitch_max })
    .collect()
  guard not(all_candidates.is_empty()) else { return anchor_midi }
  let non_chord_candidates : Array[@music.MidiNumber] = all_candidates
    .iter()
    .filter(fn(m) { not(chord_tone_pcs.contains(m.pitch_class())) })
    .collect()
  let pool = if non_chord_candidates.is_empty() {
    all_candidates
  } else {
    non_chord_candidates
  }
  pool[random_int(pool.length())]
}

///|
/// Generate an AT→CT chromatic approach ornament (2 notes).
/// AT: approach tone (Eighth, 0.5 beats), CT: anchor chord tone (remaining duration).
pub fn generate_chromatic_approach_ornament(
  state : MeasureState,
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  remaining : Double,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let at_midi = select_chromatic_approach_midi(
    anchor_midi,
    chord,
    settings.pitch_min,
    settings.pitch_max,
    random_int,
  )
  let pos_after_at = state.measure_pos + 0.5

  // CT duration: fill remaining space after AT (0.5)
  let ct_remaining = remaining - 0.5
  let ct_duration = match
    random_duration_within(
      ct_remaining,
      settings.note_duration_weights,
      random_int,
    ) {
    Some(d) => d
    None => @music.Eighth
  }

  // Emit AT
  let beat_index1 = state.measure_pos.to_int()
  let cost1 = match state.last_midi {
    Some(prev) => interval_cost(prev, at_midi)
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
    midi: Some(at_midi.value),
    duration: @music.Eighth,
    accidental: update_accidental(at_midi),
    tie: None,
    tone_origin: Some(@music.ChromaticApproach),
  })

  // Emit CT
  let beat_index2 = pos_after_at.to_int()
  let cost2 = interval_cost(at_midi, anchor_midi)
  let stamina2 = @cmp.maximum(
    0,
    @cmp.minimum(
      stamina1 - cost2 + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  state.beat_notes[beat_index2].push(@music.MeasureNote::{
    midi: Some(anchor_midi.value),
    duration: ct_duration,
    accidental: update_accidental(anchor_midi),
    tie: None,
    tone_origin: Some(@music.ChordTone),
  })

  let remaining_notes = notes_left - 2
  let next_phrase = if remaining_notes <= 0 {
    Resting
  } else {
    Playing(remaining_notes)
  }
  MeasureState::{
    measure_pos: pos_after_at + ct_duration.to_beats(),
    beat_notes: state.beat_notes,
    stamina: stamina2,
    last_midi: Some(anchor_midi),
    last_was_rest: false,
    phrase: next_phrase,
  }
}
