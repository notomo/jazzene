///|
/// Chord quality enum for exhaustive matching
pub enum ChordQuality {
  Major7
  Minor7
  Dominant7
  HalfDiminished // m7b5
  Diminished7
  Augmented
  Sus4
  Major
  Minor
} derive(Eq, Show)

///|
/// Get chord tone intervals for a quality
pub fn ChordQuality::intervals(self : ChordQuality) -> Array[Int] {
  match self {
    Major7 => [0, 4, 7, 11]
    Minor7 => [0, 3, 7, 10]
    Dominant7 => [0, 4, 7, 10]
    Diminished7 => [0, 3, 6, 9]
    HalfDiminished => [0, 3, 6, 10]
    Augmented => [0, 4, 8]
    Sus4 => [0, 5, 7]
    Major => [0, 4, 7]
    Minor => [0, 3, 7]
  }
}

///|
/// Parse quality string to ChordQuality enum
pub fn parse_quality(quality : String) -> ChordQuality {
  match quality {
    "maj7" | "M7" | "Δ7" | "△7" => Major7
    "m7" | "min7" | "-7" => Minor7
    "7" | "dom7" => Dominant7
    "dim7" | "°7" => Diminished7
    "m7b5" | "m7♭5" | "ø7" | "half-dim" => HalfDiminished
    "aug" | "+" => Augmented
    "sus4" | "sus" => Sus4
    "m" | "min" | "-" => Minor
    "" | "maj" | "M" => Major
    _ => Major // default to major if unknown
  }
}
