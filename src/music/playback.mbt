///|
/// Calculate which MIDI notes are currently active at a given playback position
pub fn calculate_active_midi_notes(
  sounds : Array[NoteValueSound],
  playback_position_ms : Double,
) -> Array[Int] {
  let active_midi_notes : Array[Int] = []
  for sound in sounds {
    let start_ms = sound.start_time.to_milliseconds()
    let end_ms = start_ms + sound.duration.to_milliseconds()

    // Early exit optimization (sounds are chronologically ordered)
    if start_ms > playback_position_ms {
      break
    }
    match sound.note_value {
      Note(midi=midi_val, ..) =>
        if playback_position_ms >= start_ms && playback_position_ms < end_ms {
          active_midi_notes.push(midi_val.value)
        }
      Rest(..) => ()
    }
  }
  active_midi_notes
}
