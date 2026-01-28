///|
/// Measure assembly - combines all musical notation elements

///|
let staff_top = 120.0

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
let measure_clickable_top_offset = -80.0

///|
let note_area_start_offset = 60.0

///|
let note_area_padding = 80.0

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
    y=(y + measure_clickable_top_offset).to_string(),
    width=measure_width.to_string(),
    height=row_height.to_string(),
    fill="transparent",
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
) -> @luna_dom.DomNode {
  if is_first_in_row {
    render_staff_lines(
      x - clef_space_width,
      y,
      width=measure_width + clef_space_width,
    )
  } else {
    render_staff_lines(x, y)
  }
}

///|
/// Render treble clef for first measure in row
fn render_measure_clef(
  x : Double,
  y : Double,
  is_first_in_row : Bool,
) -> @luna_dom.DomNode? {
  if is_first_in_row {
    Some(render_treble_clef(x - clef_space_width, y))
  } else {
    None
  }
}

///|
/// Calculate note x position within measure
fn note_x_position(measure_x : Double, start_beat : Double) -> Double {
  measure_x +
  note_area_start_offset +
  start_beat * (measure_width - note_area_padding) / 4.0
}

///|
/// Render a single note or rest with ties
fn render_note_or_rest(
  note : @music.MeasureNote,
  note_x : Double,
  y : Double,
  measure_x : Double,
) -> Array[@luna_dom.DomNode] {
  match note.midi {
    Some(midi) => {
      let note_nodes = render_note(note, note_x, y)
      let tie_nodes = render_tie_arcs(note.tie, note_x, midi, y, measure_x)
      [note_nodes, tie_nodes].flatten()
    }
    None => render_rest(note, note_x, y)
  }
}

///|
/// Render all notes and rests in a measure
fn render_measure_notes(
  measure : @music.Measure,
  x : Double,
  y : Double,
) -> Array[@luna_dom.DomNode] {
  measure.notes
  .iter()
  .flat_map(fn(note) {
    let note_x = note_x_position(x, note.start_beat)
    render_note_or_rest(note, note_x, y, x).iter()
  })
  .collect()
}

///|
/// Render a single measure with all its elements
fn render_measure(
  measure : @music.Measure,
  display_index : Int,
  playback_position : @signal.Signal[@music.Duration],
) -> @luna_dom.DomNode {
  let (x, y) = measure_position(display_index)
  let is_first_in_row = display_index % measures_per_row == 0
  let measure_number = display_index + 1
  let clef_nodes = match render_measure_clef(x, y, is_first_in_row) {
    Some(n) => [n]
    None => []
  }
  @luna_dom.svg_g(
    [
      [render_measure_staff_lines(x, y, is_first_in_row)],
      clef_nodes,
      render_chord_symbol(measure, x, y),
      render_measure_notes(measure, x, y),
      [render_bar_line(x + measure_width, y)],
      [
        render_clickable_background(
          x, y, measure_number, measure, playback_position,
        ),
      ],
    ].flatten(),
  )
}
