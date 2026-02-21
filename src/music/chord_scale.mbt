///|
/// Chord scale theory: maps chord qualities to their corresponding scales.
/// Each chord quality has an appropriate scale that fits harmonically.
/// Based on standard jazz chord-scale theory (e.g., Dorian for IIm7, Mixolydian for V7).
pub(all) enum ChordScale {
  Ionian // Major scale (Imaj7)
  Dorian // Dorian mode (IIm7)
  Phrygian // Phrygian mode (IIIm7)
  Lydian // Lydian mode (IVmaj7)
  Mixolydian // Mixolydian mode (V7)
  Aeolian // Natural minor / Aeolian (VIm7)
  Locrian // Locrian mode (VIIm7b5)
  LydianDominant // Lydian b7 (subV7, tritone substitution)
  Altered // Altered scale / Super-Locrian (V7alt)
  Diminished // Half-whole diminished (dim7)
  WholeTone // Whole-tone scale (aug, 7#5)
  BebopDominant // Mixolydian + major 7 passing tone (V7 bebop)
  BebopMajor // Ionian + #5 passing tone (Imaj7 bebop)
  HarmonicMinor // Harmonic minor (m(maj7))
  MelodicMinor // Melodic minor ascending (mMaj7, m6)
} derive(Eq, Show)

///|
/// Scale intervals (semitones from root) for each ChordScale.
/// Standard 7-note scales unless noted (bebop scales have 8 notes).
pub fn ChordScale::intervals(self : ChordScale) -> Array[Int] {
  match self {
    // 1  2  3  4  5  6  7
    Ionian => [0, 2, 4, 5, 7, 9, 11]
    // 1  2 b3  4  5  6 b7
    Dorian => [0, 2, 3, 5, 7, 9, 10]
    // 1 b2 b3  4  5 b6 b7
    Phrygian => [0, 1, 3, 5, 7, 8, 10]
    // 1  2  3 #4  5  6  7
    Lydian => [0, 2, 4, 6, 7, 9, 11]
    // 1  2  3  4  5  6 b7
    Mixolydian => [0, 2, 4, 5, 7, 9, 10]
    // 1  2 b3  4  5 b6 b7
    Aeolian => [0, 2, 3, 5, 7, 8, 10]
    // 1 b2 b3  4 b5 b6 b7
    Locrian => [0, 1, 3, 5, 6, 8, 10]
    // 1  2  3 #4  5  6 b7  (Lydian b7 / Overtone scale)
    LydianDominant => [0, 2, 4, 6, 7, 9, 10]
    // 1 b2 b3 b4 b5 b6 b7  (Altered / Super-Locrian)
    Altered => [0, 1, 3, 4, 6, 8, 10]
    // 1  2 b3  3  4 b5  5  6 b7  7  (actually 10-note but standard jazz form:)
    // Half-whole diminished: 1 b2 b3  3 b5  5  6 b7
    Diminished => [0, 1, 3, 4, 6, 7, 9, 10]
    // 1  2  3 b5 b6 b7  (Whole-tone: 6 notes)
    WholeTone => [0, 2, 4, 6, 8, 10]
    // Mixolydian + major 7th passing tone (8-note bebop dominant)
    // 1  2  3  4  5  6 b7  7
    BebopDominant => [0, 2, 4, 5, 7, 9, 10, 11]
    // Ionian + #5 passing tone (8-note bebop major)
    // 1  2  3  4  5 #5  6  7
    BebopMajor => [0, 2, 4, 5, 7, 8, 9, 11]
    // 1  2 b3  4  5 b6  7  (Harmonic minor)
    HarmonicMinor => [0, 2, 3, 5, 7, 8, 11]
    // 1  2 b3  4  5  6  7  (Melodic minor ascending)
    MelodicMinor => [0, 2, 3, 5, 7, 9, 11]
  }
}

///|
/// Determine the appropriate chord scale for a given chord quality.
/// Based on standard jazz chord-scale theory.
pub fn ChordQuality::chord_scale(self : ChordQuality) -> ChordScale {
  match self {
    Major7 => Ionian
    AugmentedMajor7 => LydianDominant // or Lydian; LydianDominant fits the #5
    Minor7 => Dorian
    Dominant7 => Mixolydian
    HalfDiminished => Locrian
    Diminished7 => Diminished
    MinorMajor7 => MelodicMinor
    Augmented => WholeTone
    Augmented7 => WholeTone
    Dominant7sus4 => Mixolydian
    Sus4 => Mixolydian
    Sus2 => Ionian
    Major6 => Ionian
    Minor6 => MelodicMinor
    Major => Ionian
    Minor => Aeolian
    Diminished => Diminished
  }
}
