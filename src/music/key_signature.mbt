///|
/// Key signature representation for music theory
pub(all) struct KeySignature {
  root : ChordRoot
  /// Diatonic steps (0-6) altered by this key, in signature order
  altered_steps : Array[Int]
  accidental_type : Accidental // Sharp, Flat, or Natural (for C)
}

///|
/// Construct a KeySignature from a ChordRoot
pub fn KeySignature::from_root(root : ChordRoot) -> KeySignature {
  let (altered_steps, accidental_type) = match root {
    C => ([], Accidental::Natural)
    G => ([3], Sharp)
    D => ([3, 0], Sharp)
    A => ([3, 0, 4], Sharp)
    E => ([3, 0, 4, 1], Sharp)
    B => ([3, 0, 4, 1, 5], Sharp)
    FSharp => ([3, 0, 4, 1, 5, 2], Sharp)
    F => ([6], Flat)
    ASharp => ([6, 2], Flat) // Bb
    DSharp => ([6, 2, 5], Flat) // Eb
    GSharp => ([6, 2, 5, 1], Flat) // Ab
    CSharp => ([6, 2, 5, 1, 4], Flat) // Db
  }
  KeySignature::{ root, altered_steps, accidental_type }
}

///|
/// Convenience constructor for C major (no sharps or flats)
pub fn KeySignature::c_major() -> KeySignature {
  KeySignature::from_root(C)
}

///|
/// Key-aware mapping from pitch class (0-11) to diatonic step (0-6)
/// In flat keys, altered black-key pitch classes map one step higher than C major default
pub fn KeySignature::pitch_class_to_diatonic_step(
  self : KeySignature,
  pitch_class : Int,
) -> Int {
  // C major default mapping
  let default_step = match pitch_class {
    0 | 1 => 0 // C, C#
    2 | 3 => 1 // D, D#/Eb
    4 => 2 // E
    5 | 6 => 3 // F, F#
    7 | 8 => 4 // G, G#/Ab
    9 | 10 => 5 // A, A#/Bb
    11 => 6 // B
    _ => 0
  }
  // In flat keys, black-key pitch classes that are flattened notes
  // should map to the step above (e.g., Bb is step 6, not step 5)
  match self.accidental_type {
    Flat => {
      // Check if this pitch class is a black key that's an altered note in this key
      let flat_adjustment = match pitch_class {
        1 => 1 // Db -> step 1 (D-flat)
        3 => 2 // Eb -> step 2 (E-flat)
        6 => 3 // Gb -> step 3 (F is step 3, but Gb is step 3+1=... no)
        8 => 5 // Ab -> step 5 (A-flat)
        10 => 6 // Bb -> step 6 (B-flat)
        _ => -1
      }
      if flat_adjustment >= 0 {
        flat_adjustment
      } else {
        default_step
      }
    }
    _ => default_step
  }
}

///|
/// Returns the accidental state for a pitch class in this key
/// Diatonic notes -> Natural; key signature alterations -> Sharp/Flat;
/// Non-diatonic chromatic notes -> Sharp in sharp keys, Flat in flat keys
pub fn KeySignature::pitch_class_accidental(
  self : KeySignature,
  pitch_class : Int,
) -> Accidental {
  let step = self.pitch_class_to_diatonic_step(pitch_class)
  let is_altered_step = self.altered_steps.iter().any(fn(s) { s == step })
  // Check if the pitch class is a "black key" (chromatic)
  let is_black_key = match pitch_class {
    1 | 3 | 6 | 8 | 10 => true
    _ => false
  }
  match (is_black_key, is_altered_step) {
    (false, _) =>
      // White key -> always Natural
      Accidental::Natural
    (true, true) =>
      // Black key on an altered step -> this IS the key signature alteration
      self.accidental_type
    (true, false) =>
      // Black key not in key signature -> chromatic accidental
      // Use the key's accidental preference, or C major defaults for Natural keys
      match self.accidental_type {
        Sharp => Sharp
        Flat => Flat
        Natural =>
          // C major: use traditional accidental assignments
          match pitch_class {
            1 | 6 => Sharp // C#, F#
            _ => Flat // Eb, Ab, Bb
          }
      }
  }
}

///|
/// MIDI positions for rendering key signature on treble clef staff
pub fn KeySignature::signature_midi_positions(
  self : KeySignature,
) -> Array[Int] {
  let sharp_positions = [77, 72, 79, 74, 69, 76, 71] // F5, C5, G5, D5, A4, E5, B4
  let flat_positions = [71, 76, 69, 74, 67, 72, 65] // B4, E5, A4, D5, G4, C5, F4
  let count = self.altered_steps.length()
  let positions = match self.accidental_type {
    Sharp => sharp_positions
    Flat => flat_positions
    Natural => return []
  }
  positions.iter().take(count).collect()
}

///|
/// All 12 keys in circle-of-fifths order for UI dropdown
pub fn KeySignature::all_roots() -> Array[ChordRoot] {
  [C, F, ASharp, DSharp, GSharp, CSharp, FSharp, B, E, A, D, G]
}
