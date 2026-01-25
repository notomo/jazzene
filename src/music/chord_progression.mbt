///|
/// Chord with type-safe root and quality
pub(all) struct Chord {
  root : ChordRoot
  quality : ChordQuality
} derive(Eq, Show)

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let intervals = self.quality.intervals()
  intervals.filter_map(fn(interval) { MidiNumber::new(root_midi + interval) })
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
/// Example: "Cm7 F7 Bbmaj7 Ebmaj7" -> Ok([Chord, Chord, Chord, Chord])
/// Returns Err with error message if any chord fails to parse
pub fn parse_chord_progression(input : String) -> Result[Array[Chord], String] {
  let results = input
    .trim()
    .split(" ")
    .map(fn(token) { token.to_string().trim().to_string() })
    .filter(fn(token) { token != "" })
    .map(fn(token) {
      parse_chord(token).map_err(fn(e) { "Failed to parse '\{token}': \{e}" })
    })
    .collect()
  let errors = results
    .iter()
    .filter_map(fn(r) {
      match r {
        Err(e) => Some(e)
        Ok(_) => None
      }
    })
    .collect()
  match errors {
    [] => Ok(results.iter().filter_map(fn(r) { r.to_option() }).collect())
    messages => Err(messages.join("; "))
  }
}

///|
/// Format complete chord symbol
pub fn format_chord(chord : Chord) -> String {
  chord.root.to_string() + chord.quality.to_string()
}
