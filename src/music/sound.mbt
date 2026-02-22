///|
/// NoteValue with pre-calculated duration and start time based on BPM
pub struct NoteValueSound {
  note_value : NoteValue
  duration : Duration
  start_time : Duration
} derive(Eq, Show)

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

///|
/// Convert measures array to sounds array
/// Combines tied notes into single NoteValueSound entries
/// Applies swing timing to off-beat eighth notes
pub fn convert_measures_to_sounds(
  measures : Array[Measure],
  bpm : Int,
  swing? : SwingConfig = SwingConfig::straight(),
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)

  // Flatten all notes with their absolute start times
  let flat_notes : Array[(Double, MeasureNote)] = measures
    .iter()
    .flat_map(fn(measure) {
      let measure_start_ms = measure.start_time.to_milliseconds()
      measure
      .positioned_notes()
      .iter()
      .map(fn(pair) {
        let (start_beat, note) = pair
        let swing_delay = swing_offset(start_beat, beat_duration_ms, swing)
        let note_start_ms = measure_start_ms +
          start_beat * beat_duration_ms +
          swing_delay
        (note_start_ms, note)
      })
    })
    .collect()

  // Convert to sounds, combining tied notes

  let sounds : Array[NoteValueSound] = []
  for i = 0; i < flat_notes.length(); i = i + 1 {
    let (start_ms, note) = flat_notes[i]

    // Skip TieEnd and TieBoth - they were already counted by TieStart
    match note.tie {
      Some(TieEnd | TieBoth) => continue
      _ => ()
    }

    // Calculate total duration (including any tied continuations)

    let base_beats = note.duration.to_beats()
    let total_beats = match note.tie {
      Some(TieStart) => accumulate_tied_beats(flat_notes, i + 1, base_beats)
      _ => base_beats
    }
    let duration_ms = total_beats * beat_duration_ms

    let note_value : NoteValue = match note.midi {
      Some(midi) =>
        match MidiNumber::new(midi) {
          Some(m) =>
            Note(midi=m, duration=NoteDuration::from_beats(total_beats))
          None => Rest(duration=NoteDuration::from_beats(total_beats))
        }
      None => Rest(duration=NoteDuration::from_beats(total_beats))
    }

    sounds.push(NoteValueSound::{
      note_value,
      duration: Duration::from_milliseconds(duration_ms),
      start_time: Duration::from_milliseconds(start_ms),
    })
  }
  sounds
}

///|
/// Accumulate beats from tied notes (TieEnd/TieBoth) following a TieStart
fn accumulate_tied_beats(
  flat_notes : Array[(Double, MeasureNote)],
  start_index : Int,
  initial_beats : Double,
) -> Double {
  let mut total = initial_beats

  for j = start_index; j < flat_notes.length(); j = j + 1 {
    let (_, next_note) = flat_notes[j]
    match next_note.tie {
      Some(TieBoth) => total = total + next_note.duration.to_beats()
      Some(TieEnd) => {
        total = total + next_note.duration.to_beats()
        break
      }
      _ => break
    }
  }
  total
}
