///|
test "Duration::from_seconds" {
  let duration = @music.Duration::from_seconds(1.5)
  assert_eq(duration.seconds, 1.5)
}

///|
test "Duration::from_milliseconds" {
  let duration = @music.Duration::from_milliseconds(1500.0)
  assert_eq(duration.seconds, 1.5)
}

///|
test "Duration::to_seconds" {
  let duration = @music.Duration::from_seconds(2.5)
  assert_eq(duration.to_seconds(), 2.5)
}

///|
test "Duration::to_milliseconds" {
  let duration = @music.Duration::from_seconds(2.5)
  assert_eq(duration.to_milliseconds(), 2500.0)
}

///|
test "Duration comparison - less than" {
  let d1 = @music.Duration::from_seconds(1.0)
  let d2 = @music.Duration::from_seconds(2.0)
  assert_true(d1 < d2)
}

///|
test "Duration comparison - greater than" {
  let d1 = @music.Duration::from_seconds(2.0)
  let d2 = @music.Duration::from_seconds(1.0)
  assert_true(d1 > d2)
}

///|
test "Duration comparison - equal" {
  let d1 = @music.Duration::from_seconds(1.5)
  let d2 = @music.Duration::from_seconds(1.5)
  assert_eq(d1.compare(d2), 0)
}

///|
test "Duration addition" {
  let d1 = @music.Duration::from_seconds(1.5)
  let d2 = @music.Duration::from_seconds(2.5)
  let result = d1 + d2
  assert_eq(result.seconds, 4.0)
}

///|
test "Duration conversion round-trip" {
  let original_ms = 1234.5
  let duration = @music.Duration::from_milliseconds(original_ms)
  assert_eq(duration.to_milliseconds(), 1234.5)
}

///|
test "Duration equality" {
  let d1 = @music.Duration::from_seconds(1.5)
  let d2 = @music.Duration::from_seconds(1.5)
  let d3 = @music.Duration::from_seconds(2.0)
  assert_eq(d1, d2)
  assert_true(d1 != d3)
}

///|
test "Duration::format - zero" {
  let d = @music.Duration::from_milliseconds(0.0)
  assert_eq(d.format(), "0:00")
}

///|
test "Duration::format - seconds with leading zero" {
  let d = @music.Duration::from_seconds(5.0)
  assert_eq(d.format(), "0:05")
}

///|
test "Duration::format - minutes and seconds" {
  let d = @music.Duration::from_seconds(65.0)
  assert_eq(d.format(), "1:05")
}

///|
test "Duration::format - exact minute" {
  let d = @music.Duration::from_seconds(120.0)
  assert_eq(d.format(), "2:00")
}

///|
test "Duration::format - large value" {
  let d = @music.Duration::from_seconds(3661.0)
  assert_eq(d.format(), "61:01")
}

///|
test "Duration::parse - valid 0:00" {
  assert_eq(
    @music.Duration::parse("0:00"),
    Some(@music.Duration::from_seconds(0.0)),
  )
}

///|
test "Duration::parse - valid 1:30" {
  assert_eq(
    @music.Duration::parse("1:30"),
    Some(@music.Duration::from_seconds(90.0)),
  )
}

///|
test "Duration::parse - valid 10:05" {
  assert_eq(
    @music.Duration::parse("10:05"),
    Some(@music.Duration::from_seconds(605.0)),
  )
}

///|
test "Duration::parse - invalid no colon" {
  assert_eq(@music.Duration::parse("100"), None)
}

///|
test "Duration::parse - invalid seconds >= 60" {
  assert_eq(@music.Duration::parse("1:60"), None)
}

///|
test "Duration::parse - invalid non-numeric" {
  assert_eq(@music.Duration::parse("a:bc"), None)
}

///|
test "Duration::parse - invalid empty" {
  assert_eq(@music.Duration::parse(""), None)
}

///|
test "Duration::parse - invalid multiple colons" {
  assert_eq(@music.Duration::parse("1:2:3"), None)
}

///|
test "Duration format-parse round trip" {
  let d = @music.Duration::from_seconds(95.0)
  assert_eq(
    @music.Duration::parse(d.format()),
    Some(@music.Duration::from_seconds(95.0)),
  )
}
