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
pub fn create_accidental_calculator() -> (MidiNumber) -> Accidental? {
  let pitch_states : Map[Int, Accidental] = {}
  fn(midi : MidiNumber) -> Accidental? {
    let pitch_class = midi.pitch_class()
    let required_state = midi.accidental()
    let current_state = pitch_states
      .get(pitch_class)
      .unwrap_or(Accidental::Natural)
    pitch_states[pitch_class] = required_state
    if required_state == current_state {
      None // No change needed
    } else {
      Some(required_state)
    }
  }
}
