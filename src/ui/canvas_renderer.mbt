///|
/// Rectangle - Basic geometry type for canvas calculations
pub struct Rectangle {
  left : Double
  top : Double
  width : Double
  height : Double
}

///|
/// KeyArea - Represents a piano key with position and metadata
pub struct KeyArea {
  rect : Rectangle
  midi : Int
  is_black : Bool
}

///|
/// Each entry is (left_ratio, right_ratio) for a semitone within an octave
/// Based on: white key = 22mm, black key = 10mm, octave = 154mm (7 white keys)
let key_ratio : Array[(Double, Double)] = [
  (0.0, 0.1429), // 0:  C  (white, 0-22mm)
  (0.1104, 0.1753), // 1:  C# (black, 17-27mm, centered at 22mm)
  (0.1429, 0.2857), // 2:  D  (white, 22-44mm)
  (0.2532, 0.3182), // 3:  D# (black, 39-49mm, centered at 44mm)
  (0.2857, 0.4286), // 4:  E  (white, 44-66mm)
  (0.4286, 0.5714), // 5:  F  (white, 66-88mm)
  (0.5390, 0.6039), // 6:  F# (black, 83-93mm, centered at 88mm)
  (0.5714, 0.7143), // 7:  G  (white, 88-110mm)
  (0.6818, 0.7468), // 8:  G# (black, 105-115mm, centered at 110mm)
  (0.7143, 0.8571), // 9:  A  (white, 110-132mm)
  (0.8247, 0.8896), // 10: A# (black, 127-137mm, centered at 132mm)
  (0.8571, 1.0), // 11: B  (white, 132-154mm)
]

///|
/// Calculate exact rectangles for each key in MIDI range
///
/// # Arguments
/// * `rect` - The bounding rectangle for all keys
/// * `min_key` - Minimum MIDI note number (e.g., 36 for C2)
/// * `max_key` - Maximum MIDI note number (e.g., 96 for C7)
///
/// # Returns
/// Array of KeyArea with exact position and size for each key
pub fn calc_key_areas(
  rect : Rectangle,
  min_key : Int,
  max_key : Int,
) -> Array[KeyArea] {
  let min_octave = min_key / 12
  let min_note = min_key % 12
  let max_note = max_key % 12

  // Calculate base offset ratio
  let (min_left_ratio, _) = key_ratio[min_note]
  let base_offset_ratio = min_octave.to_double() + min_left_ratio

  // Calculate octave width
  let min_aligned = min_key + 12 - min_key % 12
  let max_aligned = max_key - max_key % 12
  let (_, max_right_ratio) = key_ratio[max_note]
  let total_octave_ratio = (max_aligned - min_aligned).to_double() / 12.0 +
    (1.0 - min_left_ratio) +
    max_right_ratio
  let octave_width = rect.width / total_octave_ratio

  // Build key areas
  let areas : Array[KeyArea] = []
  for key = min_key; key <= max_key; key = key + 1 {
    let note_index = key % 12
    let octave = (key / 12).to_double()
    let (left_ratio, right_ratio) = key_ratio[note_index]
    let left = rect.left +
      (octave + left_ratio - base_offset_ratio) * octave_width
    let right = rect.left +
      (octave + right_ratio - base_offset_ratio) * octave_width
    areas.push({
      rect: { left, top: rect.top, width: right - left, height: rect.height },
      midi: key,
      is_black: is_black_key(note_index),
    })
  }
  areas
}

///|
/// Check if a note is a black key (chromatic scale position)
fn is_black_key(note_in_octave : Int) -> Bool {
  match note_in_octave {
    1 | 3 | 6 | 8 | 10 => true // C#, D#, F#, G#, A#
    _ => false
  }
}
