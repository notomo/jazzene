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
} derive(Eq, Show)

///|
/// Default weights for notes, favoring quarter notes
pub fn DurationWeights::note_default() -> DurationWeights {
  DurationWeights::{
    eighth: 15,
    dotted_eighth: 10,
    quarter: 40,
    dotted_quarter: 20,
    half: 8,
    dotted_half: 5,
    whole: 2,
  }
}

///|
/// Default weights for rests (no dotted durations)
pub fn DurationWeights::rest_default() -> DurationWeights {
  DurationWeights::{
    eighth: 15,
    dotted_eighth: 0,
    quarter: 40,
    dotted_quarter: 0,
    half: 8,
    dotted_half: 0,
    whole: 2,
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
