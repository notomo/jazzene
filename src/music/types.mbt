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
/// Musical event - either a note or a rest
pub enum NoteValue {
  Note(midi~ : MidiNumber, duration~ : NoteDuration)
  Rest(duration~ : NoteDuration)
} derive(Eq, Show)

///|
/// Get note duration from either Note or Rest
pub fn NoteValue::note_duration(self : NoteValue) -> NoteDuration {
  match self {
    Note(duration=d, ..) => d
    Rest(duration=d) => d
  }
}

///|
/// Get duration from either Note or Rest with BPM conversion
pub fn NoteValue::duration(self : NoteValue, bpm : Int) -> Duration {
  let ms_per_beat = 60000.0 / bpm.to_double()
  (self.note_duration().to_beats() * ms_per_beat) |> Duration::from_milliseconds
}

///|
/// Get MIDI value if this is a Note
pub fn NoteValue::midi(self : NoteValue) -> MidiNumber? {
  match self {
    Note(midi=m, ..) => Some(m)
    Rest(..) => None
  }
}

///|
/// NoteValue with pre-calculated duration based on BPM
pub struct NoteValueSound {
  note_value : NoteValue
  duration : Duration
} derive(Eq, Show)

///|
/// Create NoteValueSound from NoteValue with BPM
pub fn NoteValueSound::from_note_value(
  note_value : NoteValue,
  bpm : Int,
) -> NoteValueSound {
  NoteValueSound::{ note_value, duration: note_value.duration(bpm) }
}

///|
/// Get MIDI value if this is a Note sound
pub fn NoteValueSound::midi(self : NoteValueSound) -> MidiNumber? {
  self.note_value.midi()
}

///|
/// Calculate total duration of a note sequence
pub fn calculate_total_duration(sounds : Array[NoteValueSound]) -> Duration {
  let total = @list.from_array(sounds).fold(init=0.0, (acc, sound) => acc +
    sound.duration.to_milliseconds())
  Duration::from_milliseconds(total)
}
