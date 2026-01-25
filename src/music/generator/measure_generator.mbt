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
