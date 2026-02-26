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
/// Excludes chord tones by pitch class.
fn select_neighbor_midi(
  anchor_midi : @music.MidiNumber,
  chord : @music.Chord,
  random_int : (Int) -> Int,
) -> @music.MidiNumber {
  let chord_tone_pcs = chord.tones().map(fn(t) { t.pitch_class() })
  let scale_tone_pcs = chord.scale_tones().map(fn(t) { t.pitch_class() })
  let offsets = [-2, -1, 1, 2]
  // All valid MIDI neighbors
  let chromatic_candidates : Array[@music.MidiNumber] = offsets
    .iter()
    .filter_map(fn(offset) {
      @music.MidiNumber::new(anchor_midi.value + offset)
    })
    .collect()
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
  let neighbor_midi = select_neighbor_midi(anchor_midi, chord, random_int)

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
