///|
/// Sixteenth-note run ornament: 4 × Sixteenth notes (= 1 beat) approaching a chord tone.
/// Pattern: P1 P2 P3 CT — three chromatic approach notes + chord tone.
/// Only fires on integer beat positions to align with the metric grid.

///|
/// Decide whether to generate a sixteenth-note run at the current position.
/// Requires: on an integer beat, at least 4 notes left in phrase,
/// at least 1 beat remaining, and probability check passes.
fn should_generate_sixteenth_run(
  measure_pos : Double,
  notes_left : Int,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> Bool {
  guard probability > 0 else { return false }
  ignore(measure_pos)
  notes_left >= 4 && remaining >= 1.0 - 0.001 && random_int(100) < probability
}

///|
/// Generate 3 chromatic approach notes leading to anchor_midi.
/// Direction is determined by last_midi: ascending = approach from below, descending = from above.
/// Only includes notes within pitch_min/pitch_max.
fn select_run_approach_notes(
  anchor_midi : @music.MidiNumber,
  last_midi : @music.MidiNumber?,
  pitch_min : Int,
  pitch_max : Int,
  random_int : (Int) -> Int,
) -> Array[@music.MidiNumber] {
  // Ascending = approach from below (anchor-3, anchor-2, anchor-1)
  // Descending = approach from above (anchor+3, anchor+2, anchor+1)
  let ascending = match last_midi {
    Some(prev) =>
      if prev.value < anchor_midi.value {
        true
      } else if prev.value > anchor_midi.value {
        false
      } else {
        random_int(2) == 0
      }
    None => random_int(2) == 0
  }
  let offsets : Array[Int] = if ascending { [-3, -2, -1] } else { [3, 2, 1] }
  offsets
  .iter()
  .filter_map(fn(offset) { @music.MidiNumber::new(anchor_midi.value + offset) })
  .filter(fn(m) { m.value >= pitch_min && m.value <= pitch_max })
  .collect()
}

///|
/// Emit a single Sixteenth note into the measure state, returning updated state.
fn emit_sixteenth(
  state : MeasureState,
  midi : @music.MidiNumber,
  tone_origin : @music.ToneOrigin,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  phrase : PhraseState,
) -> MeasureState {
  let cost = match state.last_midi {
    Some(prev) => interval_cost(prev, midi)
    None => 0
  }
  let new_stamina = @cmp.maximum(
    0,
    @cmp.minimum(
      state.stamina - cost + settings.stamina_passive_recovery,
      settings.stamina_max,
    ),
  )
  let beat_index = state.measure_pos.to_int()
  state.beat_notes[beat_index].push(@music.MeasureNote::{
    midi: Some(midi.value),
    duration: @music.Sixteenth,
    accidental: update_accidental(midi),
    tie: None,
    tone_origin: Some(tone_origin),
  })
  MeasureState::{
    measure_pos: state.measure_pos + 0.25,
    beat_notes: state.beat_notes,
    stamina: new_stamina,
    last_midi: Some(midi),
    last_was_rest: false,
    phrase,
  }
}

///|
/// Generate a 4-note sixteenth-note run: P1 P2 P3 CT (each = Sixteenth, total = 1 beat).
fn generate_sixteenth_run(
  state : MeasureState,
  anchor_midi : @music.MidiNumber,
  settings : ImprovisationConfig,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let approach = select_run_approach_notes(
    anchor_midi,
    state.last_midi,
    settings.pitch_min,
    settings.pitch_max,
    random_int,
  )
  // If we couldn't generate 3 approach notes (edge of MIDI range), fall back to fewer
  let all_notes : Array[(@music.MidiNumber, @music.ToneOrigin)] = approach
    .iter()
    .map(fn(m) { (m, @music.ChromaticApproach) })
    .collect()
  all_notes.push((anchor_midi, @music.ChordTone))

  let mut cur = state
  for i, pair in all_notes {
    let (midi, tone_origin) = pair
    let remaining_notes = notes_left - (i + 1)
    let phrase = if remaining_notes <= 0 {
      Resting
    } else {
      Playing(remaining_notes)
    }
    cur = emit_sixteenth(
      cur, midi, tone_origin, settings, update_accidental, phrase,
    )
  }
  // Phrase consumed `total` notes from notes_left (already handled above in loop)
  cur
}
