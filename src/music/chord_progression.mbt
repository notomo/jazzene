///|
/// Chord with type-safe root and quality
pub struct Chord {
  root : ChordRoot
  quality : ChordQuality
} derive(Eq, Show)

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[Int] {
  let root_midi = self.root.midi()
  let intervals = self.quality.intervals()
  intervals.map(fn(interval) { root_midi + interval })
}

///|
/// Helper to safely slice string with custom error message
fn slice_to_string(
  s : String,
  start : Int,
  end : Int,
) -> Result[String, String] {
  (try? s[start:end].to_string()).map_err(fn(e) { "Invalid string slice: \{e}" })
}

///|
/// Helper to convert Option to Result with custom error message
fn[T] option_to_result(opt : T?, error : String) -> Result[T, String] {
  match opt {
    Some(v) => Ok(v)
    None => Err(error)
  }
}

///|
/// Parse a single chord string into a Chord struct
/// Examples: "Cm7" -> Chord { root: C, quality: Minor7 }
///           "F#maj7" -> Chord { root: FSharp, quality: Major7 }
pub fn parse_chord(input : String) -> Result[Chord, String] {
  // Parse root note (1 or 2 characters) using pattern matching
  let (root_str, quality_start) = match input {
    [_, '#', ..] | [_, 'b', ..] =>
      // Two character root (e.g., "F#", "Bb")
      match slice_to_string(input, 0, 2) {
        Ok(s) => (s, 2)
        Err(e) => return Err(e)
      }
    [_, ..] =>
      // Single character root (e.g., "C", "F")
      match slice_to_string(input, 0, 1) {
        Ok(s) => (s, 1)
        Err(e) => return Err(e)
      }
    [] => return Err("Empty chord string")
  }

  // Parse quality from the rest
  let quality_str = if quality_start >= input.length() {
    ""
  } else {
    match slice_to_string(input, quality_start, input.length()) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
  }

  // Convert root string to ChordRoot
  let root = match
    option_to_result(
      ChordRoot::from_string(root_str),
      "Invalid root note: " + root_str,
    ) {
    Ok(r) => r
    Err(e) => return Err(e)
  }

  // Create Chord
  let quality = parse_quality(quality_str)
  Ok(Chord::{ root, quality })
}

///|
/// Parse a chord progression string into an array of chords
/// Example: "Cm7 F7 Bbmaj7 Ebmaj7" -> [Chord, Chord, Chord, Chord]
pub fn parse_chord_progression(input : String) -> Array[Chord] {
  input
  .trim()
  .split(" ")
  .filter_map(fn(raw_chord) {
    match raw_chord.to_string().trim().to_string() {
      "" => None
      s => parse_chord(s).to_option()
    }
  })
  .to_array()
}
