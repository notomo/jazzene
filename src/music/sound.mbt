///|
/// NoteValue with pre-calculated duration and start time based on BPM
pub struct NoteValueSound {
  note_value : NoteValue
  duration : Duration
  start_time : Duration
} derive(Eq, Show)

///|
/// Create array of NoteValueSound with pre-calculated start times
pub fn NoteValueSound::from_note_values(
  note_values : Array[NoteValue],
  bpm : Int,
) -> Array[NoteValueSound] {
  let mut current_time = 0.0
  note_values.map(fn(note_value) {
    let duration = note_value.duration(bpm)
    let sound = NoteValueSound::{
      note_value,
      duration,
      start_time: Duration::from_milliseconds(current_time),
    }
    current_time = current_time + duration.to_milliseconds()
    sound
  })
}

///|
/// Get MIDI value if this is a Note sound
pub fn NoteValueSound::midi(self : NoteValueSound) -> MidiNumber? {
  self.note_value.midi()
}

///|
/// Check if this note is playing at the given position
pub fn NoteValueSound::in_range(
  self : NoteValueSound,
  position : Duration,
) -> Bool {
  self.start_time <= position && position < self.start_time + self.duration
}

///|
/// Calculate total duration of a note sequence
pub fn calculate_total_duration(sounds : Array[NoteValueSound]) -> Duration {
  sounds
  .iter()
  .fold(init=0.0, (acc, sound) => acc + sound.duration.to_milliseconds())
  |> Duration::from_milliseconds
}

///|
/// Calculate which notes are currently playing at a given playback position
pub fn calculate_playing_notes(
  sounds : Array[NoteValueSound],
  position : Duration,
) -> Array[NoteValueSound] {
  sounds
  .iter()
  .take_while(fn(sound) { sound.start_time <= position })
  .filter(fn(sound) { sound.in_range(position) })
  .collect()
}
