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
  let index = random_int(extended_tones.length())
  Note::from_midi(extended_tones[index])
}

///| Simple pseudo-random number generator

///|
/// Returns a value in [0, max)
fn random_int(max : Int) -> Int {
  if max <= 0 {
    return 0
  }
  // Simple LCG (Linear Congruential Generator)
  // Note: This is deterministic. For true randomness, we'd need JS FFI to Math.random()
  let seed = get_and_update_seed()
  (seed % max + max) % max
}

///| Global seed for pseudo-random number generation

///| In a real implementation, this would be initialized with JS Date.now()

///| Note: MoonBit doesn't support mutable let bindings in this context,

///|
/// so we use a simple stateless PRNG based on time or counter
priv struct SeedRef {
  mut val : Int
}

///|
let global_seed_ref : SeedRef = { val: 12345 }

///|
fn get_and_update_seed() -> Int {
  let a = 1103515245
  let c = 12345
  let m = 0x7FFFFFFF // 2^31 - 1
  let new_seed = (a * global_seed_ref.val + c) % m
  global_seed_ref.val = new_seed
  new_seed
}

///|
/// Initialize random seed (call this from main with JS timestamp)
pub fn init_random_seed(seed : Int) -> Unit {
  global_seed_ref.val = seed
}
