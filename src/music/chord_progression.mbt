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
/// Parse a single chord string into a Chord struct
pub fn parse_chord(input : String) -> Result[Chord, String] {
  let (root_str, quality_str) = match input {
    [c1, c2, .. tail] if ['#', 'b'].contains(c2) =>
      // e.g., "F#", "Bb"
      (c1.to_string() + c2.to_string(), tail.to_string())
    [c1, .. tail] =>
      // e.g., "C", "F"
      (c1.to_string(), tail.to_string())
    [] => return Err("Empty chord string")
  }
  let root = match ChordRoot::from_string(root_str) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  let quality = match parse_quality(quality_str) {
    Ok(q) => q
    Err(e) => return Err(e)
  }
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
