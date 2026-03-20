///|
/// Grouped audio sounds for scheduling across all instrument channels
pub struct ScheduledSounds {
  piano : Array[AudioSound]
  comping : Array[AudioSound]
  bass : Array[AudioSound]
  drum : Array[AudioSound]
  recorded : Array[AudioSound]
}

///|
/// Abstraction over audio output; implemented by the synthesizer in the audio layer
pub(open) trait AudioOutput {
  schedule_sounds(Self, ScheduledSounds) -> Unit
}

///|
/// Build a tick function that advances playback and schedules audio each frame.
/// All inputs are thunks so this function has no dependency on ui or audio packages.
pub fn[T : AudioOutput] make_tick(
  audio_output~ : T,
  total_duration~ : () -> Duration,
  bpm~ : () -> Int,
  beats_per_measure~ : () -> Double,
  time_signature~ : () -> TimeSignature,
  playback_position~ : () -> Duration,
  set_playback_position~ : (Duration) -> Unit,
  loop_a_measure~ : () -> Int,
  loop_b_measure~ : () -> Int,
  jazz_style~ : () -> JazzStyle,
  sounds~ : () -> Array[ScheduledSound],
  comping_sounds~ : () -> Array[ScheduledSound],
  bass_sounds~ : () -> Array[ScheduledSound],
  drum_sounds~ : () -> Array[ScheduledSound],
  recorded_sounds~ : () -> Array[ScheduledSound],
) -> (Double) -> Bool {
  let lookahead = Duration::from_milliseconds(100)
  fn(elapsed_ms : Double) -> Bool {
    let final_position = advance_playback_position(
      playback_position(),
      elapsed_ms,
      total_duration(),
      bpm(),
      beats_per_measure(),
      loop_a_measure(),
      loop_b_measure(),
    )
    let style = jazz_style()
    let ts = time_signature()
    let piano = match style.melody_mode {
      On =>
        AudioSound::from(sounds(), final_position, lookahead, time_signature=ts)
      Silent | Off => []
    }
    let comping = match style.comping_mode {
      Silent => []
      _ =>
        AudioSound::from(
          comping_sounds(),
          final_position,
          lookahead,
          time_signature=ts,
        )
    }
    let bass = AudioSound::from(bass_sounds(), final_position, lookahead)
    let drum = AudioSound::from(drum_sounds(), final_position, lookahead)
    let recorded = AudioSound::from(
      recorded_sounds(),
      final_position,
      lookahead,
    )
    audio_output.schedule_sounds(ScheduledSounds::{
      piano,
      comping,
      bass,
      drum,
      recorded,
    })
    set_playback_position(final_position)
    false
  }
}

///|
/// Convert a 1-based measure number to its start Duration at the given BPM
pub fn measure_to_duration(
  measure_number : Int,
  bpm : Int,
  beats_per_measure : Double,
) -> Duration {
  let ms = (measure_number - 1).to_double() *
    ms_per_measure(bpm, beats_per_measure~)
  Duration::from_milliseconds(ms)
}

///|
/// Advance playback position by elapsed_ms, clamped to total and respecting
/// the A-B loop range [loop_a_measure, loop_b_measure].
/// If the new position falls outside [a_time, b_time), it snaps back to a_time.
pub fn advance_playback_position(
  current : Duration,
  elapsed_ms : Double,
  total : Duration,
  bpm : Int,
  beats_per_measure : Double,
  loop_a_measure : Int,
  loop_b_measure : Int,
) -> Duration {
  let new_position = @cmp.minimum(
    current + Duration::from_milliseconds(elapsed_ms),
    total,
  )
  let b_time = measure_to_duration(loop_b_measure + 1, bpm, beats_per_measure)
  let a_time = measure_to_duration(loop_a_measure, bpm, beats_per_measure)
  if new_position < a_time || new_position >= b_time {
    a_time
  } else {
    new_position
  }
}
