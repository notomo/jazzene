///|
/// Syncopation check: on downbeats, probabilistically return an eighth rest
/// to shift the phrase start to the upbeat.
/// Returns Some(Eighth) if syncopation fires, None otherwise.
fn syncopation_rest(
  measure_pos : Double,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> @music.NoteDuration? {
  guard probability > 0 else { return None }
  let is_on_downbeat = (measure_pos - measure_pos.to_int().to_double()).abs() <
    0.01
  guard is_on_downbeat && random_int(100) < probability else { return None }
  if remaining >= @music.Eighth.to_beats() {
    Some(@music.Eighth)
  } else {
    None
  }
}

///|
test "syncopation_rest returns Eighth on downbeat when probability passes" {
  // random_int always returns 0 (< any positive probability)
  let result = syncopation_rest(0.0, 2.0, 100, fn(_) { 0 })
  assert_eq(result, Some(@music.Eighth))
}

///|
test "syncopation_rest returns None on offbeat" {
  let result = syncopation_rest(0.5, 2.0, 100, fn(_) { 0 })
  assert_eq(result, None)
}

///|
test "syncopation_rest returns None when probability is 0" {
  let result = syncopation_rest(0.0, 2.0, 0, fn(_) { 0 })
  assert_eq(result, None)
}

///|
test "syncopation_rest returns None when probability check fails" {
  // random_int returns 99, probability is 50 → 99 >= 50 → no syncopation
  let result = syncopation_rest(0.0, 2.0, 50, fn(_) { 99 })
  assert_eq(result, None)
}

///|
test "syncopation_rest returns None when remaining too small for eighth" {
  // remaining = 0.25 beats, eighth needs 0.5
  let result = syncopation_rest(0.0, 0.25, 100, fn(_) { 0 })
  assert_eq(result, None)
}

///|
test "syncopation_rest works on integer beat positions" {
  // Beat 2.0 is a downbeat
  let result = syncopation_rest(2.0, 2.0, 100, fn(_) { 0 })
  assert_eq(result, Some(@music.Eighth))
}
