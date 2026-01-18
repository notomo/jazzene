///|
test "Duration::from_seconds" {
  let duration = Duration::from_seconds(1.5)
  assert_eq(duration.seconds, 1.5)
}

///|
test "Duration::from_milliseconds" {
  let duration = Duration::from_milliseconds(1500.0)
  assert_eq(duration.seconds, 1.5)
}

///|
test "Duration::to_seconds" {
  let duration = Duration::from_seconds(2.5)
  assert_eq(duration.to_seconds(), 2.5)
}

///|
test "Duration::to_milliseconds" {
  let duration = Duration::from_seconds(2.5)
  assert_eq(duration.to_milliseconds(), 2500.0)
}

///|
test "Duration comparison - less than" {
  let d1 = Duration::from_seconds(1.0)
  let d2 = Duration::from_seconds(2.0)
  assert_true(d1 < d2)
}

///|
test "Duration comparison - greater than" {
  let d1 = Duration::from_seconds(2.0)
  let d2 = Duration::from_seconds(1.0)
  assert_true(d1 > d2)
}

///|
test "Duration comparison - equal" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(1.5)
  assert_eq(d1.compare(d2), 0)
}

///|
test "Duration addition" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(2.5)
  let result = d1 + d2
  assert_eq(result.seconds, 4.0)
}

///|
test "Duration conversion round-trip" {
  let original_ms = 1234.5
  let duration = Duration::from_milliseconds(original_ms)
  assert_eq(duration.to_milliseconds(), 1234.5)
}

///|
test "Duration equality" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(1.5)
  let d3 = Duration::from_seconds(2.0)
  assert_eq(d1, d2)
  assert_true(d1 != d3)
}
