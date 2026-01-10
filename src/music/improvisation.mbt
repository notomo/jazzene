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
/// Returns note values (notes and rests) with varying durations
/// Notes are generated to fit exactly within measure boundaries
pub fn generate_improvisation(
  chords : Array[Chord],
  settings : ImprovisationSettings,
) -> Array[NoteValue] {
  let note_values : Array[NoteValue] = []
  let beats_per_measure = settings.notes_per_measure.to_double()

  // Add ~1 measure of rest at the beginning
  note_values.push(NoteValue::Rest(duration=Half))
  note_values.push(NoteValue::Rest(duration=Half))
  for chord in chords {
    // Track remaining beats in current measure
    let mut remaining_beats = beats_per_measure
    while remaining_beats > 0.0 {
      let midi_number = random_midi_from_chord(chord)
      let duration = random_duration_with_limit(remaining_beats)
      match MidiNumber::new(midi_number) {
        Some(x) => {
          note_values.push(NoteValue::Note(midi=x, duration~))
          remaining_beats = remaining_beats - duration.to_beats()
        }
        None => () // Skip invalid notes
      }
    }
  }
  note_values
}

///|
/// Generate random duration that fits within the remaining beats
/// Distribution: 20% eighth, 60% quarter, 20% half (adjusted based on remaining beats)
fn random_duration_with_limit(remaining_beats : Double) -> NoteDuration {
  // Filter available durations based on remaining beats
  let available : Array[NoteDuration] = []
  if remaining_beats >= 2.0 {
    available.push(Half)
  }
  if remaining_beats >= 1.0 {
    available.push(Quarter)
  }
  if remaining_beats >= 0.5 {
    available.push(Eighth)
  }

  // If no durations fit (shouldn't happen), default to smallest
  if available.length() == 0 {
    return Eighth
  }

  // If only one option, return it
  if available.length() == 1 {
    return available[0]
  }

  // Prefer distribution: 20% eighth, 60% quarter, 20% half (when all available)
  let r = global_rand.int(limit=100)
  if available.length() == 3 {
    // All durations available
    if r < 20 {
      Eighth
    } else if r < 80 {
      Quarter
    } else {
      Half
    }
  } else if available.length() == 2 {
    if available.contains(Quarter) && available.contains(Eighth) {
      // Only Quarter and Eighth available
      if r < 25 {
        Eighth
      } else {
        Quarter
      }
      // Half and something else
    } else if r < 50 {
      available[0]
    } else {
      available[1]
    }
  } else {
    available[0]
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
