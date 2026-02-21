///|
/// Chord with type-safe root and quality, optional bass for slash chords
pub(all) struct Chord {
  root : ChordRoot
  quality : ChordQuality
  bass : ChordRoot?
} derive(Eq, Show)

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let intervals = self.quality.intervals()
  intervals.filter_map(fn(interval) { MidiNumber::new(root_midi + interval) })
}

///|
/// Transpose a chord's root by a semitone offset
pub fn Chord::transpose(self : Chord, offset : Int) -> Chord {
  let new_pc = (self.root.midi() - 60 + offset + 120) % 12
  let new_root = ChordRoot::from_pitch_class(new_pc)
  let new_bass = self.bass.map(fn(b) {
    let bp = (b.midi() - 60 + offset + 120) % 12
    ChordRoot::from_pitch_class(bp)
  })
  Chord::{ root: new_root, quality: self.quality, bass: new_bass }
}

///|
/// Format complete chord symbol
pub fn format_chord(chord : Chord) -> String {
  let base = chord.root.to_string() + chord.quality.to_string()
  match chord.bass {
    None => base
    Some(bass) => base + "/" + bass.to_string()
  }
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
/// Get scale tones for this chord using chord-scale theory.
/// Uses the appropriate scale for the chord quality (e.g., Dorian for m7, Mixolydian for 7).
/// Returns non-chord-tone scale degrees built from the chord root.
/// The key parameter is retained for API compatibility.
pub fn Chord::scale_tones(
  self : Chord,
  _key : KeySignature,
) -> Array[MidiNumber] {
  let chord_scale = self.quality.chord_scale()
  let scale_intervals = chord_scale.intervals()
  let root_midi = self.root.midi()
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  scale_intervals
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
/// Bass note expressed as a scale degree with optional accidental
pub(all) struct DegreeBass {
  accidental : Int // -1 for flat, 0 for natural, +1 for sharp
  degree : ScaleDegree
} derive(Eq, Show)

///|
/// A chord expressed as a scale degree with optional accidental
pub(all) struct DegreeChord {
  accidental : Int // -1 for flat, 0 for natural, +1 for sharp
  degree : ScaleDegree
  quality : ChordQuality
  bass : DegreeBass?
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
/// Parse bass part after "/" (e.g., "I", "bVII", "#IV")
fn parse_degree_bass(input : String) -> Result[DegreeBass, String] {
  if input == "" {
    return Err("Empty bass degree string")
  }
  let (accidental, rest) = match input {
    ['b', .. tail] => (-1, tail.to_string())
    ['#', .. tail] => (1, tail.to_string())
    _ => (0, input)
  }
  let (degree, remainder) = match parse_roman_numeral(rest) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  if remainder != "" {
    return Err("Unexpected characters after bass degree: " + remainder)
  }
  Ok(DegreeBass::{ accidental, degree })
}

///|
/// Parse a single degree chord string (e.g., "IIm7", "bVIImaj7", "#IVm7b5", "V7/II")
pub fn parse_degree_chord(input : String) -> Result[DegreeChord, String] {
  if input == "" {
    return Err("Empty degree chord string")
  }
  let parts : Array[String] = input
    .split("/")
    .map(fn(s) { s.to_string() })
    .collect()
  let (chord_part, bass) = match parts {
    [chord_str] => (chord_str, None)
    [chord_str, bass_str] =>
      match parse_degree_bass(bass_str) {
        Ok(b) => (chord_str, Some(b))
        Err(e) => return Err(e)
      }
    _ => return Err("Multiple '/' in chord: " + input)
  }

  // Parse optional accidental prefix
  let (accidental, rest) = match chord_part {
    ['b', .. tail] => (-1, tail.to_string())
    ['#', .. tail] => (1, tail.to_string())
    _ => (0, chord_part)
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
  Ok(DegreeChord::{ accidental, degree, quality, bass })
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

  let bass = self.bass.map(fn(b) {
    let bass_pc = (key_root.midi() + b.degree.semitones() + b.accidental) % 12
    ChordRoot::from_pitch_class(bass_pc)
  })
  Chord::{ root, quality: self.quality, bass }
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
