///|
/// Layout constants and calculations for lead sheet rendering

///|
const COLOR_FOREGROUND = "#f1f5f9"

// Layout constants

// Stem direction: notes below B4 (MIDI 71) have stems up

///|
const STEM_DIRECTION_MIDI_THRESHOLD = 71

// Filled note head ellipse ratios

///|
const NOTE_HEAD_RX_RATIO : Double = 0.37894733 * 1.9

///|
const NOTE_HEAD_RY_RATIO : Double = 0.2542448 * 1.9

///|
const NOTE_HEAD_ROTATION = -25.0

///|
const COS_NOTE_HEAD_ROTATION = 0.906308 // cos(25deg)

///|
const SIN_NOTE_HEAD_ROTATION = 0.422618 // sin(25deg)

///|
const STAFF_LINE_SPACING = 15.0

///|
const STAFF_LINES = 5

///|
/// Convert MIDI pitch class to diatonic steps from C
fn pitch_class_to_diatonic_step(pitch_class : Int) -> Int {
  match pitch_class {
    0 | 1 => 0 // C, C#
    2 | 3 => 1 // D, D#
    4 => 2 // E
    5 | 6 => 3 // F, F#
    7 | 8 => 4 // G, G#
    9 | 10 => 5 // A, A#
    11 => 6 // B
    _ => 0
  }
}

///|
/// Convert MIDI number to Y position on staff
/// E4 (MIDI 64) is the bottom line of treble clef
fn midi_to_staff_y(midi : Int, staff_y : Double) -> Double {
  // Calculate pitch class and octave
  let pitch_class = midi % 12
  let octave = midi / 12 - 1

  // Calculate diatonic steps from E4
  // E4 = pitch_class 4, octave 4
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = pitch_class_to_diatonic_step(e4_pitch_class)
  let total_diatonic_steps = (octave - e4_octave) * 7 +
    (note_diatonic_step - e4_diatonic_step)

  // E4 is on the bottom line (staff_y + 4 * staff_line_spacing)
  // Each diatonic step = half a line spacing
  let offset = total_diatonic_steps.to_double() * -(STAFF_LINE_SPACING / 2.0)
  staff_y + STAFF_LINE_SPACING * (STAFF_LINES - 1).to_double() + offset
}
