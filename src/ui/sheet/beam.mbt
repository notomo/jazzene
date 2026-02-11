///|
/// Beam rendering for connected eighth notes

///|
const BEAM_THICKNESS = 3.5

///|
const BEAM_REST_CLEARANCE = 8.0

///|
const TRIPLET_LABEL_OFFSET = 10.0

///|
const TRIPLET_LABEL_FONT_SIZE = "20"

///|
/// Determine stem direction for a beam group.
/// Uses the note furthest from MIDI 71 (B4) among non-rest notes.
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

  // Collect note_y values for non-rest notes
  let note_ys : Array[Double] = []
  for idx in group {
    match positioned[idx].1.midi {
      Some(midi) => note_ys.push(midi_to_staff_y(midi, staff_y, key))
      None => ()
    }
  }
  // Fallback: if no pitched notes, return horizontal at staff center
  if note_ys.is_empty() {
    let y = staff_y + STAFF_LINE_SPACING * 2.0
    return (y, y)
  }

  let first_note_y = note_ys[0]
  let last_note_y = note_ys[note_ys.length() - 1]
  // Determine min/max of all note_ys
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

  // Determine slope (positive = descending pitch, since Y increases downward)
  let mut slope = last_note_y - first_note_y
  // Check horizontal conditions
  let should_be_horizontal = if first_note_y == last_note_y {
    // Same pitch at endpoints
    true
  } else {
    // Convex/concave: extreme note is not at an endpoint
    let is_extreme_at_edge = (min_y == first_note_y || min_y == last_note_y) &&
      (max_y == first_note_y || max_y == last_note_y)
    not(is_extreme_at_edge)
  }
  if should_be_horizontal {
    slope = 0.0
  }
  // Clamp slope to max STAFF_LINE_SPACING
  if slope > STAFF_LINE_SPACING {
    slope = STAFF_LINE_SPACING
  } else if slope < -STAFF_LINE_SPACING {
    slope = -STAFF_LINE_SPACING
  }

  // Calculate base_y (the beam position for the "extreme" side)
  let base_y = if stem_up { min_y - stem_height } else { max_y + stem_height }
  // Distribute slope around base_y
  let mut first_beam_y = base_y - slope / 2.0
  let mut last_beam_y = base_y + slope / 2.0

  // Minimum stem length check: ensure every note has adequate stem length
  let mut max_violation = 0.0
  for i, y in note_ys {
    // Interpolate beam_y at this note's position (linear between first and last)
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
  // Shift beam away from noteheads if any stem is too short
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
/// Render a single beam group
fn render_beam_group(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  note_positions : Array[Double],
  staff_y : Double,
  key : @music.KeySignature,
  stem_up : Bool,
  first_beam_y : Double,
  last_beam_y : Double,
) -> Array[@luna_dom.DomNode] {
  let nodes : Array[@luna_dom.DomNode] = []
  let mut first_x = 0.0
  let mut last_x = 0.0
  let mut found_first = false

  // First pass: find first_x and last_x
  for idx in group {
    let (_, note) = positioned[idx]
    let note_x = note_positions[idx]
    match note.midi {
      Some(_) => {
        let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
        let cos_25 = COS_NOTE_HEAD_ROTATION
        let stem_x_offset = if stem_up { rx * cos_25 } else { -(rx * cos_25) }
        let stem_x = note_x + stem_x_offset
        if not(found_first) {
          first_x = stem_x
          found_first = true
        }
        last_x = stem_x
      }
      None => ()
    }
  }

  // Second pass: render stems using interpolated beam_y
  for idx in group {
    let (_, note) = positioned[idx]
    let note_x = note_positions[idx]
    match note.midi {
      Some(midi) => {
        let note_y = midi_to_staff_y(midi, staff_y, key)
        let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
        let cos_25 = COS_NOTE_HEAD_ROTATION
        let sin_25 = SIN_NOTE_HEAD_ROTATION
        let (stem_x_offset, stem_y_offset) = if stem_up {
          (rx * cos_25, -(rx * sin_25))
        } else {
          (-(rx * cos_25), rx * sin_25)
        }
        let stem_x = note_x + stem_x_offset
        let stem_y1 = note_y + stem_y_offset
        let stem_y2 = beam_y_at(
          stem_x, first_x, last_x, first_beam_y, last_beam_y,
        )
        nodes.push(
          @luna_dom.svg_line(
            x1=stem_x.to_string(),
            y1=stem_y1.to_string(),
            x2=stem_x.to_string(),
            y2=stem_y2.to_string(),
            stroke_width="1.5",
          ),
        )
      }
      None => ()
    }
  }

  // Render beam as polygon (parallelogram for angled beams)
  let (first_top, first_bottom, last_top, last_bottom) = if stem_up {
    (
      first_beam_y,
      first_beam_y + BEAM_THICKNESS,
      last_beam_y,
      last_beam_y + BEAM_THICKNESS,
    )
  } else {
    (
      first_beam_y - BEAM_THICKNESS,
      first_beam_y,
      last_beam_y - BEAM_THICKNESS,
      last_beam_y,
    )
  }
  let points = "\{first_x},\{first_top} \{last_x},\{last_top} \{last_x},\{last_bottom} \{first_x},\{first_bottom}"
  nodes.push(@luna_dom.svg_polygon(points~, stroke="none"))

  // Render triplet "3" label if all notes in the group are EighthTriplet
  // and the group has exactly 3 notes
  let is_triplet = group.length() == 3 &&
    group.iter().all(fn(idx) { positioned[idx].1.duration is EighthTriplet })
  if is_triplet {
    let center_x = (first_x + last_x) / 2.0
    let label_y = if stem_up {
      (first_beam_y + last_beam_y) / 2.0 - TRIPLET_LABEL_OFFSET
    } else {
      (first_beam_y + last_beam_y) / 2.0 + TRIPLET_LABEL_OFFSET
    }
    nodes.push(
      @luna_dom.svg_text(
        x=center_x.to_string(),
        y=label_y.to_string(),
        text_anchor="middle",
        font_size=TRIPLET_LABEL_FONT_SIZE,
        font_family="serif",
        attrs=[
          ("stroke", @luna_dom.Attr::AttrString("none")),
          ("font-style", @luna_dom.Attr::AttrString("italic")),
        ],
        [@luna_dom.text("3")],
      ),
    )
  }
  nodes
}

///|
/// Render rest symbols for rests within beam groups, adjusting position
/// so they don't overlap with the beam.
fn render_beam_group_rests(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  note_positions : Array[Double],
  staff_y : Double,
  stem_up : Bool,
  first_x : Double,
  last_x : Double,
  first_beam_y : Double,
  last_beam_y : Double,
) -> Array[@luna_dom.DomNode] {
  let nodes : Array[@luna_dom.DomNode] = []
  for idx in group {
    let (_, note) = positioned[idx]
    match note.midi {
      None => {
        let note_x = note_positions[idx]
        let beam_y_here = beam_y_at(
          note_x, first_x, last_x, first_beam_y, last_beam_y,
        )
        let default_rest_y = staff_y + STAFF_LINE_SPACING * 2.0
        // Adjust rest position to avoid overlapping with beam
        // Eighth rest extends ~18px above rest_y, so stem_up needs extra clearance
        let rest_y = if stem_up {
          // Beam is above: ensure rest is below beam (accounting for rest top extent)
          @cmp.maximum(
            default_rest_y,
            beam_y_here +
            BEAM_THICKNESS +
            STAFF_LINE_SPACING +
            BEAM_REST_CLEARANCE,
          )
        } else {
          // Beam is below: ensure rest is above beam (accounting for rest bottom extent)
          @cmp.minimum(
            default_rest_y,
            beam_y_here -
            BEAM_THICKNESS -
            STAFF_LINE_SPACING -
            BEAM_REST_CLEARANCE,
          )
        }
        nodes.push(render_rest_symbol(note.duration, note_x, rest_y))
      }
      Some(_) => ()
    }
  }
  nodes
}

///|
/// Render all beam groups for a measure
fn render_beams(
  beam_groups : Array[Array[Int]],
  positioned : Array[(Double, @music.MeasureNote)],
  note_positions : Array[Double],
  staff_y : Double,
  key : @music.KeySignature,
) -> Array[@luna_dom.DomNode] {
  beam_groups
  .iter()
  .flat_map(fn(group) {
    let stem_up = beam_stem_up(group, positioned)
    let (first_beam_y, last_beam_y) = beam_endpoints(
      group, positioned, staff_y, key, stem_up,
    )

    // Find first_x and last_x for rest clearance interpolation
    let mut first_x = 0.0
    let mut last_x = 0.0
    let mut found_first = false
    for idx in group {
      let (_, note) = positioned[idx]
      match note.midi {
        Some(_) => {
          let note_x = note_positions[idx]
          let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
          let cos_25 = COS_NOTE_HEAD_ROTATION
          let stem_x_offset = if stem_up { rx * cos_25 } else { -(rx * cos_25) }
          let stem_x = note_x + stem_x_offset
          if not(found_first) {
            first_x = stem_x
            found_first = true
          }
          last_x = stem_x
        }
        None => ()
      }
    }
    [
      ..render_beam_group(
        group, positioned, note_positions, staff_y, key, stem_up, first_beam_y, last_beam_y,
      ),
      ..render_beam_group_rests(
        group, positioned, note_positions, staff_y, stem_up, first_x, last_x, first_beam_y,
        last_beam_y,
      ),
    ].iter()
  })
  .collect()
}
