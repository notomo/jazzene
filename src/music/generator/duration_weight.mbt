///|
/// Weights for random duration selection
pub(all) struct DurationWeights {
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
pub fn DurationWeights::note_default() -> DurationWeights {
  DurationWeights::{
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
pub fn DurationWeights::rest_default() -> DurationWeights {
  DurationWeights::{
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
pub fn random_duration(
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
