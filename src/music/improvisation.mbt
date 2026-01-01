///|
/// Settings for improvisation generation
pub struct ImprovisationSettings {
  notes_per_measure : Int
} derive(Eq, Show)

///|
/// Default settings: 4 notes per measure
pub fn ImprovisationSettings::default() -> ImprovisationSettings {
  ImprovisationSettings::{ notes_per_measure: 4 }
}

///|
/// Generate improvisation from a chord progression
/// Returns notes with varying durations (eighth, quarter, half)
pub fn generate_improvisation(
  chords : Array[Chord],
  settings : ImprovisationSettings,
) -> Array[Note] {
  let notes : Array[Note] = []
  for chord in chords {
    for _i = 0; _i < settings.notes_per_measure; _i = _i + 1 {
      let midi_number = random_midi_from_chord(chord)
      let duration = random_duration()
      // Create note with validation
      match Note::new(midi_number, duration) {
        Some(note) => notes.push(note)
        None => () // Skip invalid notes
      }
    }
  }
  notes
}

///|
/// Generate random duration
/// Distribution: 20% eighth, 60% quarter, 20% half
fn random_duration() -> NoteDuration {
  let r = global_rand.int(limit=100)
  if r < 20 {
    Eighth
  } else if r < 80 {
    Quarter
  } else {
    Half
  }
}

///|
/// Generate a random MIDI number from chord tones
/// Uses chord tones across multiple octaves (C3-C6, MIDI 48-84)
fn random_midi_from_chord(chord : Chord) -> Int {
  let base_tones = chord.tones()
  if base_tones.length() == 0 {
    return 60 // Fallback to middle C
  }

  // Extend to multiple octaves (octaves 3-5)
  let extended_tones : Array[Int] = []
  for octave_offset in [-12, 0, 12] {
    for tone in base_tones {
      let midi = tone + octave_offset
      if midi >= 48 && midi <= 84 {
        // C3 to C6
        extended_tones.push(midi)
      }
    }
  }

  // Select random note
  let index = global_rand.int(limit=extended_tones.length())
  extended_tones[index]
}

///|
/// Global random number generator
let global_rand : @random.Rand = @random.Rand::chacha8()
