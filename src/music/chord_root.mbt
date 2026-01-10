///|
/// Note name enum for type-safe chord roots
pub enum ChordRoot {
  C
  CSharp // C# / Db
  D
  DSharp // D# / Eb
  E
  F
  FSharp // F# / Gb
  G
  GSharp // G# / Ab
  A
  ASharp // A# / Bb
  B
} derive(Eq, Show)

///|
/// Parse string to note name
pub fn ChordRoot::from_string(s : String) -> ChordRoot? {
  match s {
    "C" => Some(C)
    "C#" | "Db" => Some(CSharp)
    "D" => Some(D)
    "D#" | "Eb" => Some(DSharp)
    "E" => Some(E)
    "F" => Some(F)
    "F#" | "Gb" => Some(FSharp)
    "G" => Some(G)
    "G#" | "Ab" => Some(GSharp)
    "A" => Some(A)
    "A#" | "Bb" => Some(ASharp)
    "B" => Some(B)
    _ => None
  }
}

///|
/// Convert note name to MIDI number (octave 4)
pub fn ChordRoot::midi(self : ChordRoot) -> Int {
  let base_octave = 60 // C4
  base_octave +
  (match self {
    C => 0
    CSharp => 1
    D => 2
    DSharp => 3
    E => 4
    F => 5
    FSharp => 6
    G => 7
    GSharp => 8
    A => 9
    ASharp => 10
    B => 11
  })
}
