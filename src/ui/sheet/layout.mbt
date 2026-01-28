///|
/// Layout constants and calculations for lead sheet rendering

///|
let color_foreground = "#f1f5f9"

// Layout constants

// Stem direction: notes below B4 (MIDI 71) have stems up

///|
let stem_direction_midi_threshold = 71

// Augmentation dot rendering (shared by note.mbt and rest.mbt)

///|
let dot_radius_ratio = 0.15

///|
let dot_x_offset_ratio = 1.5

// Filled note head ellipse ratios

///|
let note_head_rx_ratio : Double = 0.37894733 * 1.9

///|
let note_head_ry_ratio : Double = 0.2542448 * 1.9

///|
let note_head_rotation = -25.0

///|
let cos_note_head_rotation = 0.906308 // cos(25deg)

///|
let sin_note_head_rotation = 0.422618 // sin(25deg)

///|
let staff_top = 120.0

///|
let staff_line_spacing = 15.0

///|
let staff_lines = 5

///|
let measures_per_row = 4

///|
let measure_width = 280.0

///|
let clef_space_width = 50.0

///|
let measure_start_x = 40.0

///|
let row_height = 250.0

///|
/// Calculate measure position in the layout
/// First measure of each row is offset by clef_space_width for the treble clef
fn measure_position(measure_index : Int) -> (Double, Double) {
  let col = measure_index % measures_per_row
  let row = measure_index / measures_per_row
  let clef_offset = clef_space_width
  let x = measure_start_x + clef_offset + col.to_double() * measure_width
  let y = staff_top + row.to_double() * row_height
  (x, y)
}

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
  let offset = total_diatonic_steps.to_double() * -(staff_line_spacing / 2.0)
  staff_y + staff_line_spacing * (staff_lines - 1).to_double() + offset
}
