///|
/// Create a leading rest measure (empty measure at the beginning)
pub fn leading_rest_measure() -> Array[@music.Measure] {
  [
    @music.Measure::{
      chords: [],
      notes: [],
      start_time: @music.Duration::from_milliseconds(0.0),
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
  key : @music.KeySignature,
  beats_per_measure~ : Double,
  start_offset? : Int = 0,
) -> Array[@music.Measure] {
  if chords.is_empty() {
    return []
  }
  let measure_duration_ms = @music.ms_per_measure(bpm, beats_per_measure~)
  let (measures, last_tie) = Array::makei(measure_count, fn(i) { i })
    .iter()
    .fold(init=(([] : Array[@music.Measure]), (None : TieContext?)), fn(
      acc,
      i,
    ) {
      let (measures, incoming_tie) = acc
      let chord = chords[i % chords.length()]
      let result = generator(MeasureContext::{
        chord,
        incoming_tie,
        key,
        beats_per_measure,
      })
      measures.push(@music.Measure::{
        chords: [chord],
        notes: result.notes,
        start_time: @music.Duration::from_milliseconds(
          (i + start_offset).to_double() * measure_duration_ms,
        ),
      })
      (measures, result.outgoing_tie)
    })
  remove_dangling_tie(measures, last_tie)
}

///|
/// Remove dangling tie at the end of the last measure.
/// Returns a new array without mutating the original.
fn remove_dangling_tie(
  measures : Array[@music.Measure],
  last_tie : TieContext?,
) -> Array[@music.Measure] {
  guard last_tie is Some(_) else { return measures }
  guard measures is [.. rest_measures, last_measure] else { return measures }
  guard last_measure.notes is [.. rest_notes, last_note] else {
    return measures
  }
  [
    ..rest_measures,
    @music.Measure::{
      ..last_measure,
      notes: [..rest_notes, @music.MeasureNote::{ ..last_note, tie: None }],
    },
  ]
}
