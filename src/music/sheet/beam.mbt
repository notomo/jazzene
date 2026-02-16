///|
pub const BEAM_THICKNESS : Double = 3.5

///|
const BEAM_REST_CLEARANCE : Double = 8.0

///|
/// Pre-computed beam stem data
pub(all) struct SheetBeamStem {
  x : Double
  y1 : Double
  y2 : Double
} derive(Show)

///|
/// Pre-computed beam rest data
pub(all) struct SheetBeamRest {
  x : Double
  y : Double
  duration : @music.NoteDuration
} derive(Show)

///|
/// Pre-computed beam group layout data
pub(all) struct SheetBeamGroup {
  stem_up : Bool
  first_x : Double
  first_beam_y : Double
  last_x : Double
  last_beam_y : Double
  stems : Array[SheetBeamStem]
  rests : Array[SheetBeamRest]
  show_triplet_label : Bool
  triplet_label_x : Double
  triplet_label_y : Double
} derive(Show)

///|
/// Determine stem direction for a beam group.
fn beam_stem_up(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
) -> Bool {
  let mut max_distance = 0
  let mut result_up = true
  for idx in group {
    match positioned[idx].1.midi {
      Some(midi) => {
        let distance = (midi - STEM_DIRECTION_MIDI_THRESHOLD).abs()
        if distance > max_distance {
          max_distance = distance
          result_up = midi < STEM_DIRECTION_MIDI_THRESHOLD
        }
      }
      None => ()
    }
  }
  result_up
}

///|
/// Calculate beam endpoints (first_beam_y, last_beam_y) with angled beam support.
fn beam_endpoints(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  staff_y : Double,
  key : @music.KeySignature,
  stem_up : Bool,
) -> (Double, Double) {
  let stem_height = STAFF_LINE_SPACING * STEM_HEIGHT_SPACES
  let min_stem_height = STAFF_LINE_SPACING * (STEM_HEIGHT_SPACES - 1.0)
  let note_ys : Array[Double] = []
  for idx in group {
    match positioned[idx].1.midi {
      Some(midi) => note_ys.push(midi_to_staff_y(midi, staff_y, key))
      None => ()
    }
  }
  if note_ys.is_empty() {
    let y = staff_y + STAFF_LINE_SPACING * 2.0
    return (y, y)
  }
  let first_note_y = note_ys[0]
  let last_note_y = note_ys[note_ys.length() - 1]
  let mut min_y = first_note_y
  let mut max_y = first_note_y
  for y in note_ys {
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
  }
  let mut slope = last_note_y - first_note_y
  let should_be_horizontal = if first_note_y == last_note_y {
    true
  } else {
    let is_extreme_at_edge = (min_y == first_note_y || min_y == last_note_y) &&
      (max_y == first_note_y || max_y == last_note_y)
    not(is_extreme_at_edge)
  }
  if should_be_horizontal {
    slope = 0.0
  }
  if slope > STAFF_LINE_SPACING {
    slope = STAFF_LINE_SPACING
  } else if slope < -STAFF_LINE_SPACING {
    slope = -STAFF_LINE_SPACING
  }
  let base_y = if stem_up { min_y - stem_height } else { max_y + stem_height }
  let mut first_beam_y = base_y - slope / 2.0
  let mut last_beam_y = base_y + slope / 2.0
  let mut max_violation = 0.0
  for i, y in note_ys {
    let t = if note_ys.length() <= 1 {
      0.0
    } else {
      i.to_double() / (note_ys.length() - 1).to_double()
    }
    let beam_y_here = first_beam_y + (last_beam_y - first_beam_y) * t
    let stem_len = if stem_up { y - beam_y_here } else { beam_y_here - y }
    if stem_len < min_stem_height {
      let violation = min_stem_height - stem_len
      if violation > max_violation {
        max_violation = violation
      }
    }
  }
  if max_violation > 0.0 {
    if stem_up {
      first_beam_y -= max_violation
      last_beam_y -= max_violation
    } else {
      first_beam_y += max_violation
      last_beam_y += max_violation
    }
  }
  (first_beam_y, last_beam_y)
}

