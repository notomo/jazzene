///|
/// Calculate which MIDI notes are currently active at a given playback position
pub fn calculate_active_midi_notes(
  sounds : Array[NoteValueSound],
  playback_position_ms : Double,
) -> Array[Int] {
  let mut current_pos = 0.0
  let active_midi_notes : Array[Int] = []
  for sound in sounds {
    let duration_ms = sound.duration.to_milliseconds()
    let start_ms = current_pos
    let end_ms = current_pos + duration_ms
    match sound.note_value {
      Note(midi=midi_val, ..) =>
        if playback_position_ms >= start_ms && playback_position_ms < end_ms {
          active_midi_notes.push(midi_val.value)
        }
      Rest(..) => ()
    }
    current_pos = current_pos + duration_ms
  }
  active_midi_notes
}
