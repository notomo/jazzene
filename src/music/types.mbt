///|
/// Note duration types for rhythm variation
pub enum NoteDuration {
  Eighth // 0.5 beats
  Quarter // 1 beat
  Half // 2 beats
} derive(Eq, Show)

///|
/// Convert note duration to beats
pub fn NoteDuration::to_beats(self : NoteDuration) -> Double {
  match self {
    Eighth => 0.5
    Quarter => 1.0
    Half => 2.0
  }
}

///|
/// Convert note duration to milliseconds based on tempo
pub fn NoteDuration::to_ms(self : NoteDuration, tempo_bpm : Int) -> Int {
  let ms_per_beat = 60000 / tempo_bpm
  (self.to_beats() * ms_per_beat.to_double()).to_int()
}

///|
/// MIDI number newtype with validation (0-127)
pub struct MidiNumber {
  value : Int
} derive(Eq, Show)

///|
/// Create MidiNumber with validation
pub fn MidiNumber::new(value : Int) -> MidiNumber? {
  if value >= 0 && value <= 127 {
    Some(MidiNumber::{ value, })
  } else {
    None
  }
}

///|
/// Create MidiNumber without validation (for internal use)
pub fn MidiNumber::unsafe_new(value : Int) -> MidiNumber {
  MidiNumber::{ value, }
}

///|
/// Note name enum for type-safe chord roots
pub enum NoteName {
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
/// Convert note name to string
pub fn NoteName::to_string(self : NoteName) -> String {
  match self {
    C => "C"
    CSharp => "C#"
    D => "D"
    DSharp => "D#"
    E => "E"
    F => "F"
    FSharp => "F#"
    G => "G"
    GSharp => "G#"
    A => "A"
    ASharp => "A#"
    B => "B"
  }
}

///|
/// Parse string to note name
pub fn NoteName::from_string(s : String) -> NoteName? {
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
pub fn NoteName::to_midi(self : NoteName) -> Int {
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
/// Convert chord quality to string
pub fn ChordQuality::to_string(self : ChordQuality) -> String {
  match self {
    Major7 => "maj7"
    Minor7 => "m7"
    Dominant7 => "7"
    HalfDiminished => "m7b5"
    Diminished7 => "dim7"
    Augmented => "aug"
    Sus4 => "sus4"
    Major => ""
    Minor => "m"
  }
}

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
/// Chord with type-safe root and quality
pub struct Chord {
  root : NoteName
  quality : ChordQuality
} derive(Eq, Show)

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[Int] {
  let root_midi = self.root.to_midi()
  let intervals = self.quality.intervals()
  intervals.map(fn(interval) { root_midi + interval })
}

///|
/// Musical note with MIDI number and duration
pub struct Note {
  midi : MidiNumber
  duration : NoteDuration
} derive(Eq, Show)

///|
/// Create note from MIDI number and duration
pub fn Note::new(midi_value : Int, duration : NoteDuration) -> Note? {
  match MidiNumber::new(midi_value) {
    Some(midi) => Some(Note::{ midi, duration })
    None => None
  }
}

///|
/// Convert MIDI number to note name with octave
pub fn Note::name(self : Note) -> String {
  let note_names = [
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
  ]
  let octave = self.midi.value / 12 - 1
  let note_index = self.midi.value % 12
  note_names[note_index] + octave.to_string()
}

///|
/// Tempo newtype with validation (30-300 BPM)
pub struct Tempo {
  bpm : Int
} derive(Eq, Show)

///|
/// Create Tempo with validation
pub fn Tempo::new(bpm : Int) -> Tempo? {
  if bpm >= 30 && bpm <= 300 {
    Some(Tempo::{ bpm, })
  } else {
    None
  }
}

///|
/// Position in milliseconds
pub struct Position {
  ms : Int
} derive(Eq, Show)

///|
/// Create Position with validation (>= 0)
pub fn Position::new(ms : Int) -> Position? {
  if ms >= 0 {
    Some(Position::{ ms, })
  } else {
    None
  }
}
