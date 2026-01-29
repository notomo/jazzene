///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chord : @music.Chord
  incoming_tie : TieContext? // Tie from previous measure
  key : @music.KeySignature
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

///|
/// Settings for the measure generator
pub(all) struct Settings {
  seed : Int
  rest_probability : Int // 0-100
  duration_weights : DurationWeights
} derive(Eq, Show)

///|
/// Create default settings with given seed
pub fn Settings::default(seed : Int) -> Settings {
  Settings::{
    seed,
    rest_probability: 25,
    duration_weights: DurationWeights::default(),
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
      settings.rest_probability,
      settings.duration_weights,
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
  rest_probability : Int,
  duration_weights : DurationWeights,
  random_int : (Int) -> Int,
) -> MeasureResult {
  let notes : Array[@music.MeasureNote] = []
  let update_accidental = @music.create_accidental_calculator(key)
  let mut current_beat = 0.0
  let beats_per_measure = 4.0

  // Handle incoming tie first
  match incoming_tie {
    Some(tie_ctx) => {
      let remaining = @cmp.minimum(tie_ctx.remaining_beats, beats_per_measure)
      let duration = @music.NoteDuration::from_beats(remaining)
      let tie : @music.Tie? = if tie_ctx.remaining_beats > beats_per_measure {
        Some(@music.TieBoth)
      } else {
        Some(@music.TieEnd)
      }
      notes.push(@music.MeasureNote::{
        midi: Some(tie_ctx.midi.value),
        duration,
        start_beat: 0.0,
        accidental: None,
        tie,
      })
      current_beat = remaining
      // If tie extends beyond this measure, return early with outgoing tie
      if tie_ctx.remaining_beats > beats_per_measure {
        return MeasureResult::{
          notes,
          outgoing_tie: Some(TieContext::{
            midi: tie_ctx.midi,
            remaining_beats: tie_ctx.remaining_beats - beats_per_measure,
          }),
        }
      }
    }
    None => ()
  }

  // Generate notes to fill the rest of the measure
  while current_beat < beats_per_measure {
    let remaining_beats = beats_per_measure - current_beat
    let duration = random_duration(duration_weights, random_int)
    let beats = duration.to_beats()
    match decide_midi_number(chord, rest_probability, random_int) {
      Some(midi) =>
        if beats <= remaining_beats {
          // Note fits in this measure
          notes.push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration,
            start_beat: current_beat,
            accidental: update_accidental(midi),
            tie: None,
          })
          current_beat = current_beat + beats
        } else {
          // Note extends beyond measure - create TieStart and outgoing tie
          let fitted_duration = @music.NoteDuration::fit(remaining_beats).unwrap_or(
            @music.Eighth,
          )
          notes.push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration: fitted_duration,
            start_beat: current_beat,
            accidental: update_accidental(midi),
            tie: Some(@music.TieStart),
          })
          return MeasureResult::{
            notes,
            outgoing_tie: Some(TieContext::{
              midi,
              remaining_beats: beats - remaining_beats,
            }),
          }
        }
      None => {
        // Rest - rests cannot be tied
        let rest_beats = @cmp.minimum(beats, remaining_beats)
        let rest_duration = @music.NoteDuration::fit(rest_beats).unwrap_or(
          @music.Eighth,
        )
        notes.push(@music.MeasureNote::{
          midi: None,
          duration: rest_duration,
          start_beat: current_beat,
          accidental: None,
          tie: None,
        })
        current_beat = current_beat + rest_duration.to_beats()
      }
    }
  }
  MeasureResult::{ notes, outgoing_tie: None }
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
