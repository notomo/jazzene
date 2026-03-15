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

///|
test "midi_to_diatonic_step - E4 is step 0 (bottom staff line)" {
  let key = @music.KeySignature::c_major()
  inspect(midi_to_diatonic_step(64, key), content="0") // E4
}

///|
test "midi_to_diatonic_step - C4 is step -2 (middle C, below staff)" {
  let key = @music.KeySignature::c_major()
  inspect(midi_to_diatonic_step(60, key), content="-2") // C4
}

///|
test "midi_to_diatonic_step - F5 is step 8 (above staff)" {
  let key = @music.KeySignature::c_major()
  inspect(midi_to_diatonic_step(77, key), content="8") // F5
}

///|
test "midi_to_diatonic_step - B4 on Bb key" {
  let key = @music.KeySignature::from_root(@music.ASharp) // Bb major
  // B4 (MIDI 71) in Bb key: pitch_class=11, step=6
  let step = midi_to_diatonic_step(71, key)
  inspect(step, content="4")
}

///|
test "midi_to_staff_y - E4 at bottom staff line" {
  let key = @music.KeySignature::c_major()
  let staff_y = 120.0
  let y = midi_to_staff_y(64, staff_y, key)
  // E4 is step 0, so y = staff_y + STAFF_LINE_SPACING * 4 + 0 = 120 + 60 = 180
  inspect(y, content="180")
}

///|
test "midi_to_staff_y - F4 one step up from E4" {
  let key = @music.KeySignature::c_major()
  let staff_y = 120.0
  let e4_y = midi_to_staff_y(64, staff_y, key) // E4
  let f4_y = midi_to_staff_y(65, staff_y, key) // F4
  // F4 is one diatonic step above E4 → half a line spacing higher (lower y)
  inspect(e4_y - f4_y == STAFF_LINE_SPACING / 2.0, content="true")
}

///|
test "ledger_steps_below - C4 needs one ledger line" {
  let steps = ledger_steps_below(-2) // C4 = step -2
  inspect(steps, content="[-2]")
}

///|
test "ledger_steps_below - no ledger lines for notes on staff" {
  let steps = ledger_steps_below(0) // E4 = step 0 (on staff)
  inspect(steps, content="[]")
}

///|
test "ledger_steps_above - G5 needs one ledger line" {
  let steps = ledger_steps_above(10) // G5 = step 10
  inspect(steps, content="[10]")
}

///|
test "ledger_steps_above - no ledger lines for notes on staff" {
  let steps = ledger_steps_above(8) // F5 = step 8 (within threshold)
  inspect(steps, content="[]")
}
