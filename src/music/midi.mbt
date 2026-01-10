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
