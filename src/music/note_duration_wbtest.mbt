///|
test "NoteDuration to_beats" {
  assert_eq(Eighth.to_beats(), 0.5)
  assert_eq(Quarter.to_beats(), 1.0)
  assert_eq(Half.to_beats(), 2.0)
}

///|
test "NoteDuration fit" {
  assert_eq(NoteDuration::fit(4.0), Some(Whole))
  assert_eq(NoteDuration::fit(1.0), Some(Quarter))
  assert_eq(NoteDuration::fit(0.5), Some(Eighth))
  assert_eq(NoteDuration::fit(0.1), None)
}
