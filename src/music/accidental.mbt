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
/// Tracks state by diatonic step (0-6) to correctly handle key signatures
pub fn create_accidental_calculator(
  key : KeySignature,
) -> (MidiNumber) -> Accidental? {
  let step_states : Map[Int, Accidental] = {}
  // Initialize from key signature: altered steps start with key's accidental type
  for step in key.altered_steps {
    step_states[step] = key.accidental_type
  }
  fn(midi : MidiNumber) -> Accidental? {
    let step = key.pitch_class_to_diatonic_step(midi.pitch_class())
    let required_state = key.pitch_class_accidental(midi.pitch_class())
    let current_state = step_states.get(step).unwrap_or(Accidental::Natural)
    step_states[step] = required_state
    if required_state == current_state {
      None // No change needed
    } else {
      Some(required_state)
    }
  }
}
