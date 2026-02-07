///|
test "TimeSignature beat_group_index 4/4" {
  let ts = TimeSignature::{ numerator: 4, denominator: 4 }
  assert_eq(ts.beat_group_index(0.0), 0)
  assert_eq(ts.beat_group_index(0.5), 0)
  assert_eq(ts.beat_group_index(1.0), 0)
  assert_eq(ts.beat_group_index(1.5), 0)
  assert_eq(ts.beat_group_index(2.0), 1)
  assert_eq(ts.beat_group_index(2.5), 1)
  assert_eq(ts.beat_group_index(3.0), 1)
  assert_eq(ts.beat_group_index(3.5), 1)
}

///|
test "TimeSignature beat_group_index 3/4" {
  let ts = TimeSignature::{ numerator: 3, denominator: 4 }
  assert_eq(ts.beat_group_index(0.0), 0)
  assert_eq(ts.beat_group_index(1.0), 0)
  assert_eq(ts.beat_group_index(1.5), 0)
  assert_eq(ts.beat_group_index(2.0), 1)
  assert_eq(ts.beat_group_index(2.5), 1)
}
