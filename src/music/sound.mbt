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
  @list.from_array(sounds)
  .take_while(fn(sound) { sound.start_time < window_end })
  .filter(fn(sound) { sound.start_time >= current_pos })
  .filter_map(fn(sound) {
    match sound.note_value {
      Note(midi=midi_val, ..) => {
        let offset = Duration::from_seconds(
          sound.start_time.to_seconds() - current_pos.to_seconds(),
        )
        let audio_start_time = Duration::from_seconds(
          current_time + offset.to_seconds(),
        )
        Some(ScheduledSound::{
          midi: midi_val.value,
          start_time: audio_start_time,
          duration: sound.duration,
        })
      }
      Rest(..) => None // Rests advance time but produce no sound
    }
  })
  .to_array()
}
