///|
test "NoteDuration to_beats" {
  assert_eq(Eighth.to_beats(), 0.5)
  assert_eq(Quarter.to_beats(), 1.0)
  assert_eq(Half.to_beats(), 2.0)
}

///|
test "NoteDuration to_beats for dotted notes" {
  assert_eq(DottedEighth.to_beats(), 0.75)
  assert_eq(DottedQuarter.to_beats(), 1.5)
  assert_eq(DottedHalf.to_beats(), 3.0)
}
