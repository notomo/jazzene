///|
/// Generate improvisation using measure generator
/// Returns array of Measures
/// measure_count specifies the total number of measures (including leading rest)
pub fn improvisation(
  generator : MeasureGenerator,
  chords : Array[@music.Chord],
  bpm : Int,
  measure_count : Int,
) -> Array[@music.Measure] {
  if chords.is_empty() {
    return []
  }
  let measure_duration_ms = @music.ms_per_measure(bpm)
  let measures : Array[@music.Measure] = []
  let mut incoming_tie : TieContext? = None
  for i = 0; i < measure_count; i = i + 1 {
    let (chord, measure_chords) = match i {
      0 => (None, [])
      _ => {
        let c = chords[(i - 1) % chords.length()]
        (Some(c), [c])
      }
    }
    let ctx = MeasureContext::{ chord, incoming_tie }
    let result = generator(ctx)
    let measure = @music.Measure::{
      chords: measure_chords,
      notes: result.notes,
      start_time: @music.Duration::from_milliseconds(
        i.to_double() * measure_duration_ms,
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
