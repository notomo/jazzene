///|
/// Accidental types for note display
pub(all) enum Accidental {
  Sharp
  Flat
  Natural
} derive(Eq, Show)

///|
/// Create an accidental calculator that tracks pitch states internally
/// Returns a function that calculates and updates accidentals for each note
/// Tracks state by (diatonic step, octave) because accidentals don't cross octaves
pub fn create_accidental_calculator(
  key : KeySignature,
) -> (MidiNumber) -> Accidental? {
  // Track accidental state per (step, octave) - accidentals only apply within the same octave
  let note_states : Map[Int, Accidental] = {}
  // Key signature defaults per step (applies to all octaves)
  let key_defaults : Map[Int, Accidental] = {}

  for step in key.altered_steps {
    key_defaults[step] = key.accidental_type
  }

  fn(midi : MidiNumber) -> Accidental? {
    let step = key.pitch_class_to_diatonic_step(midi.pitch_class())
    let octave = midi.value / 12
    let note_key = octave * 7 + step
    let required_state = key.pitch_class_accidental(midi.pitch_class())
    let current_state = match note_states.get(note_key) {
      Some(s) => s
      None => key_defaults.get(step).unwrap_or(Accidental::Natural)
    }
    note_states[note_key] = required_state
    if required_state == current_state {
      None // No change needed
    } else {
      Some(required_state)
    }
  }
}
