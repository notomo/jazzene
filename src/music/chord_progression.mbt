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
/// Format complete chord symbol
pub fn format_chord(chord : Chord) -> String {
  chord.root.to_string() + chord.quality.to_string()
}

///|
/// Get tension tones (9th, 11th, 13th) as MIDI numbers in octave 4
pub fn Chord::tension_tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let tensions = self.quality.tensions()
  tensions.filter_map(fn(interval) { MidiNumber::new(root_midi + interval) })
}

///|
/// Get chromatic approach tones (half-step above and below each chord tone)
/// Returns MIDI numbers that are NOT already chord tones
pub fn Chord::approach_tones(self : Chord) -> Array[MidiNumber] {
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  self
  .tones()
  .iter()
  .flat_map(fn(tone) {
    // Half-step below and above each chord tone
    [tone.value - 1, tone.value + 1]
    .iter()
    .filter_map(fn(v) {
      match MidiNumber::new(v) {
        None => None
        Some(midi) =>
          // Exclude if it's already a chord tone
          if chord_pitch_classes.contains(midi.pitch_class()) {
            None
          } else {
            Some(midi)
          }
      }
    })
  })
  .collect()
}

///|
/// Get diatonic scale tones that are NOT chord tones for the given key
/// Returns non-chord scale degrees in octave 4
pub fn Chord::scale_tones(
  self : Chord,
  key : KeySignature,
) -> Array[MidiNumber] {
  let major_scale_intervals = [0, 2, 4, 5, 7, 9, 11]
  let root_midi = key.root.midi()
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  major_scale_intervals
  .iter()
  .filter_map(fn(interval) {
    let midi_value = root_midi + interval
    let pitch_class = midi_value % 12
    guard not(chord_pitch_classes.contains(pitch_class)) else { return None }
    MidiNumber::new(midi_value)
  })
  .collect()
}

///|
/// Scale degree in a major scale
pub(all) enum ScaleDegree {
  I
  II
  III
  IV
  V
  VI
  VII
} derive(Eq, Show)

///|
/// Semitone offset from the root for each scale degree in a major scale
pub fn ScaleDegree::semitones(self : ScaleDegree) -> Int {
  match self {
    I => 0
    II => 2
    III => 4
    IV => 5
    V => 7
    VI => 9
    VII => 11
  }
}

///|
/// A chord expressed as a scale degree with optional accidental
pub(all) struct DegreeChord {
  accidental : Int // -1 for flat, 0 for natural, +1 for sharp
  degree : ScaleDegree
  quality : ChordQuality
} derive(Eq, Show)

///|
/// Parse a Roman numeral from the beginning of a string.
/// Returns the ScaleDegree and the remaining string.
fn parse_roman_numeral(input : String) -> Result[(ScaleDegree, String), String] {
  match input {
    ['V' | 'v', 'I' | 'i', 'I' | 'i', .. rest] => Ok((VII, rest.to_string()))
    ['V' | 'v', 'I' | 'i', .. rest] => Ok((VI, rest.to_string()))
    ['I' | 'i', 'V' | 'v', .. rest] => Ok((IV, rest.to_string()))
    ['V' | 'v', .. rest] => Ok((V, rest.to_string()))
    ['I' | 'i', 'I' | 'i', 'I' | 'i', .. rest] => Ok((III, rest.to_string()))
    ['I' | 'i', 'I' | 'i', .. rest] => Ok((II, rest.to_string()))
    ['I' | 'i', .. rest] => Ok((I, rest.to_string()))
    _ => Err("Invalid Roman numeral in: " + input)
  }
}

///|
/// Parse a single degree chord string (e.g., "IIm7", "bVIImaj7", "#IVm7b5")
pub fn parse_degree_chord(input : String) -> Result[DegreeChord, String] {
  if input == "" {
    return Err("Empty degree chord string")
  }
  // Parse optional accidental prefix
  let (accidental, rest) = match input {
    ['b', .. tail] => (-1, tail.to_string())
    ['#', .. tail] => (1, tail.to_string())
    _ => (0, input)
  }
  // Parse Roman numeral
  let (degree, quality_str) = match parse_roman_numeral(rest) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  // Parse quality suffix
  let quality = match parse_quality(quality_str) {
    Ok(q) => q
    Err(e) => return Err(e)
  }
  Ok(DegreeChord::{ accidental, degree, quality })
}

///|
/// Parse a space-separated degree chord progression
pub fn parse_degree_progression(
  input : String,
) -> Result[Array[DegreeChord], String] {
  let results = input
    .trim()
    .split(" ")
    .map(fn(token) { token.to_string().trim().to_string() })
    .filter(fn(token) { token != "" })
    .map(fn(token) {
      parse_degree_chord(token).map_err(fn(e) {
        "Failed to parse '\{token}': \{e}"
      })
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
/// Resolve a degree chord to an absolute chord given a key root
pub fn DegreeChord::resolve(self : DegreeChord, key_root : ChordRoot) -> Chord {
  let root_pc = (key_root.midi() + self.degree.semitones() + self.accidental) %
    12
  let root = ChordRoot::from_pitch_class(root_pc)
  Chord::{ root, quality: self.quality }
}

///|
/// A single measure containing one or more degree chords
pub(all) struct DegreeMeasure {
  chords : Array[DegreeChord]
} derive(Eq, Show)

///|
/// Resolve all chords in a measure to absolute chords
pub fn DegreeMeasure::resolve(
  self : DegreeMeasure,
  key_root : ChordRoot,
) -> Array[Chord] {
  self.chords.map(fn(dc) { dc.resolve(key_root) })
}

///|
/// Parse a measure progression with `|` as measure delimiter.
/// Returns array of DegreeMeasure, each containing one or more chords.
pub fn parse_measure_progression(
  input : String,
) -> Result[Array[DegreeMeasure], String] {
  let trimmed = input.trim().to_string()
  if trimmed == "" {
    return Ok([])
  }
  let measure_strs = trimmed
    .split("|")
    .map(fn(s) { s.to_string().trim().to_string() })
    .collect()
  let results : Array[Result[DegreeMeasure, String]] = measure_strs
    .iter()
    .mapi(fn(i, measure_str) {
      if measure_str == "" {
        return Err("Empty measure at position \{i + 1}")
      }
      parse_degree_progression(measure_str).map(fn(chords) {
        DegreeMeasure::{ chords, }
      })
    })
    .collect()
  let errors : Array[String] = results
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
