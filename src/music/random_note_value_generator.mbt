///|
/// Type alias for a generator function that produces NoteValues
pub type NoteValueGenerator = () -> NoteValue

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
/// Generate a random duration based on weights
fn random_duration(
  weights : DurationWeights,
  rand : @random.Rand,
) -> NoteDuration {
  let total = weights.eighth +
    weights.dotted_eighth +
    weights.quarter +
    weights.dotted_quarter +
    weights.half +
    weights.dotted_half +
    weights.whole
  let r = rand.int(limit=total)
  let mut threshold = weights.eighth
  guard r >= threshold else { return Eighth }
  threshold = threshold + weights.dotted_eighth
  guard r >= threshold else { return DottedEighth }
  threshold = threshold + weights.quarter
  guard r >= threshold else { return Quarter }
  threshold = threshold + weights.dotted_quarter
  guard r >= threshold else { return DottedQuarter }
  threshold = threshold + weights.half
  guard r >= threshold else { return Half }
  threshold = threshold + weights.dotted_half
  guard r >= threshold else { return DottedHalf }
  Whole
}

///|
/// Generate a random MIDI number from chord tones
/// Uses chord tones across multiple octaves (C3-C6, MIDI 48-84)
fn random_midi_from_chord(chord : Chord, rand : @random.Rand) -> MidiNumber? {
  let base_tones = chord.tones()
  guard base_tones.length() > 0 else { return MidiNumber::new(60) } // Fallback to middle C
  // Extend to multiple octaves (octaves 3-5)
  let extended_tones : Array[Int] = [-12, 0, 12]
    .iter()
    .flat_map(fn(octave_offset) {
      base_tones
      .iter()
      .filter_map(fn(tone) {
        let midi = tone + octave_offset
        match midi >= 48 && midi <= 84 {
          true => Some(midi)
          false => None
        }
      })
    })
    .collect()
  let index = rand.int(limit=extended_tones.length())
  MidiNumber::new(extended_tones[index])
}
