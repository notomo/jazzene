///|
/// MIDI number newtype with validation (0-127)
pub struct MidiNumber {
  value : Int
} derive(Eq, Show)

///|
/// Create MidiNumber with validation
pub fn MidiNumber::new(value : Int) -> MidiNumber? {
  if value >= 0 && value <= 127 {
    Some(MidiNumber::{ value, })
  } else {
    None
  }
}

///|
/// Convert MIDI number to frequency in Hz
/// Uses the formula: f = 440 * 2^((n-69)/12)
/// where MIDI 69 = A4 = 440 Hz
pub fn MidiNumber::to_frequency(self : MidiNumber) -> Double {
  440.0 * @math.pow(2.0, (self.value.to_double() - 69.0) / 12.0)
}
