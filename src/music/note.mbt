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
  note_values.map(fn(nv) {
    let dur = nv.duration(bpm)
    let sound = NoteValueSound::{
      note_value: nv,
      duration: dur,
      start_time: Duration::from_milliseconds(current_time),
    }
    current_time = current_time + dur.to_milliseconds()
    sound
  })
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
