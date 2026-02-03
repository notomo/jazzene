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
/// Internal state for measure generation
priv struct MeasureState {
  measure_pos : Double
  beat_notes : Array[Array[@music.MeasureNote]]
}

///|
fn MeasureState::new(num_beats : Int) -> MeasureState {
  MeasureState::{
    measure_pos: 0.0,
    beat_notes: Array::makei(num_beats, fn(_) { [] }),
  }
}

///|
fn MeasureState::add_note(
  self : MeasureState,
  note : @music.MeasureNote,
) -> MeasureState {
  let beat_index = self.measure_pos.to_int()
  self.beat_notes[beat_index].push(note)
  MeasureState::{
    measure_pos: self.measure_pos + note.duration.to_beats(),
    beat_notes: self.beat_notes,
  }
}

///|
fn MeasureState::to_beats(self : MeasureState) -> Array[@music.Beat] {
  self.beat_notes
  .iter()
  .mapi(fn(i, notes) { @music.Beat::{ count: i, notes } })
  .collect()
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
  let initial_state = MeasureState::new(beats_per_measure.to_int())

  // Handle incoming tie first
  let (state_after_tie, outgoing_tie) = match incoming_tie {
    Some(tie_ctx) =>
      process_incoming_tie(initial_state, tie_ctx, beats_per_measure)
    None => (initial_state, None)
  }

  // Fill remaining measure with new notes
  let update_accidental = @music.create_accidental_calculator(key)
  let final_state = fill_remaining_measure(
    state_after_tie, chord, beats_per_measure, rest_probability, note_duration_weights,
    rest_duration_weights, update_accidental, random_int,
  )
  MeasureResult::{ beats: final_state.to_beats(), outgoing_tie }
}

///|
/// Process incoming tie from previous measure
/// Returns updated state and optional outgoing tie
fn process_incoming_tie(
  state : MeasureState,
  tie_ctx : TieContext,
  beats_per_measure : Double,
) -> (MeasureState, TieContext?) {
  let midi = tie_ctx.midi
  for remaining = tie_ctx.remaining_beats, state = state {
    guard remaining > 0.0 && state.measure_pos < beats_per_measure else {
      let outgoing = if remaining > 0.0 {
        Some(TieContext::{ midi, remaining_beats: remaining })
      } else {
        None
      }
      break (state, outgoing)
    }
    let beat_index = state.measure_pos.to_int()
    let beat_capacity = (beat_index + 1).to_double() - state.measure_pos
    let remaining_in_measure = beats_per_measure - state.measure_pos
    let (tie, consume) = match
      (remaining > remaining_in_measure, remaining > beat_capacity) {
      (true, _) => (@music.TieBoth, beat_capacity) // Extends beyond measure
      (false, true) => (@music.TieBoth, beat_capacity) // Spans beyond beat
      (false, false) => (@music.TieEnd, remaining) // Ends in this beat
    }
    let fitted = @music.NoteDuration::fit(consume).unwrap_or(@music.Eighth)
    let new_state = state.add_note(@music.MeasureNote::{
      midi: Some(midi.value),
      duration: fitted,
      accidental: None,
      tie: Some(tie),
    })
    continue remaining - fitted.to_beats(), new_state
  }
}

///|
/// Fill remaining measure with new notes
fn fill_remaining_measure(
  state : MeasureState,
  chord : @music.Chord,
  beats_per_measure : Double,
  rest_probability : Int,
  note_duration_weights : DurationWeights,
  rest_duration_weights : DurationWeights,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
) -> MeasureState {
  for state = state {
    guard state.measure_pos < beats_per_measure else { break state }
    let remaining = beats_per_measure - state.measure_pos
    let (midi_opt, weights) = match
      decide_midi_number(chord, rest_probability, random_int) {
      Some(midi) => (Some(midi), note_duration_weights)
      None => (None, rest_duration_weights)
    }
    match random_duration_within(remaining, weights, random_int) {
      Some(duration) => {
        let new_state = state.add_note(@music.MeasureNote::{
          midi: midi_opt.map(fn(m) { m.value }),
          duration,
          accidental: midi_opt.bind(update_accidental),
          tie: None,
        })
        continue new_state
      }
      None => break state
    }
  }
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
