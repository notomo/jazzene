///|
/// Scheduled sound with timing information for playback
pub struct ScheduledSound {
  midi : Int
  start_time : Duration // Audio context time
  duration : Duration // Duration
} derive(Eq, Show)

///|
/// Extract sounds from note values within a time window
/// Returns only Note events (not Rests) that fall within the lookahead window
pub fn extract_sounds_in_window(
  note_values : Array[NoteValue],
  bpm : Int,
  current_pos : Duration,
  lookahead : Duration,
  current_time : Double,
) -> Array[ScheduledSound] {
  let window_end = current_pos + lookahead
  let sounds = []
  let mut position = Duration::from_milliseconds(0)
  for note_value in note_values {
    let duration = note_value.duration(bpm)
    let end_pos = position + duration

    // Extract only actual notes (skip rests) within the window
    match note_value {
      Note(midi=midi_val, ..) =>
        if position.compare(current_pos) >= 0 &&
          position.compare(window_end) < 0 {
          // Convert to audio context time
          let offset = Duration::from_seconds(
            position.to_seconds() - current_pos.to_seconds(),
          )
          let audio_start_time = Duration::from_seconds(
            current_time + offset.to_seconds(),
          )
          sounds.push(ScheduledSound::{
            midi: midi_val.value,
            start_time: audio_start_time,
            duration,
          })
        }
      Rest(..) => () // Rests advance time but produce no sound
    }
    position = end_pos

    // Stop if we've passed the window
    if position.compare(window_end) >= 0 {
      break
    }
  }
  sounds
}
