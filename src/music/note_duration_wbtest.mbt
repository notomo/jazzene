///|
test "NoteDuration to_beats" {
  assert_eq(Eighth.to_beats(), 0.5)
  assert_eq(Quarter.to_beats(), 1.0)
  assert_eq(Half.to_beats(), 2.0)
}
