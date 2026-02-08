///|
/// Measure assembly - combines all musical notation elements

///|
const STAFF_TOP = 120.0

///|
const MEASURES_PER_ROW = 4

///|
const MEASURE_WIDTH = 280.0

///|
const CLEF_SPACE_WIDTH = 50.0

///|
const MEASURE_START_X = 40.0

///|
const ROW_HEIGHT = 300.0

///|
/// Calculate measure position in the layout
/// First measure of each row is offset by clef_space_width for the treble clef
fn measure_position(
  measure_index : Int,
  key : @music.KeySignature,
) -> (Double, Double) {
  let col = measure_index % MEASURES_PER_ROW
  let row = measure_index / MEASURES_PER_ROW
  let clef_offset = CLEF_SPACE_WIDTH + key_signature_width(key)
  let x = MEASURE_START_X + clef_offset + col.to_double() * MEASURE_WIDTH
  let y = STAFF_TOP + row.to_double() * ROW_HEIGHT
  (x, y)
}

///|
const MEASURE_CLICKABLE_TOP_OFFSET = -80.0

///|
const NOTE_AREA_START_OFFSET = 60.0

///|
const NOTE_AREA_PADDING = 95.0

///|
const MIN_NOTE_SPACING = 32.0

///|
const ACCIDENTAL_EXTRA_SPACING = 14.0

///|
/// Render clickable background for seeking
fn render_clickable_background(
  x : Double,
  y : Double,
  measure_number : Int,
  measure : @music.Measure,
  playback_position : @signal.Signal[@music.Duration],
) -> @luna_dom.DomNode {
  @luna_dom.svg_rect(
    x=x.to_string(),
    y=(y + MEASURE_CLICKABLE_TOP_OFFSET).to_string(),
    width=MEASURE_WIDTH.to_string(),
    height=ROW_HEIGHT.to_string(),
    fill="transparent",
    stroke="none",
    style="cursor: pointer",
    attrs=[
      ("aria-label", @luna_dom.Attr::AttrString("measure \{measure_number}")),
      ("pointer-events", @luna_dom.Attr::AttrString("all")),
    ],
    on=@luna_dom.events().click(fn(_) {
      playback_position.set(measure.start_time)
    }),
  )
}

///|
/// Render staff lines with extended width for first measure in row
fn render_measure_staff_lines(
  x : Double,
  y : Double,
  is_first_in_row : Bool,
  key : @music.KeySignature,
) -> @luna_dom.DomNode {
  let extra_width = CLEF_SPACE_WIDTH + key_signature_width(key)
  match is_first_in_row {
    true =>
      render_staff_lines(x - extra_width, y, width=MEASURE_WIDTH + extra_width)
    false => render_staff_lines(x, y)
  }
}

///|
/// Render treble clef for first measure in row
fn render_measure_clef(
  x : Double,
  y : Double,
  is_first_in_row : Bool,
  key : @music.KeySignature,
) -> @luna_dom.DomNode? {
  let extra_width = CLEF_SPACE_WIDTH + key_signature_width(key)
  match is_first_in_row {
    true => Some(render_treble_clef(x - extra_width, y))
    false => None
  }
}

///|
/// Compute x positions for all notes in a measure, enforcing minimum spacing
/// to prevent overlapping note heads for shorter durations.
fn compute_note_positions(
  positioned : Array[(Double, @music.MeasureNote)],
  measure_x : Double,
  beats_per_measure : Double,
) -> Array[Double] {
  let n = positioned.length()
  if n == 0 {
    return []
  }
  let note_area_start = measure_x + NOTE_AREA_START_OFFSET
  let note_area_width = MEASURE_WIDTH - NOTE_AREA_PADDING
  // Compute beat-proportional positions with minimum spacing enforcement
  let positions : Array[Double] = []
  for i, pair in positioned {
    let (start_beat, note) = pair
    let proportional_x = match (note.midi, note.duration) {
      (None, @music.Whole) => measure_x + MEASURE_WIDTH / 2.0
      _ => note_area_start + start_beat * note_area_width / beats_per_measure
    }
    let min_spacing = match note.accidental {
      Some(_) => MIN_NOTE_SPACING + ACCIDENTAL_EXTRA_SPACING
      None => MIN_NOTE_SPACING
    }
    let x = if i == 0 {
      proportional_x
    } else {
      @cmp.maximum(proportional_x, positions[i - 1] + min_spacing)
    }
    positions.push(x)
  }
  // If rightmost position exceeds the available area, scale all positions to fit
  let right_edge = note_area_start + note_area_width
  if n > 1 && positions[n - 1] > right_edge {
    let first_pos = positions[0]
    let current_span = positions[n - 1] - first_pos
    if current_span > 0.0 {
      let available_span = right_edge - first_pos
      let scale = available_span / current_span
      for i, _ in positions {
        if i > 0 {
          positions[i] = first_pos + (positions[i] - first_pos) * scale
        }
      }
    }
  }
  positions
}

