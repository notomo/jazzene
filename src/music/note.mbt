///|
/// Note duration types for rhythm variation
pub enum NoteDuration {
  Eighth // 0.5 beats
  Quarter // 1 beat
  Half // 2 beats
  DottedEighth // 0.75 beats
  DottedQuarter // 1.5 beats
  DottedHalf // 3.0 beats
} derive(Eq, Show)

///|
/// Convert note duration to beats
pub fn NoteDuration::to_beats(self : NoteDuration) -> Double {
  match self {
    Eighth => 0.5
    Quarter => 1.0
    Half => 2.0
    DottedEighth => 0.75
    DottedQuarter => 1.5
    DottedHalf => 3.0
  }
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
  let total = @list.from_array(sounds).fold(init=0.0, (acc, sound) => acc +
    sound.duration.to_milliseconds())
  Duration::from_milliseconds(total)
}

///|
/// Calculate which notes are currently playing at a given playback position
pub fn calculate_playing_notes(
  sounds : Array[NoteValueSound],
  position : Duration,
) -> Array[NoteValueSound] {
  @list.from_array(sounds)
  .take_while(fn(sound) { sound.start_time <= position })
  .filter(fn(sound) { sound.in_range(position) })
  .to_array()
}

///|
/// Slice notes within a time window for lookahead scheduling
/// Returns all sounds (both Note and Rest) within [position, position + lookahead)
pub fn slice_notes(
  sounds : Array[NoteValueSound],
  position : Duration,
  lookahead : Duration,
) -> Array[NoteValueSound] {
  let window_end = position + lookahead
  @list.from_array(sounds)
  .take_while(fn(sound) { sound.start_time < window_end })
  .filter(fn(sound) { sound.start_time >= position })
  .to_array()
}
