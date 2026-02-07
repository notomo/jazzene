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
const NOTE_AREA_PADDING = 80.0

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
/// Calculate note x position within measure
fn note_x_position(
  measure_x : Double,
  start_beat : Double,
  beats_per_measure : Double,
) -> Double {
  measure_x +
  NOTE_AREA_START_OFFSET +
  start_beat * (MEASURE_WIDTH - NOTE_AREA_PADDING) / beats_per_measure
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
  let beam_groups = @music.find_beam_groups(positioned, time_signature)
  let beamed_indices : Map[Int, Bool] = {}
  beam_groups.each(fn(group) {
    group.each(fn(idx) { beamed_indices[idx] = true })
  })
  let note_nodes : Array[@luna_dom.DomNode] = positioned
    .iter()
    .mapi(fn(i, pair) {
      let (start_beat, note) = pair
      let note_x = match (note.midi, note.duration) {
        (None, Whole) => x + MEASURE_WIDTH / 2.0
        _ => note_x_position(x, start_beat, beats_per_measure)
      }
      let is_beamed = beamed_indices.contains(i)
      // Skip rests that are in beam groups (they are rendered by beam code)
      match (is_beamed, note.midi) {
        (true, None) => Array::new().iter()
        _ => {
          let prev_note_x : Double? = match note.tie {
            Some(@music.TieEnd | @music.TieBoth) =>
              if i > 0 {
                let (prev_beat, _) = positioned[i - 1]
                Some(note_x_position(x, prev_beat, beats_per_measure))
              } else {
                None
              }
            _ => None
          }
          let next_note_x : Double? = match note.tie {
            Some(@music.TieStart | @music.TieBoth) =>
              if i + 1 < positioned.length() {
                let (next_beat, _) = positioned[i + 1]
                Some(note_x_position(x, next_beat, beats_per_measure))
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
  let beam_nodes = render_beams(
    beam_groups, positioned, x, y, key, beats_per_measure,
  )
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
