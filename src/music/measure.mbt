///|
/// Measure representation for lead sheet visualization

///|
/// Accidental types for note display
pub(all) enum Accidental {
  Sharp
  Flat
  Natural
} derive(Eq, Show)

///|
/// Tie state for notes that span measure boundaries
pub(all) enum TieState {
  None // No tie
  TieStart // Ties to next measure
  TieEnd // Tied from previous measure
  TieBoth // Spans 3+ measures (both in and out)
} derive(Eq, Show)

///|
/// Represents one measure with its chord and notes
pub(all) struct Measure {
  chord : Chord
  notes : Array[MeasureNote]
  start_time : Duration
  duration : Duration
  measure_index : Int
}

///|
/// A note positioned within a measure
pub(all) struct MeasureNote {
  midi : Int? // None for rests
  duration : NoteDuration
  start_beat : Double // 0.0 to 4.0 for 4/4 time
  accidental : Accidental? // Sharp, Flat, or Natural symbol to display
  tie_state : TieState // Tie connection state for cross-measure notes
}
