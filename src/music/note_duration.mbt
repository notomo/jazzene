///|
/// Note duration types for rhythm variation
pub(all) enum NoteDuration {
  Eighth // 0.5 beats
  Quarter // 1 beat
  Half // 2 beats
  Whole // 4 beats
  DottedEighth // 0.75 beats
  DottedQuarter // 1.5 beats
  DottedHalf // 3.0 beats
} derive(Eq, Show)

///|
/// Convert note duration to beats
pub fn NoteDuration::to_beats(self : NoteDuration) -> Double {
  match self {
    Eighth => 0.5
    Quarter => 1.0
    Half => 2.0
    Whole => 4.0
    DottedEighth => 0.75
    DottedQuarter => 1.5
    DottedHalf => 3.0
  }
}

///|
/// Convert beats to the closest note duration
pub fn NoteDuration::from_beats(beats : Double) -> NoteDuration {
  if beats <= 0.625 {
    Eighth
  } else if beats <= 0.875 {
    DottedEighth
  } else if beats <= 1.25 {
    Quarter
  } else if beats <= 1.75 {
    DottedQuarter
  } else if beats <= 2.5 {
    Half
  } else if beats <= 3.5 {
    DottedHalf
  } else {
    Whole
  }
}

///|
/// Find the largest duration that fits within remaining_beats
pub fn NoteDuration::fit(remaining_beats : Double) -> NoteDuration? {
  [Whole, DottedHalf, Half, DottedQuarter, Quarter, DottedEighth, Eighth]
  .iter()
  .find_first(fn(d) { d.to_beats() <= remaining_beats + 0.001 })
}
