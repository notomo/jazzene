///|
/// Chord quality enum for exhaustive matching
pub(all) enum ChordQuality {
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
pub fn parse_quality(quality : String) -> Result[ChordQuality, String] {
  match quality {
    "maj7" | "M7" | "Δ7" | "△7" => Ok(Major7)
    "m7" | "min7" | "-7" => Ok(Minor7)
    "7" | "dom7" => Ok(Dominant7)
    "dim7" | "°7" => Ok(Diminished7)
    "m7b5" | "m7♭5" | "ø7" | "half-dim" => Ok(HalfDiminished)
    "aug" | "+" => Ok(Augmented)
    "sus4" | "sus" => Ok(Sus4)
    "m" | "min" | "-" => Ok(Minor)
    "" | "maj" | "M" => Ok(Major)
    _ => Err("Unknown chord quality: " + quality)
  }
}

///|
/// Get available tension intervals (9th, 11th, 13th) for a quality.
/// Returns pitch classes (0-11) representing jazz-appropriate tensions.
/// These are chord extensions that add color without clashing with chord tones.
pub fn ChordQuality::tensions(self : ChordQuality) -> Array[Int] {
  match self {
    // 9(2), #11(6), 13(9) — avoid natural 11 (clashes with major 3rd)
    Major7 => [2, 6, 9]
    // 9(2), 11(5), 13(9) — all natural tensions work
    Minor7 => [2, 5, 9]
    // 9(2), #11(6), 13(9) — standard "inside" dominant tensions
    Dominant7 => [2, 6, 9]
    // 9(2), 11(5), b13(8)
    HalfDiminished => [2, 5, 8]
    // Symmetrical chord — no standard tensions
    Diminished7 => []
    // 9(2)
    Augmented => [2]
    // 9(2), 13(9) — avoid 3rd-related tensions
    Sus4 => [2, 9]
    // 9(2), #11(6), 13(9)
    Major => [2, 6, 9]
    // 9(2), 11(5), 13(9)
    Minor => [2, 5, 9]
  }
}

///|
/// Convert chord quality to display string
pub fn ChordQuality::to_string(self : ChordQuality) -> String {
  match self {
    Major7 => "maj7"
    Minor7 => "m7"
    Dominant7 => "7"
    HalfDiminished => "m7♭5"
    Diminished7 => "°7"
    Augmented => "aug"
    Sus4 => "sus4"
    Major => ""
    Minor => "m"
  }
}
