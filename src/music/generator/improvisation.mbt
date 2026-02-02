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
  let new_beats = beats.copy()
  for i = new_beats.length() - 1; i >= 0; i = i - 1 {
    let beat = new_beats[i]
    if beat.notes.is_empty() {
      continue
    }
    let last_note = beat.notes[beat.notes.length() - 1]
    match last_note.tie {
      Some(@music.TieStart | @music.TieBoth) => {
        // Remove the last note from this beat
        let remaining_notes = beat.notes
          .iter()
          .take(beat.notes.length() - 1)
          .collect()
        new_beats[i] = @music.Beat::{
          count: beat.count,
          notes: remaining_notes,
        }
        // If this was TieBoth, the previous beat's last note may also need removal
        // But for the dangling tie case, TieStart in the last beat with notes is the source
        // Continue backwards to remove any TieBoth notes that were part of the same chain
        continue
      }
      _ => break
    }
  }
  new_beats
}
