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
const NOTE_AREA_START_OFFSET : Double = 40.0

///|
const NOTE_AREA_PADDING : Double = 75.0

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
  let has_accidental_space = note.accidental is Some(_) &&
    not(beamed_indices.contains(i))
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
) -> Array[Double] {
  let n = positioned.length()
  if n == 0 {
    return []
  }
  let note_area_start = measure_x + NOTE_AREA_START_OFFSET
  let note_area_width = MEASURE_WIDTH - NOTE_AREA_PADDING
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
      (None, Whole) => measure_x + MEASURE_WIDTH / 2.0
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
  compress_overflow(
    positions,
    positioned,
    beamed_indices,
    note_area_start + note_area_width,
  )
  positions
}

///|
/// Compress positions that overflow the available area
fn compress_overflow(
  positions : Array[Double],
  positioned : Array[(Double, @music.MeasureNote)],
  beamed_indices : Map[Int, Bool],
  right_edge : Double,
) -> Unit {
  let n = positions.length()
  guard n > 1 && positions[n - 1] > right_edge else { return }
  let first_pos = positions[0]
  let available_span = right_edge - first_pos
  let min_gaps : Array[Double] = []
  let extras : Array[Double] = []
  let mut total_min = 0.0
  let mut total_extra = 0.0
  for i = 1; i < n; i = i + 1 {
    let min_sp = note_min_spacing(i, positioned, beamed_indices)
    let gap = positions[i] - positions[i - 1]
    let extra = gap - min_sp
    min_gaps.push(min_sp)
    extras.push(extra)
    total_min = total_min + min_sp
    total_extra = total_extra + extra
  }
  if available_span >= total_min {
    let extra_scale = if total_extra > 0.0 {
      (available_span - total_min) / total_extra
    } else {
      0.0
    }
    for i = 1; i < n; i = i + 1 {
      positions[i] = positions[i - 1] +
        min_gaps[i - 1] +
        extras[i - 1] * extra_scale
    }
  } else {
    let mut critical_total = 0.0
    let mut flexible_total = 0.0
    let is_critical : Array[Bool] = []
    for i = 0; i < min_gaps.length(); i = i + 1 {
      let critical = min_gaps[i] > MIN_NOTE_SPACING
      is_critical.push(critical)
      if critical {
        critical_total = critical_total + min_gaps[i]
      } else {
        flexible_total = flexible_total + (min_gaps[i] + extras[i])
      }
    }
    let flexible_available = available_span - critical_total
    let flexible_scale = if flexible_total > 0.0 {
      @cmp.maximum(0.0, flexible_available / flexible_total)
    } else {
      0.0
    }
    for i = 1; i < n; i = i + 1 {
      let gap_idx = i - 1
      let new_gap = if is_critical[gap_idx] {
        min_gaps[gap_idx]
      } else {
        (min_gaps[gap_idx] + extras[gap_idx]) * flexible_scale
      }
      positions[i] = positions[i - 1] + new_gap
    }
  }
}
