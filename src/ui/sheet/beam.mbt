///|
/// Beam rendering for connected eighth notes

///|
const BEAM_THICKNESS = 3.5

///|
const BEAM_REST_CLEARANCE = 8.0

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
/// Calculate the beam Y coordinate (horizontal beam).
/// Up: min(note_y) - stem_height, Down: max(note_y) + stem_height
fn beam_y_position(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  staff_y : Double,
  key : @music.KeySignature,
  stem_up : Bool,
) -> Double {
  let stem_height = STAFF_LINE_SPACING * STEM_HEIGHT_SPACES
  let mut min_y = 1.0e10
  let mut max_y = -1.0e10
  for idx in group {
    match positioned[idx].1.midi {
      Some(midi) => {
        let y = midi_to_staff_y(midi, staff_y, key)
        if y < min_y {
          min_y = y
        }
        if y > max_y {
          max_y = y
        }
      }
      None => ()
    }
  }
  if stem_up {
    min_y - stem_height
  } else {
    max_y + stem_height
  }
}

///|
/// Render a single beam group
fn render_beam_group(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  measure_x : Double,
  staff_y : Double,
  key : @music.KeySignature,
  beats_per_measure : Double,
) -> Array[@luna_dom.DomNode] {
  let stem_up = beam_stem_up(group, positioned)
  let beam_y = beam_y_position(group, positioned, staff_y, key, stem_up)
  let nodes : Array[@luna_dom.DomNode] = []
  let mut first_x = 0.0
  let mut last_x = 0.0
  // Render stems for non-rest notes and collect x positions
  for i, idx in group {
    let (start_beat, note) = positioned[idx]
    let note_x = note_x_position(measure_x, start_beat, beats_per_measure)
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
        nodes.push(
          @luna_dom.svg_line(
            x1=stem_x.to_string(),
            y1=stem_y1.to_string(),
            x2=stem_x.to_string(),
            y2=beam_y.to_string(),
            stroke_width="1.5",
          ),
        )
        if i == 0 {
          first_x = stem_x
        }
        last_x = stem_x
      }
      None => ()
    }
  }
  // Render beam rectangle
  let beam_rect_y = if stem_up { beam_y } else { beam_y - BEAM_THICKNESS }
  nodes.push(
    @luna_dom.svg_rect(
      x=first_x.to_string(),
      y=beam_rect_y.to_string(),
      width=(last_x - first_x).to_string(),
      height=BEAM_THICKNESS.to_string(),
      stroke="none",
    ),
  )
  nodes
}

///|
/// Render rest symbols for rests within beam groups, adjusting position
/// so they don't overlap with the beam.
fn render_beam_group_rests(
  group : Array[Int],
  positioned : Array[(Double, @music.MeasureNote)],
  measure_x : Double,
  staff_y : Double,
  beats_per_measure : Double,
  stem_up : Bool,
  beam_y : Double,
) -> Array[@luna_dom.DomNode] {
  let nodes : Array[@luna_dom.DomNode] = []
  for idx in group {
    let (start_beat, note) = positioned[idx]
    match note.midi {
      None => {
        let note_x = note_x_position(measure_x, start_beat, beats_per_measure)
        let default_rest_y = staff_y + STAFF_LINE_SPACING * 2.0
        // Adjust rest position to avoid overlapping with beam
        let rest_y = if stem_up {
          // Beam is above: ensure rest is below beam
          @cmp.maximum(default_rest_y, beam_y + BEAM_REST_CLEARANCE)
        } else {
          // Beam is below: ensure rest is above beam
          @cmp.minimum(
            default_rest_y,
            beam_y - BEAM_REST_CLEARANCE - STAFF_LINE_SPACING,
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
  measure_x : Double,
  staff_y : Double,
  key : @music.KeySignature,
  beats_per_measure : Double,
) -> Array[@luna_dom.DomNode] {
  beam_groups
  .iter()
  .flat_map(fn(group) {
    let stem_up = beam_stem_up(group, positioned)
    let beam_y = beam_y_position(group, positioned, staff_y, key, stem_up)
    [
      ..render_beam_group(
        group, positioned, measure_x, staff_y, key, beats_per_measure,
      ),
      ..render_beam_group_rests(
        group, positioned, measure_x, staff_y, beats_per_measure, stem_up, beam_y,
      ),
    ].iter()
  })
  .collect()
}
