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
/// Parse a single chord string into a Chord struct
pub fn parse_chord(input : String) -> Result[Chord, String] {
  let (root_str, quality_start) = match input {
    [_, '#', ..] | [_, 'b', ..] =>
      // Two character root (e.g., "F#", "Bb")
      try input[0:2] catch {
        e => return Err("Invalid string slice: \{e}")
      } noraise {
        s => (s.to_string(), 2)
      }
    [_, ..] =>
      // Single character root (e.g., "C", "F")
      try input[0:1] catch {
        e => return Err("Invalid string slice: \{e}")
      } noraise {
        s => (s.to_string(), 1)
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
  let root = match ChordRoot::from_string(root_str) {
    Ok(r) => r
    Err(e) => return Err(e)
  }

  // Parse chord quality
  let quality = match parse_quality(quality_str) {
    Ok(q) => q
    Err(e) => return Err(e)
  }

  // Create Chord
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
