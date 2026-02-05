///|
fn assert_float_near(actual : Double, expected : Double) -> Unit raise Failure {
  let epsilon = 0.0001
  if (actual - expected).abs() > epsilon {
    fail("expected \{expected}, got \{actual}")
  }
}

///|
test "swing_offset returns 0 for on-beat positions" {
  let swing = SwingConfig::triplet()
  let beat_duration_ms = 500.0 // 120 BPM

  // On-beat positions should have no swing delay
  assert_float_near(swing_offset(0.0, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(1.0, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(2.0, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(3.0, beat_duration_ms, swing), 0.0)
}

///|
test "swing_offset applies delay to off-beat positions" {
  let swing = SwingConfig::triplet()
  let beat_duration_ms = 500.0 // 120 BPM

  // Off-beat eighth notes should be delayed
  // Expected delay: (2/3 - 0.5) * 500 = 0.1667 * 500 ≈ 83.33ms
  let expected_delay = (2.0 / 3.0 - 0.5) * beat_duration_ms
  assert_float_near(swing_offset(0.5, beat_duration_ms, swing), expected_delay)
  assert_float_near(swing_offset(1.5, beat_duration_ms, swing), expected_delay)
  assert_float_near(swing_offset(2.5, beat_duration_ms, swing), expected_delay)
}

///|
test "straight swing has no delay" {
  let swing = SwingConfig::straight()
  let beat_duration_ms = 500.0

  // Straight feel should have no delay anywhere
  assert_float_near(swing_offset(0.0, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(0.5, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(1.0, beat_duration_ms, swing), 0.0)
  assert_float_near(swing_offset(1.5, beat_duration_ms, swing), 0.0)
}

///|
test "SwingConfig::straight creates ratio 0.5" {
  inspect(SwingConfig::straight().ratio, content="0.5")
}

///|
test "SwingConfig::triplet creates ratio ~0.667" {
  assert_float_near(SwingConfig::triplet().ratio, 2.0 / 3.0)
}
