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
  let measure_duration_ms = @music.ms_per_measure(bpm)

  // Leading rest measure (measure index 0)
  let dummy_chord = @music.Chord::{ root: @music.C, quality: @music.Major }
  let leading_rest = @music.Measure::{
    chord: dummy_chord,
    notes: [
      @music.MeasureNote::{
        midi: None,
        duration: @music.Whole,
        start_beat: 0.0,
        accidental: None,
        tie_state: @music.None,
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
    duration: @music.Duration::from_milliseconds(measure_duration_ms),
    measure_index: 0,
  }
  if chords.is_empty() || measure_count <= 1 {
    return [leading_rest]
  }
  let measures : Array[@music.Measure] = [leading_rest]
  let mut incoming_tie : TieContext? = None
  let mut pitch_states : Map[Int, @music.Accidental] = {}

  // Generate measures for each chord position
  let chord_measures_count = measure_count - 1
  for i = 0; i < chord_measures_count; i = i + 1 {
    let chord = chords[i % chords.length()]
    let measure_index = i + 1
    let ctx = MeasureContext::{
      chord,
      measure_index,
      incoming_tie,
      pitch_states,
    }
    let result = generator(ctx)
    let measure = @music.Measure::{
      chord,
      notes: result.notes,
      start_time: @music.Duration::from_milliseconds(
        measure_index.to_double() * measure_duration_ms,
      ),
      duration: @music.Duration::from_milliseconds(measure_duration_ms),
      measure_index,
    }
    measures.push(measure)

    // Pass context to next measure
    incoming_tie = result.outgoing_tie
    pitch_states = result.pitch_states
  }
  measures
}
