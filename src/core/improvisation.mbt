///|
/// Settings for improvisation generation
pub struct ImprovisationSettings {
  notes_per_measure : Int
  // FUTURE: Add rhythm_pattern, scale_mode, etc.
} derive(Eq, Show)

///|
/// Default settings: 4 quarter notes per measure
pub fn ImprovisationSettings::default() -> ImprovisationSettings {
  ImprovisationSettings::{ notes_per_measure: 4 }
}

///| Generate improvisation from a chord progression

///|
/// Initial implementation: 1 measure per chord, random notes from chord tones
pub fn generate_improvisation(
  chords : Array[Chord],
  settings : ImprovisationSettings,
) -> Array[Note] {
  let notes : Array[Note] = []
  for chord in chords {
    for _i = 0; _i < settings.notes_per_measure; _i = _i + 1 {
      let note = random_note_from_chord(chord)
      notes.push(note)
    }
  }
  notes
}

///| Generate a random note from chord tones

///|
/// Uses simple random selection from chord tones across multiple octaves
fn random_note_from_chord(chord : Chord) -> Note {
  let base_tones = chord.tones()
  if base_tones.length() == 0 {
    return Note::from_midi(60) // Fallback to middle C
  }

  // Extend to multiple octaves (octaves 3-5)
  let extended_tones : Array[Int] = []
  for octave_offset in [-12, 0, 12] {
    for tone in base_tones {
      let midi = tone + octave_offset
      if midi >= 48 && midi <= 84 { // C3 to C6
        extended_tones.push(midi)
      }
    }
  }

  // Select random note
  let index = global_rand.int(limit=extended_tones.length())
  Note::from_midi(extended_tones[index])
}

///| Global random number generator

///|
let global_rand : @random.Rand = @random.Rand::chacha8()
