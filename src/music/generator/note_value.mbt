///|
/// Settings for the note value generator
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
/// Create a note value generator from settings
/// Returns a closure that generates one NoteValue per call, cycling through chords
pub fn create_note_value_generator(settings : Settings) -> NoteValueGenerator {
  let random_int = create_random_int(settings.seed)
  let mut chord_index = 0
  fn() {
    let chord = match settings.chords.length() {
      0 => @music.Chord::{ root: @music.C, quality: @music.Major7 } // Fallback chord
      _ => settings.chords[chord_index % settings.chords.length()]
    }
    chord_index = chord_index + 1
    let duration = random_duration(settings.duration_weights, random_int)
    match decide_midi_number(chord, settings.rest_probability, random_int) {
      Some(midi) => @music.NoteValue::Note(midi~, duration~)
      None => @music.NoteValue::Rest(duration~)
    }
  }
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
