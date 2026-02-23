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
