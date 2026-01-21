///|
/// MIDI number newtype with validation (0-127)
pub struct MidiNumber {
  value : Int
} derive(Eq, Show)

///|
/// Create MidiNumber with validation
pub fn MidiNumber::new(value : Int) -> MidiNumber? {
  match value {
    0..=127 => Some(MidiNumber::{ value, })
    _ => None
  }
}

///|
/// Shift by octaves (positive = up, negative = down)
/// Returns None if result would be outside valid MIDI range (0-127)
pub fn MidiNumber::shift_octave(
  self : MidiNumber,
  octaves : Int,
) -> MidiNumber? {
  MidiNumber::new(self.value + octaves * 12)
}

///|
/// Convert MIDI number to frequency in Hz
/// Uses the formula: f = 440 * 2^((n-69)/12)
/// where MIDI 69 = A4 = 440 Hz
pub fn MidiNumber::to_frequency(self : MidiNumber) -> Double {
  440.0 * @math.pow(2.0, (self.value.to_double() - 69.0) / 12.0)
}
