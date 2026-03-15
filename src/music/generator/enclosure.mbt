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
