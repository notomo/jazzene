///|
/// Decide whether to generate a triplet group at the current position.
/// Requires: on an integer beat, at least 3 notes left in phrase,
/// at least 1 beat remaining, and probability check passes.
fn should_generate_triplet(
  measure_pos : Double,
  notes_left : Int,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> Bool {
  guard probability > 0 else { return false }
  let on_beat = (measure_pos - measure_pos.to_int().to_double()).abs() < 0.01
  on_beat &&
  notes_left >= 3 &&
  remaining >= 1.0 - 0.001 &&
  random_int(100) < probability
}

///|
/// Generate a group of 3 eighth-note triplets (totaling 1 beat)
fn generate_triplet_group(
  state : MeasureState,
  _chord : @music.Chord,
  ctx : MeasureContext,
  settings : Settings,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
  notes_left : Int,
) -> MeasureState {
  let triplet_duration = @music.EighthTriplet
  // Remember the start position so we can snap to exact integer after 3 triplets
  // (avoids floating-point drift from 1/3 + 1/3 + 1/3 != 1.0)
  let start_pos = state.measure_pos
  let mut current_state = state

  for i = 0; i < 3; i = i + 1 {
    let current_chord = ctx.chord_at(current_state.measure_pos)
    let (midi_opt, tone_origin, new_motif_memory) = select_note_with_motif(
      current_state, current_chord, ctx, settings, random_int,
    )

    match midi_opt {
      Some(midi) => {
        let cost = match current_state.last_midi {
          Some(prev) => interval_cost(prev, midi)
          None => 0
        }
        let new_stamina = @cmp.maximum(
          0,
          @cmp.minimum(
            current_state.stamina - cost + settings.stamina_passive_recovery,
            settings.stamina_max,
          ),
        )
        let new_motif_memory = record_motif_interval(
          new_motif_memory,
          current_state.last_midi,
          midi,
          current_state.motif_first_note,
        )
        let beat_index = current_state.measure_pos.to_int()
        current_state.beat_notes[beat_index].push(@music.MeasureNote::{
          midi: Some(midi.value),
          duration: triplet_duration,
          accidental: update_accidental(midi),
          tie: None,
          tone_origin,
        })
        let remaining_after = notes_left - (i + 1)
        let next_phrase = if remaining_after <= 0 {
          Resting
        } else {
          Playing(remaining_after)
        }
        // After the last triplet, snap to exact integer to avoid floating-point drift
        let new_pos = if i == 2 {
          start_pos + 1.0
        } else {
          current_state.measure_pos + triplet_duration.to_beats()
        }
        current_state = MeasureState::{
          measure_pos: new_pos,
          beat_notes: current_state.beat_notes,
          stamina: new_stamina,
          last_midi: Some(midi),
          last_was_rest: false,
          phrase: next_phrase,
          motif_memory: new_motif_memory,
          motif_first_note: false,
        }
      }
      None => break
    }
  }
  current_state
}
