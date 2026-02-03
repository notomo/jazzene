///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chord : @music.Chord
  incoming_tie : TieContext? // Tie from previous measure
  key : @music.KeySignature
  beats_per_measure : Double
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
  beats : Array[@music.Beat]
  outgoing_tie : TieContext? // Tie to next measure
}

///|
/// Generator function that produces notes for one measure
pub type MeasureGenerator = (MeasureContext) -> MeasureResult

///|
/// Settings for the measure generator
pub(all) struct Settings {
  seed : Int
  rest_probability : Int // 0-100
  note_duration_weights : DurationWeights
  rest_duration_weights : DurationWeights
} derive(Eq, Show)

///|
/// Create default settings with given seed
pub fn Settings::default(seed : Int) -> Settings {
  Settings::{
    seed,
    rest_probability: 25,
    note_duration_weights: DurationWeights::note_default(),
    rest_duration_weights: DurationWeights::rest_default(),
  }
}

///|
/// Create a measure generator from settings
/// Returns a function that generates notes for one measure
pub fn create_measure_generator(settings : Settings) -> MeasureGenerator {
  let random_int = create_random_int(settings.seed)
  fn(ctx : MeasureContext) -> MeasureResult {
    generate_measure_notes(
      ctx.chord,
      ctx.incoming_tie,
      ctx.key,
      ctx.beats_per_measure,
      settings.rest_probability,
      settings.note_duration_weights,
      settings.rest_duration_weights,
      random_int,
    )
  }
}

///|
/// Generate notes for one measure
fn generate_measure_notes(
  chord : @music.Chord,
  incoming_tie : TieContext?,
  key : @music.KeySignature,
  beats_per_measure : Double,
  rest_probability : Int,
  note_duration_weights : DurationWeights,
  rest_duration_weights : DurationWeights,
  random_int : (Int) -> Int,
) -> MeasureResult {
  let update_accidental = @music.create_accidental_calculator(key)
  let num_beats = beats_per_measure.to_int()
  let beats : Array[@music.Beat] = []

  // Convert incoming cross-measure tie to beat carry
  // Track position across the entire measure
  let mut measure_pos = 0.0
  // Notes grouped by beat index
  let beat_notes : Array[Array[@music.MeasureNote]] = Array::makei(num_beats, fn(
    _i,
  ) {
    []
  })

  // Handle incoming tie first
  let mut outgoing_tie : TieContext? = None
  match incoming_tie {
    Some(tie_ctx) => {
      let midi = tie_ctx.midi
      let mut remaining = tie_ctx.remaining_beats
      // Fill beats with tied notes
      while remaining > 0.0 && measure_pos < beats_per_measure {
        let beat_index = measure_pos.to_int()
        let beat_capacity = (beat_index + 1).to_double() - measure_pos
        let remaining_in_measure = beats_per_measure - measure_pos
        if remaining > remaining_in_measure {
          // Tie extends beyond this measure
          let fitted = @music.NoteDuration::fit(beat_capacity).unwrap_or(
            @music.Eighth,
          )
          beat_notes[beat_index].push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration: fitted,
            accidental: None,
            tie: Some(@music.TieBoth),
          })
          measure_pos = measure_pos + fitted.to_beats()
          remaining = remaining - fitted.to_beats()
        } else if remaining > beat_capacity {
          // Tie spans beyond this beat but not beyond measure
          let fitted = @music.NoteDuration::fit(beat_capacity).unwrap_or(
            @music.Eighth,
          )
          let tie = if measure_pos == 0.0 {
            @music.TieBoth
          } else {
            @music.TieBoth
          }
          beat_notes[beat_index].push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration: fitted,
            accidental: None,
            tie: Some(tie),
          })
          measure_pos = measure_pos + fitted.to_beats()
          remaining = remaining - fitted.to_beats()
        } else {
          // Tie ends in this beat
          let fitted = @music.NoteDuration::fit(remaining).unwrap_or(
            @music.Eighth,
          )
          beat_notes[beat_index].push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration: fitted,
            accidental: None,
            tie: Some(@music.TieEnd),
          })
          measure_pos = measure_pos + fitted.to_beats()
          remaining = 0.0
        }
      }
      // If tie still has remaining beats, create outgoing tie
      if remaining > 0.0 {
        outgoing_tie = Some(TieContext::{ midi, remaining_beats: remaining })
      }
    }
    None => ()
  }

  // Fill remaining measure with new notes (no ties created)
  while measure_pos < beats_per_measure {
    let remaining_in_measure = beats_per_measure - measure_pos
    let beat_index = measure_pos.to_int()
    match decide_midi_number(chord, rest_probability, random_int) {
      Some(midi) =>
        match
          random_duration_within(
            remaining_in_measure, note_duration_weights, random_int,
          ) {
          Some(duration) => {
            beat_notes[beat_index].push(@music.MeasureNote::{
              midi: Some(midi.value),
              duration,
              accidental: update_accidental(midi),
              tie: None,
            })
            measure_pos = measure_pos + duration.to_beats()
          }
          None => break
        }
      None =>
        match
          random_duration_within(
            remaining_in_measure, rest_duration_weights, random_int,
          ) {
          Some(duration) => {
            beat_notes[beat_index].push(@music.MeasureNote::{
              midi: None,
              duration,
              accidental: None,
              tie: None,
            })
            measure_pos = measure_pos + duration.to_beats()
          }
          None => break
        }
    }
  }

  // Convert to Beat array
  for i, notes in beat_notes {
    beats.push(@music.Beat::{ count: i, notes })
  }
  MeasureResult::{ beats, outgoing_tie }
}

///|
/// Decide whether to generate a note or rest, and if note, which MIDI number
/// Uses chord tones across multiple octaves
fn decide_midi_number(
  chord : @music.Chord,
  rest_probability : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
  guard random_int(100) >= rest_probability else { return None }
  let base_tones = chord.tones()
  let extended_tones = [-1, 0, 1]
    .iter()
    .flat_map(fn(octave_offset) {
      base_tones
      .iter()
      .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
    })
    .collect()
  let index = random_int(extended_tones.length())
  Some(extended_tones[index])
}
