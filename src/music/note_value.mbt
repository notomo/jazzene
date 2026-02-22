///|
/// Musical event - either a note or a rest
pub(all) enum SoundEvent {
  Note(midi~ : MidiNumber, duration~ : NoteDuration)
  Rest(duration~ : NoteDuration)
} derive(Eq, Show)

///|
/// Get note duration from either Note or Rest
pub fn SoundEvent::note_duration(self : SoundEvent) -> NoteDuration {
  match self {
    Note(duration~, ..) => duration
    Rest(duration~) => duration
  }
}

///|
/// Get duration from either Note or Rest with BPM conversion
pub fn SoundEvent::duration(self : SoundEvent, bpm : Int) -> Duration {
  (self.note_duration().to_beats() * ms_per_beat(bpm))
  |> Duration::from_milliseconds
}

///|
/// Get MIDI value if this is a Note
pub fn SoundEvent::midi(self : SoundEvent) -> MidiNumber? {
  match self {
    Note(midi~, ..) => Some(midi)
    Rest(..) => None
  }
}

///|
/// Create a new SoundEvent with a different duration
pub fn SoundEvent::with_duration(
  self : SoundEvent,
  duration : NoteDuration,
) -> SoundEvent {
  match self {
    Note(midi~, ..) => Note(midi~, duration~)
    Rest(..) => Rest(duration~)
  }
}
