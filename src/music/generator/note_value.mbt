///|
/// Settings for the measure generator
pub(all) struct Settings {
  chords : Array[@music.Chord]
  seed : Int
  rest_probability : Int // 0-100
  duration_weights : DurationWeights
} derive(Eq, Show)

///|
/// Create default settings with given chords and seed
pub fn Settings::default(chords : Array[@music.Chord], seed : Int) -> Settings {
  Settings::{
    chords,
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
      ctx,
      settings.rest_probability,
      settings.duration_weights,
      random_int,
    )
  }
}

///|
/// Generate notes for one measure
fn generate_measure_notes(
  ctx : MeasureContext,
  rest_probability : Int,
  duration_weights : DurationWeights,
  random_int : (Int) -> Int,
) -> MeasureResult {
  let notes : Array[@music.MeasureNote] = []
  let pitch_states = ctx.pitch_states.copy()
  let mut current_beat = 0.0
  let beats_per_measure = 4.0

  // Handle incoming tie first
  match ctx.incoming_tie {
    Some(tie_ctx) => {
      let remaining = @cmp.minimum(tie_ctx.remaining_beats, beats_per_measure)
      let duration = @music.NoteDuration::from_beats(remaining)
      let tie_state : @music.TieState = if tie_ctx.remaining_beats >
        beats_per_measure {
        @music.TieBoth
      } else {
        @music.TieEnd
      }
      notes.push(@music.MeasureNote::{
        midi: Some(tie_ctx.midi.value),
        duration,
        start_beat: 0.0,
        accidental: None,
        tie_state,
      })
      // Update pitch state for tie note
      let pc = tie_ctx.midi.value % 12
      pitch_states[pc] = midi_to_required_state(tie_ctx.midi.value)
      current_beat = remaining
      // If tie extends beyond this measure, return early with outgoing tie
      if tie_ctx.remaining_beats > beats_per_measure {
        return MeasureResult::{
          notes,
          outgoing_tie: Some(TieContext::{
            midi: tie_ctx.midi,
            remaining_beats: tie_ctx.remaining_beats - beats_per_measure,
          }),
          pitch_states,
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
    match decide_midi_number(ctx.chord, rest_probability, random_int) {
      Some(midi) =>
        if beats <= remaining_beats {
          // Note fits in this measure
          let accidental = calculate_accidental(midi.value, pitch_states)
          let pc = midi.value % 12
          pitch_states[pc] = midi_to_required_state(midi.value)
          notes.push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration,
            start_beat: current_beat,
            accidental,
            tie_state: @music.None,
          })
          current_beat = current_beat + beats
        } else {
          // Note extends beyond measure - create TieStart and outgoing tie
          let fitted_duration = @music.NoteDuration::fit(remaining_beats).unwrap_or(
            @music.Eighth,
          )
          let accidental = calculate_accidental(midi.value, pitch_states)
          let pc = midi.value % 12
          pitch_states[pc] = midi_to_required_state(midi.value)
          notes.push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration: fitted_duration,
            start_beat: current_beat,
            accidental,
            tie_state: @music.TieStart,
          })
          return MeasureResult::{
            notes,
            outgoing_tie: Some(TieContext::{
              midi,
              remaining_beats: beats - remaining_beats,
            }),
            pitch_states,
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
          tie_state: @music.None,
        })
        current_beat = current_beat + rest_duration.to_beats()
      }
    }
  }
  MeasureResult::{ notes, outgoing_tie: None, pitch_states }
}

///|
/// Decide whether to generate a note or rest, and if note, which MIDI number
fn decide_midi_number(
  chord : @music.Chord,
  rest_probability : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
  match random_int(100) < rest_probability {
    true => None
    false => random_midi_from_chord(chord, random_int)
  }
}

///|
/// Generate a random MIDI number from chord tones
/// Uses chord tones across multiple octaves
fn random_midi_from_chord(
  chord : @music.Chord,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
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
