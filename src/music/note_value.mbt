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
    Note(duration~, ..) => duration
    Rest(duration~) => duration
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
    Note(midi~, ..) => Some(midi)
    Rest(..) => None
  }
}
