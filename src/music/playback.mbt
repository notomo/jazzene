///|
/// Calculate which MIDI notes are currently active at a given playback position
pub fn calculate_active_midi_notes(
  note_values : Array[NoteValue],
  playback_position_ms : Int,
  bpm : Int,
) -> Array[Int] {
  let mut current_pos = 0
  let active_midi_notes : Array[Int] = []
  for note_value in note_values {
    let duration_ms = note_value.duration().to_ms(bpm)
    let start_ms = current_pos
    let end_ms = current_pos + duration_ms
    match note_value {
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
