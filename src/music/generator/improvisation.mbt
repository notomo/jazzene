///|
/// Create a leading rest measure (empty measure at the beginning)
pub fn leading_rest_measure() -> Array[@music.Measure] {
  [
    @music.Measure::{
      chords: [],
      beats: [],
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
        beats: result.beats,
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
/// The last note that would overflow into a non-existent next measure
/// is removed entirely rather than kept with its tie cleared.
/// Returns a new array without mutating the original.
fn remove_dangling_tie(
  measures : Array[@music.Measure],
  last_tie : TieContext?,
) -> Array[@music.Measure] {
  guard last_tie is Some(_) else { return measures }
  guard measures is [.. rest_measures, last_measure] else { return measures }
  guard last_measure.beats is [.. _rest_beats] else { return measures }
  // Remove trailing tied notes from the last measure's beats
  let new_beats = remove_trailing_tied_notes(last_measure.beats)
  [..rest_measures, @music.Measure::{ ..last_measure, beats: new_beats }]
}

///|
/// Remove trailing tied notes from beats.
/// Works backwards through beats, removing notes with TieStart/TieBoth ties
/// from the end of the last beat that has notes.
fn remove_trailing_tied_notes(beats : Array[@music.Beat]) -> Array[@music.Beat] {
  // Work backwards through beats to find and remove the trailing tied note chain
  // State: (result_beats, should_continue_removing)
  let (result, _) = beats[:].rev_fold(init=([], true), fn(acc, beat) {
    let (result_beats, removing) = acc
    match (removing, beat.notes) {
      (true, [.. rest, { tie: Some(@music.TieStart | @music.TieBoth), .. }]) => {
        // Remove the last note and continue removing backwards
        let new_beat = @music.Beat::{
          count: beat.count,
          notes: rest.to_array(),
        }
        ([new_beat, ..result_beats], true)
      }
      _ =>
        // Stop removing: either not removing or last note doesn't have tie
        ([beat, ..result_beats], false)
    }
  })
  result
}
