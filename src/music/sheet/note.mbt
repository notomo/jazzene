///|
pub const STEM_HEIGHT_SPACES : Double = 3.0

///|
pub const NOTE_HEAD_RX_RATIO : Double = 0.37894733 * 1.9

///|
pub const NOTE_HEAD_RY_RATIO : Double = 0.2542448 * 1.9

///|
pub const COS_NOTE_HEAD_ROTATION : Double = 0.906308

///|
pub const SIN_NOTE_HEAD_ROTATION : Double = 0.422618

///|
const STEM_DIRECTION_MIDI_THRESHOLD : Int = 71

///|
const NOTE_AREA_START_OFFSET : Double = 42.0

///|
const NOTE_AREA_PADDING : Double = 84.0

///|
const MIN_NOTE_SPACING : Double = 32.0

///|
const FLAGGED_EIGHTH_EXTRA_SPACING : Double = 15.0

///|
const ACCIDENTAL_EXTRA_SPACING : Double = 14.0

///|
/// Pre-computed note layout data
pub(all) struct SheetNote {
  x : Double
  y : Double
  duration : @music.NoteDuration
  accidental : @music.Accidental?
  tie : @music.Tie?
  is_rest : Bool
  stem_up : Bool
  beamed : Bool
  diatonic_step : Int
  on_line : Bool
  tie_arcs : Array[SheetTieArc]
  midi : Int?
} derive(Show)

///|
/// Calculate stem x offset from note center
fn stem_x_offset(stem_up : Bool) -> Double {
  let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
  if stem_up {
    rx * COS_NOTE_HEAD_ROTATION
  } else {
    -(rx * COS_NOTE_HEAD_ROTATION)
  }
}

///|
/// Calculate stem y offset from note center
fn stem_y_offset(stem_up : Bool) -> Double {
  let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
  if stem_up {
    -(rx * SIN_NOTE_HEAD_ROTATION)
  } else {
    rx * SIN_NOTE_HEAD_ROTATION
  }
}

///|
/// Calculate stem position (x, y1, y2) from note position and stem direction
pub fn calculate_stem(
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> (Double, Double, Double) {
  let stem_height = STAFF_LINE_SPACING * STEM_HEIGHT_SPACES
  let stem_x = note_x + stem_x_offset(stem_up)
  let y1 = note_y + stem_y_offset(stem_up)
  let y2 = if stem_up { y1 - stem_height } else { y1 + stem_height }
  (stem_x, y1, y2)
}

///|
/// Visual weight for duration-proportional spacing
fn duration_visual_weight(duration : @music.NoteDuration) -> Double {
  match duration {
    EighthTriplet => 0.545
    Eighth => 0.667
    DottedEighth => 0.852
    Quarter => 1.0
    DottedQuarter => 1.271
    Half => 1.5
    DottedHalf => 1.814
    Whole => 2.25
  }
}

///|
/// Calculate minimum spacing between note at index i and its predecessor.
fn note_min_spacing(
  i : Int,
  positioned : Array[(Double, @music.MeasureNote)],
  beamed_indices : Map[Int, Bool],
) -> Double {
  let (_, note) = positioned[i]
  let (_, prev_note) = positioned[i - 1]
  let prev_has_flag = if beamed_indices.contains(i - 1) {
    false
  } else {
    match prev_note.duration {
      Eighth | DottedEighth | EighthTriplet => true
      _ => false
    }
  }
  let has_accidental_space = note.accidental is Some(_)
  MIN_NOTE_SPACING +
  (if prev_has_flag { FLAGGED_EIGHTH_EXTRA_SPACING } else { 0.0 }) +
  (if has_accidental_space { ACCIDENTAL_EXTRA_SPACING } else { 0.0 })
}

///|
/// Compute x positions for all notes in a measure
fn compute_note_positions(
  positioned : Array[(Double, @music.MeasureNote)],
  measure_x : Double,
  beamed_indices : Map[Int, Bool],
  measure_width? : Double = MIN_MEASURE_WIDTH,
) -> Array[Double] {
  let n = positioned.length()
  if n == 0 {
    return []
  }
  let note_area_start = measure_x + NOTE_AREA_START_OFFSET
  let note_area_width = measure_width - NOTE_AREA_PADDING
  let cumulative_weights : Array[Double] = Array::make(n, 0.0)
  let mut total_weight = 0.0
  for i = 0; i < n; i = i + 1 {
    cumulative_weights[i] = total_weight
    total_weight = total_weight +
      duration_visual_weight(positioned[i].1.duration)
  }
  let positions : Array[Double] = []
  for i, pair in positioned {
    let (_, note) = pair
    let proportional_x = match (note.midi, note.duration) {
      (None, Whole) => measure_x + measure_width / 2.0
      _ =>
        if total_weight > 0.0 {
          note_area_start +
          cumulative_weights[i] * note_area_width / total_weight
        } else {
          note_area_start
        }
    }
    let x = if i == 0 {
      proportional_x
    } else {
      let min_spacing = note_min_spacing(i, positioned, beamed_indices)
      @cmp.maximum(proportional_x, positions[i - 1] + min_spacing)
    }
    positions.push(x)
  }
  positions
}

///|
/// Compute the ideal measure width needed to fit all notes without compression.
/// Uses sum of minimum spacings to determine the width where no collisions occur.
pub fn compute_ideal_measure_width(
  positioned : Array[(Double, @music.MeasureNote)],
  beamed_indices : Map[Int, Bool],
) -> Double {
  let n = positioned.length()
  if n <= 1 {
    return MIN_MEASURE_WIDTH
  }
  let total_min_spacing = (1)
    .until(n)
    .fold(init=0.0, fn(acc, i) {
      acc + note_min_spacing(i, positioned, beamed_indices)
    })
  total_min_spacing + NOTE_AREA_PADDING
}
