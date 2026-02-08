///|
/// Chord quality enum for exhaustive matching
pub(all) enum ChordQuality {
  Major7
  Minor7
  Dominant7
  HalfDiminished // m7b5
  Diminished7
  MinorMajor7 // m(maj7)
  Augmented
  AugmentedMajor7 // maj7#5
  Augmented7 // 7#5
  Dominant7sus4 // 7sus4
  Sus4
  Sus2
  Major6
  Minor6
  Major
  Minor
  Diminished // triad
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
    MinorMajor7 => [0, 3, 7, 11]
    Augmented => [0, 4, 8]
    AugmentedMajor7 => [0, 4, 8, 11]
    Augmented7 => [0, 4, 8, 10]
    Dominant7sus4 => [0, 5, 7, 10]
    Sus4 => [0, 5, 7]
    Sus2 => [0, 2, 7]
    Major6 => [0, 4, 7, 9]
    Minor6 => [0, 3, 7, 9]
    Major => [0, 4, 7]
    Minor => [0, 3, 7]
    Diminished => [0, 3, 6]
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
    "mMaj7" | "m(maj7)" | "minMaj7" | "-Maj7" => Ok(MinorMajor7)
    "aug" | "+" => Ok(Augmented)
    "augMaj7" | "maj7#5" | "+maj7" => Ok(AugmentedMajor7)
    "aug7" | "7#5" | "+7" => Ok(Augmented7)
    "7sus4" | "7sus" => Ok(Dominant7sus4)
    "sus4" | "sus" => Ok(Sus4)
    "sus2" => Ok(Sus2)
    "6" | "maj6" => Ok(Major6)
    "m6" | "min6" | "-6" => Ok(Minor6)
    "dim" | "°" => Ok(Diminished)
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
    // 9(2), 11(5) — avoid natural 13 (clashes with major 7th enharmonically)
    MinorMajor7 => [2, 5]
    // 9(2)
    Augmented => [2]
    // 9(2)
    AugmentedMajor7 => [2]
    // 9(2), #11(6) — altered dominant tensions
    Augmented7 => [2, 6]
    // 9(2), 13(9) — sus resolves 3rd, so avoid 3rd-related tensions
    Dominant7sus4 => [2, 9]
    // 9(2), 13(9) — avoid 3rd-related tensions
    Sus4 => [2, 9]
    // 13(9) — avoid 3rd-related tensions
    Sus2 => [9]
    // 9(2), #11(6) — 13 is already a chord tone (6th = 13th)
    Major6 => [2, 6]
    // 9(2), 11(5) — 13 is already a chord tone
    Minor6 => [2, 5]
    // 9(2), #11(6), 13(9)
    Major => [2, 6, 9]
    // 9(2), 11(5), 13(9)
    Minor => [2, 5, 9]
    // Symmetrical structure — limited tensions
    Diminished => []
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
    MinorMajor7 => "m(maj7)"
    Augmented => "aug"
    AugmentedMajor7 => "augMaj7"
    Augmented7 => "aug7"
    Dominant7sus4 => "7sus4"
    Sus4 => "sus4"
    Sus2 => "sus2"
    Major6 => "6"
    Minor6 => "m6"
    Major => ""
    Minor => "m"
    Diminished => "dim"
  }
}
