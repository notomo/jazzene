///|
/// Note name enum for type-safe chord roots
pub enum NoteName {
  C
  CSharp // C# / Db
  D
  DSharp // D# / Eb
  E
  F
  FSharp // F# / Gb
  G
  GSharp // G# / Ab
  A
  ASharp // A# / Bb
  B
} derive(Eq, Show)

///|
/// Parse string to note name
pub fn NoteName::from_string(s : String) -> NoteName? {
  match s {
    "C" => Some(C)
    "C#" | "Db" => Some(CSharp)
    "D" => Some(D)
    "D#" | "Eb" => Some(DSharp)
    "E" => Some(E)
    "F" => Some(F)
    "F#" | "Gb" => Some(FSharp)
    "G" => Some(G)
    "G#" | "Ab" => Some(GSharp)
    "A" => Some(A)
    "A#" | "Bb" => Some(ASharp)
    "B" => Some(B)
    _ => None
  }
}

///|
/// Convert note name to MIDI number (octave 4)
pub fn NoteName::to_midi(self : NoteName) -> Int {
  let base_octave = 60 // C4
  base_octave +
  (match self {
    C => 0
    CSharp => 1
    D => 2
    DSharp => 3
    E => 4
    F => 5
    FSharp => 6
    G => 7
    GSharp => 8
    A => 9
    ASharp => 10
    B => 11
  })
}

///|
/// Chord with type-safe root and quality
pub struct Chord {
  root : NoteName
  quality : ChordQuality
} derive(Eq, Show)

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[Int] {
  let root_midi = self.root.to_midi()
  let intervals = self.quality.intervals()
  intervals.map(fn(interval) { root_midi + interval })
}

///|
/// Parse a single chord string into a Chord struct
/// Examples: "Cm7" -> Chord { root: C, quality: Minor7 }
///           "F#maj7" -> Chord { root: FSharp, quality: Major7 }
pub fn parse_chord(input : String) -> Result[Chord, String] {
  if input.length() == 0 {
    return Err("Empty chord string")
  }

  // Parse root note (1 or 2 characters)
  let (root_str, quality_start) = if input.length() >= 2 &&
    (input[1] == '#' || input[1] == 'b') {
    // Two character root (e.g., "F#", "Bb")
    let c1 = input[0].to_int().unsafe_to_char()
    let c2 = input[1].to_int().unsafe_to_char()
    (c1.to_string() + c2.to_string(), 2)
  } else {
    // Single character root (e.g., "C", "F")
    (input[0].to_int().unsafe_to_char().to_string(), 1)
  }

  // Parse quality from the rest
  let quality_str = if quality_start >= input.length() {
    ""
  } else {
    substring_from(input, quality_start)
  }

  // Convert root string to NoteName
  let root = match NoteName::from_string(root_str) {
    Some(name) => name
    None => return Err("Invalid root note: " + root_str)
  }

  // Parse quality string to ChordQuality
  let quality = parse_quality(quality_str)
  Ok(Chord::{ root, quality })
}

///|
/// Helper to get substring from index to end
fn substring_from(s : String, start : Int) -> String {
  let mut result = ""
  for i = start; i < s.length(); i = i + 1 {
    result = result + s[i].to_int().unsafe_to_char().to_string()
  }
  result
}

///|
/// Parse a chord progression string into an array of chords
/// Example: "Cm7 F7 Bbmaj7 Ebmaj7" -> [Chord, Chord, Chord, Chord]
pub fn parse_chord_progression(input : String) -> Array[Chord] {
  let trimmed = input.trim()
  if trimmed.length() == 0 {
    return []
  }
  let chord_strings = trimmed.split(" ")
  let chords : Array[Chord] = []
  for chord_str_view in chord_strings {
    let chord_str_untrimmed = chord_str_view.to_string()
    let chord_str_trimmed_view = chord_str_untrimmed.trim()
    let chord_str = chord_str_trimmed_view.to_string()
    if chord_str.length() > 0 {
      match parse_chord(chord_str) {
        Ok(chord) => chords.push(chord)
        Err(_) => () // Skip invalid chords
      }
    }
  }
  chords
}
