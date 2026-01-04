///|
/// Scheduled sound with timing information for playback
pub struct ScheduledSound {
  midi : Int
  audio_start_time : Double // Audio context time (seconds)
  duration_sec : Double // Duration in seconds
} derive(Eq, Show)

///|
/// Extract sounds from note values within a time window
/// Returns only Note events (not Rests) that fall within the lookahead window
pub fn extract_sounds_in_window(
  note_values : Array[NoteValue],
  bpm : Int,
  current_pos_ms : Int,
  lookahead_ms : Int,
  current_time : Double,
) -> Array[ScheduledSound] {
  let window_end_ms = current_pos_ms + lookahead_ms
  let sounds = []
  let mut position_ms = 0
  for note_value in note_values {
    let duration_ms = note_value.duration().to_ms(bpm)
    let end_ms = position_ms + duration_ms

    // Extract only actual notes (skip rests) within the window
    match note_value {
      Note(midi=midi_val, ..) =>
        if position_ms >= current_pos_ms && position_ms < window_end_ms {
          // Convert to audio context time
          let audio_start_time = current_time +
            (position_ms - current_pos_ms).to_double() / 1000.0
          let duration_sec = duration_ms.to_double() / 1000.0
          sounds.push(ScheduledSound::{
            midi: midi_val.value,
            audio_start_time,
            duration_sec,
          })
        }
      Rest(..) => () // Rests advance time but produce no sound
    }
    position_ms = end_ms

    // Stop if we've passed the window
    if position_ms >= window_end_ms {
      break
    }
  }
  sounds
}
