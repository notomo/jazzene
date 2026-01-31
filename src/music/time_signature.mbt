///|
/// Time signature representation (e.g. 4/4, 3/4, 6/8)
pub(all) struct TimeSignature {
  numerator : Int // Beats per measure (e.g. 4)
  denominator : Int // Beat unit (e.g. 4 = quarter note)
}

///|
/// Default time signature: 4/4
pub fn TimeSignature::default() -> TimeSignature {
  TimeSignature::{ numerator: 4, denominator: 4 }
}

///|
/// Calculate beats per measure in quarter note units
/// e.g. 4/4 = 4.0, 3/4 = 3.0, 6/8 = 3.0
pub fn TimeSignature::beats_per_measure(self : TimeSignature) -> Double {
  self.numerator.to_double() * (4.0 / self.denominator.to_double())
}
