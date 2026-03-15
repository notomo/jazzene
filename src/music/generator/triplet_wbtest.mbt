///|
test "should_generate_triplet returns false when probability is 0" {
  let result = should_generate_triplet(0.0, 5, 2.0, 0, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_triplet returns false when not on beat" {
  let result = should_generate_triplet(0.5, 5, 2.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_triplet returns false when notes_left < 3" {
  let result = should_generate_triplet(0.0, 2, 2.0, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_triplet returns false when remaining < 1 beat" {
  let result = should_generate_triplet(0.0, 5, 0.5, 100, fn(_) { 0 })
  assert_false(result)
}

///|
test "should_generate_triplet returns true when all conditions met" {
  let result = should_generate_triplet(0.0, 5, 2.0, 100, fn(_) { 0 })
  assert_true(result)
}

///|
test "should_generate_triplet returns false when probability check fails" {
  // random_int returns 99, probability is 50 → 99 >= 50 → false
  let result = should_generate_triplet(0.0, 5, 2.0, 50, fn(_) { 99 })
  assert_false(result)
}

///|
test "should_generate_triplet works on non-zero integer beats" {
  let result = should_generate_triplet(3.0, 5, 1.0, 100, fn(_) { 0 })
  assert_true(result)
}
