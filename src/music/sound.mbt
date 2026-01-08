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
  sounds : Array[NoteValueSound],
  current_pos : Duration,
  lookahead : Duration,
  current_time : Double,
) -> Array[ScheduledSound] {
  let window_end = current_pos + lookahead
  let scheduled_sounds = []
  for sound in sounds {
    let position = sound.start_time

    // Early exit if past window
    if position.compare(window_end) >= 0 {
      break
    }

    // Extract only actual notes (skip rests) within the window
    match sound.note_value {
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
          scheduled_sounds.push(ScheduledSound::{
            midi: midi_val.value,
            start_time: audio_start_time,
            duration: sound.duration,
          })
        }
      Rest(..) => () // Rests advance time but produce no sound
    }
  }
  scheduled_sounds
}
