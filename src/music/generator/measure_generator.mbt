///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chord : @music.Chord
  measure_index : Int
  incoming_tie : TieContext? // Tie from previous measure
}

///|
/// Tie information for cross-measure notes
pub struct TieContext {
  midi : @music.MidiNumber
  remaining_beats : Double
}

///|
/// Result from MeasureGenerator
pub struct MeasureResult {
  notes : Array[@music.MeasureNote]
  outgoing_tie : TieContext? // Tie to next measure
}

///|
/// Generator function that produces notes for one measure
pub type MeasureGenerator = (MeasureContext) -> MeasureResult

///|
/// Determine the required accidental state for a MIDI number
/// Based on C major key (no sharps/flats), so black keys need accidentals
fn midi_to_required_state(midi : Int) -> @music.Accidental {
  let pitch_class = midi % 12
  match pitch_class {
    1 => @music.Sharp // C#
    3 => @music.Flat // Eb (prefer flat per ChordRoot convention)
    6 => @music.Sharp // F#
    8 => @music.Flat // Ab (prefer flat per ChordRoot convention)
    10 => @music.Flat // Bb (prefer flat per ChordRoot convention)
    _ => @music.Accidental::Natural // White keys
  }
}

///|
/// Calculate the accidental to display based on current pitch states
/// Returns None if no accidental change is needed
fn calculate_accidental(
  midi : Int,
  pitch_states : Map[Int, @music.Accidental],
) -> @music.Accidental? {
  let pitch_class = midi % 12
  let required_state = midi_to_required_state(midi)
  let current_state = pitch_states
    .get(pitch_class)
    .unwrap_or(@music.Accidental::Natural)
  if required_state == current_state {
    None // No change needed
  } else {
    Some(required_state)
  }
}