///|
/// Render a single note or rest with ties
fn render_note_or_rest(
  note : @music.MeasureNote,
  note_x : Double,
  y : Double,
  measure_x : Double,
  key : @music.KeySignature,
  prev_note_x? : Double? = None,
  next_note_x? : Double? = None,
  beamed? : Bool = false,
) -> Array[@luna_dom.DomNode] {
  match note.midi {
    Some(midi) =>
      [
        ..render_note(note, note_x, y, key, beamed~),
        ..render_tie_arcs(
          note.tie,
          note_x,
          midi,
          y,
          measure_x,
          key,
          prev_note_x~,
          next_note_x~,
        ),
      ]
    None => render_rest(note, note_x, y)
  }
}

///|
/// Render all notes and rests in a measure
fn render_measure_notes(
  measure : @music.Measure,
  x : Double,
  y : Double,
  key : @music.KeySignature,
  beats_per_measure : Double,
  time_signature : @music.TimeSignature,
) -> Array[@luna_dom.DomNode] {
  let positioned = measure.positioned_notes()
  let note_positions = compute_note_positions(positioned, x, beats_per_measure)
  let beam_groups = @music.find_beam_groups(positioned, time_signature)
  let beamed_indices : Map[Int, Bool] = {}
  beam_groups.each(fn(group) {
    group.each(fn(idx) { beamed_indices[idx] = true })
  })
  let note_nodes : Array[@luna_dom.DomNode] = positioned
    .iter()
    .mapi(fn(i, _pair) {
      let (_, note) = _pair
      let note_x = note_positions[i]
      let is_beamed = beamed_indices.contains(i)
      // Skip rests that are in beam groups (they are rendered by beam code)
      match (is_beamed, note.midi) {
        (true, None) => Array::new().iter()
        _ => {
          let prev_note_x : Double? = match note.tie {
            Some(@music.TieEnd | @music.TieBoth) =>
              if i > 0 {
                Some(note_positions[i - 1])
              } else {
                None
              }
            _ => None
          }
          let next_note_x : Double? = match note.tie {
            Some(@music.TieStart | @music.TieBoth) =>
              if i + 1 < positioned.length() {
                Some(note_positions[i + 1])
              } else {
                None
              }
            _ => None
          }
          render_note_or_rest(
            note,
            note_x,
            y,
            x,
            key,
            prev_note_x~,
            next_note_x~,
            beamed=is_beamed,
          ).iter()
        }
      }
    })
    .flatten()
    .collect()
  let beam_nodes = render_beams(beam_groups, positioned, note_positions, y, key)
  [..note_nodes, ..beam_nodes]
}

///|
/// Render a single measure with all its elements
fn render_measure(
  measure : @music.Measure,
  display_index : Int,
  playback_position : @signal.Signal[@music.Duration],
  key : @music.KeySignature,
  beats_per_measure : Double,
  time_signature : @music.TimeSignature,
) -> @luna_dom.DomNode {
  let (x, y) = measure_position(display_index, key)
  let is_first_in_row = display_index % MEASURES_PER_ROW == 0
  let is_first_measure = display_index == 0
  let measure_number = display_index + 1
  @luna_dom.svg_g(
    [
      render_measure_staff_lines(x, y, is_first_in_row, key),
      ..render_measure_clef(x, y, is_first_in_row, key),
      ..render_measure_key_signature(key, x, y, is_first_in_row),
      ..render_measure_time_signature(time_signature, x, y, is_first_measure),
      ..render_chord_symbol(measure, x, y),
      ..render_measure_notes(
        measure, x, y, key, beats_per_measure, time_signature,
      ),
      render_bar_line(x + MEASURE_WIDTH, y),
      render_clickable_background(
        x, y, measure_number, measure, playback_position,
      ),
    ],
  )
}
