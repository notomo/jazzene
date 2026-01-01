///|
/// Schedule notes in a lookahead window for smooth playback
/// This avoids setTimeout drift by using WebAudio's precise scheduling
pub fn schedule_notes_in_window(
  ctx : AudioContext,
  notes : Array[@music.Note],
  tempo_bpm : Int,
  current_pos_ms : Int,
  lookahead_ms : Int,
) -> Unit {
  let window_end_ms = current_pos_ms + lookahead_ms

  // Calculate position in the note sequence
  let mut position_ms = 0
  for note in notes {
    let note_duration_ms = note.duration.to_ms(tempo_bpm)
    let note_end_ms = position_ms + note_duration_ms

    // Schedule if note starts within the lookahead window
    if position_ms >= current_pos_ms && position_ms < window_end_ms {
      // Convert to audio context time
      let audio_start_time = ctx.current_time() +
        (position_ms - current_pos_ms).to_double() / 1000.0
      let duration_sec = note_duration_ms.to_double() / 1000.0

      // Schedule the note
      ctx.schedule_note(note.midi.value, audio_start_time, duration_sec, 0.7)
    }
    position_ms = note_end_ms

    // Stop if we've passed the window
    if position_ms >= window_end_ms {
      break
    }
  }
}

///|
/// Calculate total duration of a note sequence in milliseconds
pub fn calculate_total_duration(
  notes : Array[@music.Note],
  tempo_bpm : Int,
) -> Int {
  let mut total_ms = 0
  for note in notes {
    total_ms = total_ms + note.duration.to_ms(tempo_bpm)
  }
  total_ms
}
