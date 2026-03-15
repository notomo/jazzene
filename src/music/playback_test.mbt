///|
// At 120 BPM, 4/4: ms_per_measure = 60000/120 * 4 = 2000ms

///|
test "measure_to_duration - measure 1 is at 0ms" {
  let d = measure_to_duration(1, 120, 4.0)
  assert_eq(d.to_milliseconds(), 0.0)
}

///|
test "measure_to_duration - measure 2 is at one measure" {
  let d = measure_to_duration(2, 120, 4.0)
  assert_eq(d.to_milliseconds(), 2000.0)
}

///|
test "measure_to_duration - measure 3 is at two measures" {
  let d = measure_to_duration(3, 120, 4.0)
  assert_eq(d.to_milliseconds(), 4000.0)
}

///|
test "measure_to_duration - 3/4 time signature" {
  // 60 BPM, 3/4: ms_per_measure = 60000/60 * 3 = 3000ms
  let d = measure_to_duration(2, 60, 3.0)
  assert_eq(d.to_milliseconds(), 3000.0)
}

///|
test "advance_playback_position - normal advance within loop" {
  // loop: A=1, B=2 → [0ms, 4000ms), total=4000ms
  let current = Duration::from_milliseconds(500.0)
  let result = advance_playback_position(
    current,
    200.0,
    Duration::from_milliseconds(4000.0),
    120,
    4.0,
    1,
    2,
  )
  assert_eq(result.to_milliseconds(), 700.0)
}

///|
test "advance_playback_position - snaps back to A when reaching B" {
  // loop: A=1, B=2 → [0ms, 4000ms), total=8000ms
  // current=3900ms + 200ms = 4100ms >= 4000ms → snap to 0ms
  let current = Duration::from_milliseconds(3900.0)
  let result = advance_playback_position(
    current,
    200.0,
    Duration::from_milliseconds(8000.0),
    120,
    4.0,
    1,
    2,
  )
  assert_eq(result.to_milliseconds(), 0.0)
}

///|
test "advance_playback_position - snaps to A when position before A" {
  // loop: A=2, B=3 → [2000ms, 4000ms), total=8000ms
  // current=0ms → before a_time=2000ms → snap to 2000ms
  let current = Duration::from_milliseconds(0.0)
  let result = advance_playback_position(
    current,
    100.0,
    Duration::from_milliseconds(8000.0),
    120,
    4.0,
    2,
    3,
  )
  assert_eq(result.to_milliseconds(), 2000.0)
}

///|
test "advance_playback_position - clamps to total within loop" {
  // loop: A=1, B=4 → [0ms, 6000ms), total=4000ms
  // current=3900ms + 200ms → clamp to 4000ms, within [0, 6000) → stays 4000ms
  let current = Duration::from_milliseconds(3900.0)
  let result = advance_playback_position(
    current,
    200.0,
    Duration::from_milliseconds(4000.0),
    120,
    4.0,
    1,
    4,
  )
  assert_eq(result.to_milliseconds(), 4000.0)
}

///|
test "advance_playback_position - reversed B<A always snaps to A" {
  // loop: A=2, B=1 → a_time=2000ms, b_time=measure_to_duration(2)=2000ms
  // a_time == b_time, so any new_position >= b_time → snap to a_time
  let current = Duration::from_milliseconds(2000.0)
  let result = advance_playback_position(
    current,
    100.0,
    Duration::from_milliseconds(8000.0),
    120,
    4.0,
    2,
    1,
  )
  assert_eq(result.to_milliseconds(), 2000.0)
}
