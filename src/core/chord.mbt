///| Parse a single chord string into a Chord struct

///| Examples: "Cm7" -> Chord { root: "C", quality: "m7" }

///|
///          "F#maj7" -> Chord { root: "F#", quality: "maj7" }
pub fn parse_chord(input : String) -> Result[Chord, String] {
  if input.length() == 0 {
    return Err("Empty chord string")
  }

  // Parse root note (1 or 2 characters)
  let (root, quality_start) = if input.length() >= 2 &&
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
  let quality = normalize_quality(quality_str)
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
/// Normalize chord quality strings to canonical forms
fn normalize_quality(quality : String) -> String {
  match quality {
    "maj7" | "M7" | "Δ7" | "△7" => "maj7"
    "m7" | "min7" | "-7" => "m7"
    "7" | "dom7" => "7"
    "dim7" | "°7" => "dim7"
    "m7b5" | "m7♭5" | "ø7" | "half-dim" => "m7b5"
    "aug" | "+" => "aug"
    "sus4" | "sus" => "sus4"
    "" | "maj" | "M" => "" // major triad
    "m" | "min" | "-" => "m"
    _ => quality // keep as-is if unknown
  }
}

///| Parse a chord progression string into an array of chords

///|
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
