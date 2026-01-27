///|
/// Create a leading rest measure (empty measure at the beginning)
pub fn leading_rest_measure(bpm : Int) -> Array[@music.Measure] {
  let measure_duration_ms = @music.ms_per_measure(bpm)
  [
    @music.Measure::{
      chords: [],
      notes: [],
      start_time: @music.Duration::from_milliseconds(0.0),
      duration: @music.Duration::from_milliseconds(measure_duration_ms),
    },
  ]
}

///|
/// Generate improvisation using measure generator
/// Returns array of Measures
/// measure_count specifies the number of music measures (excluding leading rest)
/// start_offset specifies the measure index offset for start_time calculation
pub fn improvisation(
  generator : MeasureGenerator,
  chords : Array[@music.Chord],
  bpm : Int,
  measure_count : Int,
  start_offset? : Int = 0,
) -> Array[@music.Measure] {
  if chords.is_empty() {
    return []
  }
  let measure_duration_ms = @music.ms_per_measure(bpm)
  let measures : Array[@music.Measure] = []
  let mut incoming_tie : TieContext? = None
  for i = 0; i < measure_count; i = i + 1 {
    let chord = chords[i % chords.length()]
    let ctx = MeasureContext::{ chord, incoming_tie }
    let result = generator(ctx)
    let measure = @music.Measure::{
      chords: [chord],
      notes: result.notes,
      start_time: @music.Duration::from_milliseconds(
        (i + start_offset).to_double() * measure_duration_ms,
      ),
      duration: @music.Duration::from_milliseconds(measure_duration_ms),
    }
    measures.push(measure)
    incoming_tie = result.outgoing_tie
  }

  // Remove dangling tie at the end of the last measure
  match incoming_tie {
    Some(_) => {
      guard not(measures.is_empty()) else { () }
      let last_measure = measures[measures.length() - 1]
      guard not(last_measure.notes.is_empty()) else { () }
      let last_idx = last_measure.notes.length() - 1
      let last_note = last_measure.notes[last_idx]
      last_measure.notes[last_idx] = @music.MeasureNote::{
        ..last_note,
        tie: None,
      }
    }
    None => ()
  }
  measures
}
