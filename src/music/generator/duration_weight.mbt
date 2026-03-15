///|
/// Weights for random duration selection
struct DurationWeights {
  sixteenth : Int
  eighth : Int
  dotted_eighth : Int
  quarter : Int
  dotted_quarter : Int
  half : Int
  dotted_half : Int
  whole : Int
  eighth_triplet : Int
} derive(Eq, Show)

///|
/// Default weights for notes, favoring eighth notes for jazz phrasing
fn DurationWeights::note_default() -> DurationWeights {
  DurationWeights::{
    sixteenth: 0,
    eighth: 45,
    dotted_eighth: 0,
    quarter: 20,
    dotted_quarter: 3,
    half: 2,
    dotted_half: 0,
    whole: 2,
    eighth_triplet: 0,
  }
}

///|
/// Default weights for rests, shorter rests for jazz feel
fn DurationWeights::rest_default() -> DurationWeights {
  DurationWeights::{
    sixteenth: 0,
    eighth: 40,
    dotted_eighth: 0,
    quarter: 25,
    dotted_quarter: 0,
    half: 5,
    dotted_half: 0,
    whole: 0,
    eighth_triplet: 0,
  }
}

///|
/// Convert duration weights to an array of (weight, duration) pairs
fn DurationWeights::to_choices(
  self : DurationWeights,
) -> Array[(Int, @music.NoteDuration)] {
  [
    (self.sixteenth, @music.Sixteenth),
    (self.eighth, @music.Eighth),
    (self.dotted_eighth, @music.DottedEighth),
    (self.quarter, @music.Quarter),
    (self.dotted_quarter, @music.DottedQuarter),
    (self.half, @music.Half),
    (self.dotted_half, @music.DottedHalf),
    (self.whole, @music.Whole),
    (self.eighth_triplet, @music.EighthTriplet),
  ]
}

///|
/// Select a random item from weighted choices
fn[T] weighted_choice(
  choices : Array[(Int, T)],
  random_int : (Int) -> Int,
) -> T {
  let total = choices.iter().fold(init=0, fn(acc, pair) { acc + pair.0 })
  let r = random_int(total)

  let mut cumulative = 0
  for _, pair in choices {
    cumulative = cumulative + pair.0
    if r < cumulative {
      return pair.1
    }
  }
  choices[choices.length() - 1].1
}

///|
/// Generate a random duration based on weights
fn random_duration(
  weights : DurationWeights,
  random_int : (Int) -> Int,
) -> @music.NoteDuration {
  weighted_choice(weights.to_choices(), random_int)
}

///|
/// Generate a random duration that fits within the given beat capacity
fn random_duration_within(
  max_beats : Double,
  weights : DurationWeights,
  random_int : (Int) -> Int,
) -> @music.NoteDuration? {
  let choices = weights
    .to_choices()
    .iter()
    .filter(fn(pair) { pair.0 > 0 && pair.1.to_beats() <= max_beats + 0.001 })
    .collect()

  if choices.is_empty() {
    None
  } else {
    Some(weighted_choice(choices, random_int))
  }
}

///|
test "DurationWeights::note_default has eighth as dominant weight" {
  let w = DurationWeights::note_default()
  assert_true(w.eighth > w.quarter)
  assert_true(w.eighth > w.half)
  assert_eq(w.sixteenth, 0)
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
  // Sixteenth weight is 0, so r=0 falls to Eighth (first non-zero weight)
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
    sixteenth: 0,
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
    sixteenth: 0,
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
    sixteenth: 0,
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
