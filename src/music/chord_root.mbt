///|
/// Note name enum for type-safe chord roots
pub(all) enum ChordRoot {
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
pub fn ChordRoot::from_string(s : String) -> Result[ChordRoot, String] {
  match s {
    "C" => Ok(C)
    "C#" | "Db" => Ok(CSharp)
    "D" => Ok(D)
    "D#" | "Eb" => Ok(DSharp)
    "E" => Ok(E)
    "F" => Ok(F)
    "F#" | "Gb" => Ok(FSharp)
    "G" => Ok(G)
    "G#" | "Ab" => Ok(GSharp)
    "A" => Ok(A)
    "A#" | "Bb" => Ok(ASharp)
    "B" => Ok(B)
    _ => Err("Invalid chord root: " + s)
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

///|
/// Convert chord root to display string
pub fn ChordRoot::to_string(self : ChordRoot) -> String {
  match self {
    C => "C"
    CSharp => "C#"
    D => "D"
    DSharp => "Eb" // Prefer flats
    E => "E"
    F => "F"
    FSharp => "F#"
    G => "G"
    GSharp => "Ab"
    A => "A"
    ASharp => "Bb"
    B => "B"
  }
}
