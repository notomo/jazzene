///|
/// Audio sound with offset from current position for Web Audio scheduling
pub(all) struct AudioSound {
  offset : Duration
  duration : Duration
  midi : MidiNumber
  volume : Double
} derive(Eq, Debug)

///|
pub impl Show for AudioSound with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Create AudioSound array from ScheduledSound array within lookahead window
/// Only includes sounds where start_time is in [current_pos, current_pos + lookahead)
/// offset = sound.start_time - current_pos
/// Filters out Rest notes (only includes actual notes with MIDI values)
pub fn AudioSound::from(
  sounds : Array[ScheduledSound],
  current_pos : Duration,
  lookahead : Duration,
  time_signature? : TimeSignature = TimeSignature::default(),
) -> Array[AudioSound] {
  let window_end = current_pos + lookahead
  sounds
  .iter()
  .take_while(fn(sound) { sound.start_time < window_end })
  .filter(fn(sound) { sound.start_time >= current_pos })
  .filter_map(fn(sound) {
    sound
    .midi()
    .map(fn(midi) {
      let intensity = match sound.tone_origin {
        Some(origin) => origin.intensity()
        None => 0.85
      }
      let volume = intensity * time_signature.beat_accent(sound.beat_position)
      AudioSound::{
        offset: sound.start_time - current_pos,
        duration: sound.duration,
        midi,
        volume,
      }
    })
  })
  .collect()
}

///|
/// Calculate the actual start time for Web Audio scheduling
/// Returns audio_current_time + offset
pub fn AudioSound::start_time(
  self : AudioSound,
  audio_current_time : Duration,
) -> Duration {
  audio_current_time + self.offset
}