///|
/// Linear interpolation of beam Y at a given x position.
fn beam_y_at(
  x : Double,
  first_x : Double,
  last_x : Double,
  first_beam_y : Double,
  last_beam_y : Double,
) -> Double {
  if (last_x - first_x).abs() < 0.001 {
    first_beam_y
  } else {
    let t = (x - first_x) / (last_x - first_x)
    first_beam_y + (last_beam_y - first_beam_y) * t
  }
}

///|
/// Find first_x and last_x for a beam group (stem x positions of first/last pitched notes)
fn find_beam_x_range(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  note_positions : Array[Double],
  stem_up : Bool,
) -> (Double, Double) {
  let offset = stem_x_offset(stem_up)
  let mut first_x = 0.0
  let mut last_x = 0.0
  let mut found_first = false
  for idx in group {
    match positioned[idx].1.midi {
      Some(_) => {
        let stem_x = note_positions[idx] + offset
        if not(found_first) {
          first_x = stem_x
          found_first = true
        }
        last_x = stem_x
      }
      None => ()
    }
  }
  (first_x, last_x)
}

///|
/// Compute a SheetBeamGroup from raw beam group data
fn compute_beam_group(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  note_positions : Array[Double],
  staff_y : Double,
  key : @music.KeySignature,
) -> SheetBeamGroup {
  let stem_up = beam_stem_up(group, positioned)
  let (first_beam_y, last_beam_y) = beam_endpoints(
    group, positioned, staff_y, key, stem_up,
  )
  let (first_x, last_x) = find_beam_x_range(
    group, positioned, note_positions, stem_up,
  )

  // Compute stems
  let stems : Array[SheetBeamStem] = []
  let x_offset = stem_x_offset(stem_up)
  let y_offset = stem_y_offset(stem_up)
  for idx in group {
    match positioned[idx].1.midi {
      Some(midi) => {
        let note_y = midi_to_staff_y(midi, staff_y, key)
        let sx = note_positions[idx] + x_offset
        let sy1 = note_y + y_offset
        let sy2 = beam_y_at(sx, first_x, last_x, first_beam_y, last_beam_y)
        stems.push(SheetBeamStem::{ x: sx, y1: sy1, y2: sy2 })
      }
      None => ()
    }
  }

  // Compute rests
  let rests : Array[SheetBeamRest] = []
  for idx in group {
    let (_, note) = positioned[idx]
    match note.midi {
      None => {
        let note_x = note_positions[idx]
        let beam_y_here = beam_y_at(
          note_x, first_x, last_x, first_beam_y, last_beam_y,
        )
        let default_rest_y = staff_y + STAFF_LINE_SPACING * 2.0
        let rest_y = if stem_up {
          @cmp.maximum(
            default_rest_y,
            beam_y_here +
            BEAM_THICKNESS +
            STAFF_LINE_SPACING +
            BEAM_REST_CLEARANCE,
          )
        } else {
          @cmp.minimum(
            default_rest_y,
            beam_y_here -
            BEAM_THICKNESS -
            STAFF_LINE_SPACING -
            BEAM_REST_CLEARANCE,
          )
        }
        rests.push(SheetBeamRest::{
          x: note_x,
          y: rest_y,
          duration: note.duration,
        })
      }
      Some(_) => ()
    }
  }

  // Triplet label
  let is_triplet = group.length() == 3 &&
    group.iter().all(fn(idx) { positioned[idx].1.duration is EighthTriplet })
  let triplet_label_offset = 10.0
  let (triplet_label_x, triplet_label_y) = if is_triplet {
    let cx = (first_x + last_x) / 2.0
    let cy = if stem_up {
      (first_beam_y + last_beam_y) / 2.0 - triplet_label_offset
    } else {
      (first_beam_y + last_beam_y) / 2.0 + triplet_label_offset + 14.0
    }
    (cx, cy)
  } else {
    (0.0, 0.0)
  }

  SheetBeamGroup::{
    stem_up,
    first_x,
    first_beam_y,
    last_x,
    last_beam_y,
    stems,
    rests,
    show_triplet_label: is_triplet,
    triplet_label_x,
    triplet_label_y,
  }
}
