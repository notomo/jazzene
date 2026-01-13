///|
/// Convert an integer seed to a 32-byte seed for ChaCha8 RNG
/// The seed is distributed across the 32 bytes using little-endian encoding
fn seed_to_bytes(seed : Int) -> Bytes {
  let seed_bytes = FixedArray::make(32, b'\x00')
  let seed_uint = seed.reinterpret_as_uint()

  // Write the seed as 8 consecutive 32-bit integers (little-endian)
  // This ensures good distribution even for small seed values
  for i = 0; i < 8; {
    seed_bytes.unsafe_write_uint32_le(
      i * 4,
      seed_uint + i.reinterpret_as_uint(),
    )
    continue i + 1
  }
  seed_bytes.unsafe_reinterpret_as_bytes()
}

///|
/// Settings for improvisation generation
pub(all) struct ImprovisationSettings {
  notes_per_measure : Int
  seed : Int
} derive(Eq, Show)

///|
/// Default settings: 4 notes per measure, seed 0
pub fn ImprovisationSettings::default() -> ImprovisationSettings {
  ImprovisationSettings::{ notes_per_measure: 4, seed: 0 }
}

///|
/// Generate improvisation from a chord progression with a specific seed
/// Returns note values (notes and rests) with varying durations
/// Notes are generated to fit exactly within measure boundaries
/// Using the same seed with the same chords produces the same improvisation
pub fn generate_improvisation(
  chords : Array[Chord],
  settings : ImprovisationSettings,
) -> Array[NoteValue] {
  // Create a seeded RNG for deterministic generation
  let rand = @random.Rand::chacha8(seed=seed_to_bytes(settings.seed))
  let note_values : Array[NoteValue] = []
  let beats_per_measure = settings.notes_per_measure.to_double()

  // Add ~1 measure of rest at the beginning
  note_values.push(NoteValue::Rest(duration=Half))
  note_values.push(NoteValue::Rest(duration=Half))
  for chord in chords {
    // Track remaining beats in current measure
    let mut remaining_beats = beats_per_measure
    while remaining_beats > 0.0 {
      let duration = random_duration_with_limit(remaining_beats, rand)

      // 25% chance to generate a rest instead of a note
      let is_rest = rand.int(limit=100) < 25
      if is_rest {
        note_values.push(NoteValue::Rest(duration~))
        remaining_beats = remaining_beats - duration.to_beats()
      } else {
        let midi_number = random_midi_from_chord(chord, rand)
        match MidiNumber::new(midi_number) {
          Some(x) => {
            note_values.push(NoteValue::Note(midi=x, duration~))
            remaining_beats = remaining_beats - duration.to_beats()
          }
          None => () // Skip invalid notes
        }
      }
    }
  }
  note_values
}

///|
/// Generate random duration that fits within the remaining beats
/// Distribution includes dotted notes for rhythmic variety
fn random_duration_with_limit(
  remaining_beats : Double,
  rand : @random.Rand,
) -> NoteDuration {
  // Filter available durations based on remaining beats
  let available : Array[NoteDuration] = []
  if remaining_beats >= 3.0 {
    available.push(DottedHalf)
  }
  if remaining_beats >= 2.0 {
    available.push(Half)
  }
  if remaining_beats >= 1.5 {
    available.push(DottedQuarter)
  }
  if remaining_beats >= 1.0 {
    available.push(Quarter)
  }
  if remaining_beats >= 0.75 {
    available.push(DottedEighth)
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

  // Weighted distribution for rhythmic variety
  // Preferred: 40% Quarter, 20% DottedQuarter, 15% Eighth, 10% DottedEighth, 10% Half, 5% DottedHalf
  let r = rand.int(limit=100)

  // When all 6 durations are available
  if available.length() == 6 {
    if r < 15 {
      Eighth
    } else if r < 25 {
      DottedEighth
    } else if r < 65 {
      Quarter
    } else if r < 85 {
      DottedQuarter
    } else if r < 95 {
      Half
    } else {
      DottedHalf
    }
  } else {
    // For partial availability, pick uniformly from available options
    // This keeps the code simple while still introducing variety
    let index = rand.int(limit=available.length())
    available[index]
  }
}

///|
/// Generate a random MIDI number from chord tones
/// Uses chord tones across multiple octaves (C3-C6, MIDI 48-84)
fn random_midi_from_chord(chord : Chord, rand : @random.Rand) -> Int {
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
  let index = rand.int(limit=extended_tones.length())
  extended_tones[index]
}
