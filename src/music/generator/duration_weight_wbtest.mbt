///|
test "DurationWeights::note_default has eighth as dominant weight" {
  let w = DurationWeights::note_default()
  assert_true(w.eighth > w.quarter)
  assert_true(w.eighth > w.half)
}

///|
test "DurationWeights::rest_default has no eighth_triplet" {
  let w = DurationWeights::rest_default()
  assert_eq(w.eighth_triplet, 0)
}

///|
test "random_duration returns a valid duration" {
  let w = DurationWeights::note_default()
  // Just ensure it doesn't crash and returns something
  let result = random_duration(w, fn(_) { 0 })
  // Eighth has highest weight, so with r=0 we should get Eighth
  inspect(result, content="Eighth")
}

///|
test "random_duration_within returns None when no duration fits" {
  let w = DurationWeights::note_default()
  // max_beats = 0.1 — no duration fits (smallest is Eighth = 0.5)
  let result = random_duration_within(0.1, w, fn(_) { 0 })
  assert_eq(result, None)
}

///|
test "random_duration_within returns Some when max_beats >= 0.5" {
  let w = DurationWeights::note_default()
  let result = random_duration_within(0.5, w, fn(_) { 0 })
  match result {
    Some(_) => ()
    None => fail("Expected Some duration for 0.5 beats capacity")
  }
}

///|
test "random_duration_within only returns durations that fit" {
  let w = DurationWeights::{
    eighth: 0,
    dotted_eighth: 0,
    quarter: 10,
    dotted_quarter: 0,
    half: 10,
    dotted_half: 0,
    whole: 10,
    eighth_triplet: 0,
  }
  // max_beats = 1.0 — Quarter(1.0) fits, Half(2.0) and Whole(4.0) do not
  for r in 0..<30 {
    let result = random_duration_within(1.0, w, fn(_) { r % 30 })
    match result {
      Some(d) => assert_true(d.to_beats() <= 1.0 + 0.001)
      None => ()
    }
  }
}

///|
test "weighted_choice selects first item with weight when r=0" {
  // DurationWeights with only Eighth weight
  let w = DurationWeights::{
    eighth: 10,
    dotted_eighth: 0,
    quarter: 10,
    dotted_quarter: 0,
    half: 0,
    dotted_half: 0,
    whole: 0,
    eighth_triplet: 0,
  }
  // total = 20, r=0 → first choice (Eighth)
  let result = random_duration(w, fn(_) { 0 })
  inspect(result, content="Eighth")
}

///|
test "weighted_choice selects second item when r falls in second bucket" {
  let w = DurationWeights::{
    eighth: 10,
    dotted_eighth: 0,
    quarter: 10,
    dotted_quarter: 0,
    half: 0,
    dotted_half: 0,
    whole: 0,
    eighth_triplet: 0,
  }
  // total = 20, r=10 → second choice (Quarter)
  let result = random_duration(w, fn(_) { 10 })
  inspect(result, content="Quarter")
}
