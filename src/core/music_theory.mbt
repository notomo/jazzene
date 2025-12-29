///| Note represents a musical note with MIDI number (0-127)

///|
/// Middle C (C4) = 60
pub struct Note {
  midi_number : Int
} derive(Eq, Show)

///|
/// Convert MIDI number to note name
pub fn Note::name(self : Note) -> String {
  let note_names = [
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
  ]
  let octave = self.midi_number / 12 - 1
  let note_index = self.midi_number % 12
  note_names[note_index] + octave.to_string()
}

///|
/// Create a Note from MIDI number
pub fn Note::from_midi(midi_number : Int) -> Note {
  Note::{ midi_number, }
}

///|
/// Chord represents a jazz chord with root and quality
pub struct Chord {
  root : String // "C", "Db", "F#"
  quality : String // "maj7", "m7", "7", etc.
} derive(Eq, Show)

///|
/// Get the MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[Int] {
  let root_midi = note_name_to_midi(self.root)
  match self.quality {
    "maj7" => [root_midi, root_midi + 4, root_midi + 7, root_midi + 11]
    "m7" => [root_midi, root_midi + 3, root_midi + 7, root_midi + 10]
    "7" => [root_midi, root_midi + 4, root_midi + 7, root_midi + 10]
    "dim7" => [root_midi, root_midi + 3, root_midi + 6, root_midi + 9]
    "m7b5" | "half-dim" =>
      [root_midi, root_midi + 3, root_midi + 6, root_midi + 10]
    "aug" => [root_midi, root_midi + 4, root_midi + 8]
    "sus4" => [root_midi, root_midi + 5, root_midi + 7]
    _ => [root_midi, root_midi + 4, root_midi + 7] // default to major triad
  }
}

///|
/// Convert note name to MIDI number (octave 4)
fn note_name_to_midi(note_name : String) -> Int {
  let base_octave = 60 // C4
  match note_name {
    "C" => base_octave
    "C#" | "Db" => base_octave + 1
    "D" => base_octave + 2
    "D#" | "Eb" => base_octave + 3
    "E" => base_octave + 4
    "F" => base_octave + 5
    "F#" | "Gb" => base_octave + 6
    "G" => base_octave + 7
    "G#" | "Ab" => base_octave + 8
    "A" => base_octave + 9
    "A#" | "Bb" => base_octave + 10
    "B" => base_octave + 11
    _ => base_octave // default to C
  }
}

///| Duration represents note duration (reserved for future use)
// pub enum Duration {
//   Whole
//   Half
//   Quarter
//   Eighth
//   Sixteenth
// } derive(Eq, Show)
