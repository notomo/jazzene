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

///|
/// Return the beat group index for a given start beat position.
/// In 4/4: beats 0,1 → group 0, beats 2,3 → group 1
/// In 3/4: beats 0,1 → group 0, beat 2 → group 1
/// Default: groups of 2 beats
pub fn TimeSignature::beat_group_index(
  self : TimeSignature,
  start_beat : Double,
) -> Int {
  let group_size = match (self.numerator, self.denominator) {
    (3, 4) =>
      // 3/4: [0,1], [2]
      if start_beat < 2.0 {
        return 0
      } else {
        return 1
      }
    _ => 2.0
  }
  (start_beat / group_size).to_int()
}

///|
/// Return the remaining beats until the next beat group boundary.
/// In 4/4 at position 0.5: 1.5 (boundary at 2.0)
/// In 4/4 at position 2.0: 2.0 (boundary at 4.0)
/// In 3/4 at position 0.5: 1.5 (boundary at 2.0)
/// In 3/4 at position 2.0: 1.0 (boundary at 3.0)
pub fn TimeSignature::beat_group_remaining(
  self : TimeSignature,
  position : Double,
) -> Double {
  let beats = self.beats_per_measure()
  let group_end = match (self.numerator, self.denominator) {
    (3, 4) => if position < 2.0 { 2.0 } else { 3.0 }
    _ => {
      let group_size = 2.0
      let raw_end = ((position / group_size).to_int() + 1).to_double() *
        group_size
      if raw_end < beats {
        raw_end
      } else {
        beats
      }
    }
  }
  group_end - position
}

///|
/// Returns all supported time signatures
pub fn TimeSignature::all() -> Array[TimeSignature] {
  [
    TimeSignature::{ numerator: 4, denominator: 4 },
    TimeSignature::{ numerator: 3, denominator: 4 },
  ]
}

///|
pub fn TimeSignature::to_string(self : TimeSignature) -> String {
  self.numerator.to_string() + "/" + self.denominator.to_string()
}

///|
pub fn TimeSignature::from_string(s : String) -> Result[TimeSignature, String] {
  match s {
    "4/4" => Ok(TimeSignature::{ numerator: 4, denominator: 4 })
    "3/4" => Ok(TimeSignature::{ numerator: 3, denominator: 4 })
    _ => Err("Unknown time signature: " + s)
  }
}
