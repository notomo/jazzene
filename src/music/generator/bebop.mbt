///|
/// Decide whether to generate a bebop passing tone ornament at the current position.
/// Requires: at least 2 notes left in phrase, at least 1.0 beats remaining,
/// and probability check passes.
fn should_generate_bebop_ornament(
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
/// Select the bebop passing MIDI note adjacent to anchor_midi.
/// Returns Some(pt_midi) if the chord's bebop passing tone is ±1 semitone from anchor
/// and within pitch_min/pitch_max, else None.
fn select_bebop_approach_midi(
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  pitch_min : Int,
  pitch_max : Int,
) -> @music.MidiNumber? {
  let bebop_pcs = chord.bebop_passing_tones().map(fn(t) { t.pitch_class() })
  guard !bebop_pcs.is_empty() else { return None }
  let candidates = [-1, 1]
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .filter(fn(m) {
      m.value >= pitch_min &&
      m.value <= pitch_max &&
      bebop_pcs.contains(m.pitch_class())
    })
    .collect()
  guard !candidates.is_empty() else { return None }
  Some(candidates[0])
}

///|
/// Generate a PT→CT bebop passing tone ornament (2 notes).
/// PT: bebop passing tone (Eighth, 0.5 beats), CT: anchor chord tone (remaining duration).
fn generate_bebop_ornament(
  state : MeasureState,
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  remaining : Double,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let pt_midi = select_bebop_approach_midi(
    anchor_midi,
    chord,
    settings.pitch_min,
    settings.pitch_max,
  ).unwrap()
  let pos_after_pt = state.measure_pos + 0.5

  // CT duration: fill remaining space after PT (0.5)
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

  // Emit PT
  let beat_index1 = state.measure_pos.to_int()
  let cost1 = match state.last_midi {
    Some(prev) => interval_cost(prev, pt_midi)
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
    midi: Some(pt_midi.value),
    duration: @music.Eighth,
    accidental: update_accidental(pt_midi),
    tie: None,
    tone_origin: Some(@music.PassingTone),
  })

  // Emit CT
  let beat_index2 = pos_after_pt.to_int()
  let cost2 = interval_cost(pt_midi, anchor_midi)
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
    measure_pos: pos_after_pt + ct_duration.to_beats(),
    beat_notes: state.beat_notes,
    stamina: stamina2,
    last_midi: Some(anchor_midi),
    last_was_rest: false,
    phrase: next_phrase,
  }
}
