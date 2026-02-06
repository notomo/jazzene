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
/// State passed between measures during improvisation generation
priv struct ImprovisationState {
  measures : Array[@music.Measure]
  incoming_tie : TieContext?
  incoming_stamina : Int
  incoming_last_midi : @music.MidiNumber?
}

///|
/// Generate improvisation using measure generator
/// Returns array of Measures
/// measure_count specifies the number of music measures (excluding leading rest)
/// start_offset specifies the measure index offset for start_time calculation
/// measure_defs contains arrays of chords per measure (supports multiple chords per measure)
pub fn improvisation(
  generator : MeasureGenerator,
  measure_defs : Array[Array[@music.Chord]],
  bpm : Int,
  measure_count : Int,
  key : @music.KeySignature,
  settings : Settings,
  beats_per_measure~ : Double,
  start_offset? : Int = 0,
) -> Array[@music.Measure] {
  if measure_defs.is_empty() {
    return []
  }
  let measure_duration_ms = @music.ms_per_measure(bpm, beats_per_measure~)
  let initial_state = ImprovisationState::{
    measures: [],
    incoming_tie: None,
    incoming_stamina: settings.stamina_initial,
    incoming_last_midi: None,
  }
  let final_state = Array::makei(measure_count, fn(i) { i })
    .iter()
    .fold(init=initial_state, fn(state, i) {
      let measure_chords = measure_defs[i % measure_defs.length()]
      let chord_segments = create_chord_segments(
        measure_chords, beats_per_measure,
      )
      let result = generator(MeasureContext::{
        chords: chord_segments,
        incoming_tie: state.incoming_tie,
        key,
        beats_per_measure,
        incoming_stamina: state.incoming_stamina,
        incoming_last_midi: state.incoming_last_midi,
      })
      state.measures.push(@music.Measure::{
        chords: measure_chords,
        beats: result.beats,
        start_time: @music.Duration::from_milliseconds(
          (i + start_offset).to_double() * measure_duration_ms,
        ),
      })
      ImprovisationState::{
        measures: state.measures,
        incoming_tie: result.outgoing_tie,
        incoming_stamina: result.outgoing_stamina,
        incoming_last_midi: result.outgoing_last_midi,
      }
    })
  remove_dangling_tie(final_state.measures, final_state.incoming_tie)
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
