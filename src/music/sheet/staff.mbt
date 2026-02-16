///|
pub const STAFF_LINE_SPACING : Double = 15.0

///|
pub const STAFF_LINES : Int = 5

///|
const FIRST_LEDGER_LINE_BELOW_STEP : Int = -2

///|
const UPPER_LEDGER_LINE_THRESHOLD : Int = 8

///|
const FIRST_LEDGER_LINE_ABOVE_STEP : Int = 10

///|
/// Calculate diatonic steps from E4 (bottom line of treble clef)
fn midi_to_diatonic_step(midi : Int, key : @music.KeySignature) -> Int {
  let pitch_class = midi % 12
  let octave = midi / 12 - 1
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = key.pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = key.pitch_class_to_diatonic_step(e4_pitch_class)
  (octave - e4_octave) * 7 + (note_diatonic_step - e4_diatonic_step)
}

///|
/// Convert MIDI number to Y position on staff
pub fn midi_to_staff_y(
  midi : Int,
  staff_y : Double,
  key : @music.KeySignature,
) -> Double {
  let total_diatonic_steps = midi_to_diatonic_step(midi, key)
  let offset = total_diatonic_steps.to_double() * -(STAFF_LINE_SPACING / 2.0)
  staff_y + STAFF_LINE_SPACING * (STAFF_LINES - 1).to_double() + offset
}

///|
/// Generate ledger line steps for notes below the staff
pub fn ledger_steps_below(step : Int) -> Array[Int] {
  if step >= 0 {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (FIRST_LEDGER_LINE_BELOW_STEP - end_step) / 2 + 1
  Array::makei(count, fn(i) { FIRST_LEDGER_LINE_BELOW_STEP - i * 2 })
}

///|
/// Generate ledger line steps for notes above the staff
pub fn ledger_steps_above(step : Int) -> Array[Int] {
  if step <= UPPER_LEDGER_LINE_THRESHOLD {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (end_step - FIRST_LEDGER_LINE_ABOVE_STEP) / 2 + 1
  Array::makei(count, fn(i) { FIRST_LEDGER_LINE_ABOVE_STEP + i * 2 })
}
