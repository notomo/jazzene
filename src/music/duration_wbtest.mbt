///|
test "Duration::from_seconds" {
  let duration = Duration::from_seconds(1.5)
  inspect(duration.seconds, content="1.5")
}

///|
test "Duration::from_milliseconds" {
  let duration = Duration::from_milliseconds(1500.0)
  inspect(duration.seconds, content="1.5")
}

///|
test "Duration::to_seconds" {
  let duration = Duration::from_seconds(2.5)
  inspect(duration.to_seconds(), content="2.5")
}

///|
test "Duration::to_milliseconds" {
  let duration = Duration::from_seconds(2.5)
  inspect(duration.to_milliseconds(), content="2500")
}

///|
test "Duration comparison - less than" {
  let d1 = Duration::from_seconds(1.0)
  let d2 = Duration::from_seconds(2.0)
  inspect(d1.compare(d2), content="-1")
}

///|
test "Duration comparison - greater than" {
  let d1 = Duration::from_seconds(2.0)
  let d2 = Duration::from_seconds(1.0)
  inspect(d1.compare(d2), content="1")
}

///|
test "Duration comparison - equal" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(1.5)
  inspect(d1.compare(d2), content="0")
}

///|
test "Duration addition" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(2.5)
  let result = d1 + d2
  inspect(result.seconds, content="4")
}

///|
test "Duration conversion round-trip" {
  let original_ms = 1234.5
  let duration = Duration::from_milliseconds(original_ms)
  inspect(duration.to_milliseconds(), content="1234.5")
}

///|
test "Duration equality" {
  let d1 = Duration::from_seconds(1.5)
  let d2 = Duration::from_seconds(1.5)
  let d3 = Duration::from_seconds(2.0)
  inspect(d1 == d2, content="true")
  inspect(d1 == d3, content="false")
}
