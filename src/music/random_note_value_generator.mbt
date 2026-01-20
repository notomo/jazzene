///|
/// Weights for random duration selection
pub(all) struct DurationWeights {
  eighth : Int
  dotted_eighth : Int
  quarter : Int
  dotted_quarter : Int
  half : Int
  dotted_half : Int
  whole : Int
} derive(Eq, Show)

///|
/// Default weights favoring quarter notes
pub fn DurationWeights::default() -> DurationWeights {
  DurationWeights::{
    eighth: 15,
    dotted_eighth: 10,
    quarter: 40,
    dotted_quarter: 20,
    half: 8,
    dotted_half: 5,
    whole: 2,
  }
}

///|
/// Settings for the note value generator
pub(all) struct GeneratorSettings {
  chords : Array[Chord]
  seed : Int
  rest_probability : Int // 0-100
  duration_weights : DurationWeights
} derive(Eq, Show)

///|
/// Create default settings with given chords and seed
pub fn GeneratorSettings::default(
  chords : Array[Chord],
  seed : Int,
) -> GeneratorSettings {
  GeneratorSettings::{
    chords,
    seed,
    rest_probability: 25,
    duration_weights: DurationWeights::default(),
  }
}

///|
/// Convert an integer seed to a 32-byte seed for ChaCha8 RNG
/// The seed is distributed across the 32 bytes using little-endian encoding
fn seed_to_bytes(seed : Int) -> Bytes {
  let seed_uint = seed.reinterpret_as_uint()
  Bytes::makei(32, fn(i) {
    let value = seed_uint + (i / 4).reinterpret_as_uint()
    (value >> (i % 4 * 8)).to_byte()
  })
}

///|
/// Create a note value generator from settings
/// Returns a closure that generates one NoteValue per call, cycling through chords
pub fn create_note_value_generator(
  settings : GeneratorSettings,
) -> NoteValueGenerator {
  let rand = @random.Rand::chacha8(seed=seed_to_bytes(settings.seed))
  let mut chord_index = 0
  fn() {
    let chord = match settings.chords.length() {
      0 => Chord::{ root: C, quality: Major7 } // Fallback chord
      _ => settings.chords[chord_index % settings.chords.length()]
    }
    chord_index = chord_index + 1
    let duration = random_duration(settings.duration_weights, rand)
    match decide_midi_number(chord, settings.rest_probability, rand) {
      Some(midi) => NoteValue::Note(midi~, duration~)
      None => NoteValue::Rest(duration~)
    }
  }
}

///|
/// Decide whether to generate a note or rest, and if note, which MIDI number
fn decide_midi_number(
  chord : Chord,
  rest_probability : Int,
  rand : @random.Rand,
) -> MidiNumber? {
  match rand.int(limit=100) < rest_probability {
    true => None
    false => random_midi_from_chord(chord, rand)
  }
}

///|
/// Convert duration weights to an array of (weight, duration) pairs
fn DurationWeights::to_choices(
  self : DurationWeights,
) -> Array[(Int, NoteDuration)] {
  [
    (self.eighth, Eighth),
    (self.dotted_eighth, DottedEighth),
    (self.quarter, Quarter),
    (self.dotted_quarter, DottedQuarter),
    (self.half, Half),
    (self.dotted_half, DottedHalf),
    (self.whole, Whole),
  ]
}

///|
/// Select a random item from weighted choices
fn[T] weighted_choice(choices : Array[(Int, T)], rand : @random.Rand) -> T {
  let total = choices.iter().fold(init=0, fn(acc, pair) { acc + pair.0 })
  let r = rand.int(limit=total)
  let mut cumulative = 0
  for _, pair in choices {
    cumulative = cumulative + pair.0
    if r < cumulative {
      return pair.1
    }
  }
  choices[choices.length() - 1].1
}

///|
/// Generate a random duration based on weights
fn random_duration(
  weights : DurationWeights,
  rand : @random.Rand,
) -> NoteDuration {
  weighted_choice(weights.to_choices(), rand)
}

///|
/// Generate a random MIDI number from chord tones
/// Uses chord tones across multiple octaves
fn random_midi_from_chord(chord : Chord, rand : @random.Rand) -> MidiNumber? {
  let base_tones = chord.tones()
  let extended_tones = [-1, 0, 1]
    .iter()
    .flat_map(fn(octave_offset) {
      base_tones
      .iter()
      .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
    })
    .collect()
  let index = rand.int(limit=extended_tones.length())
  Some(extended_tones[index])
}
