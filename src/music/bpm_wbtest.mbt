///|
test "calculate_total_duration" {
  // 1 measure at 120 bpm = 1 * 240 / 120 * 1000 = 2000 ms
  assert_eq(
    calculate_total_duration(bpm=120, measure_count=1, beats_per_measure=4.0).to_milliseconds(),
    2000.0,
  )
  // 2 measures at 120 bpm = 2 * 240 / 120 * 1000 = 4000 ms
  assert_eq(
    calculate_total_duration(bpm=120, measure_count=2, beats_per_measure=4.0).to_milliseconds(),
    4000.0,
  )
  // 1 measure at 60 bpm = 1 * 240 / 60 * 1000 = 4000 ms
  assert_eq(
    calculate_total_duration(bpm=60, measure_count=1, beats_per_measure=4.0).to_milliseconds(),
    4000.0,
  )
}
