///|
/// Measure assembly - combines all musical notation elements

///|
const MEASURE_CLICKABLE_TOP_OFFSET = -80.0

///|
/// Render clickable background for seeking
fn render_clickable_background(
  x : Double,
  y : Double,
  measure_number : Int,
  measure : @music.Measure,
  playback_position : @signals.Signal[@music.Duration],
) -> @luna_dom.DomNode {
  @luna_dom.svg_rect(
    x=x.to_string(),
    y=(y + MEASURE_CLICKABLE_TOP_OFFSET).to_string(),
    width=@music.MEASURE_WIDTH.to_string(),
    height=@music.ROW_HEIGHT.to_string(),
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
  let extra_width = @music.CLEF_SPACE_WIDTH +
    @music.key_signature_layout_width(key)
  match is_first_in_row {
    true =>
      render_staff_lines(
        x - extra_width,
        y,
        width=@music.MEASURE_WIDTH + extra_width,
      )
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
  let extra_width = @music.CLEF_SPACE_WIDTH +
    @music.key_signature_layout_width(key)
  match is_first_in_row {
    true => Some(render_treble_clef(x - extra_width, y))
    false => None
  }
}

///|
/// Render a single note or rest from pre-computed SheetNote data
fn render_sheet_note(note : @music.SheetNote) -> Array[@luna_dom.DomNode] {
  if note.is_rest {
    // Rests in beam groups are rendered by beam code
    if note.beamed {
      return []
    }
    return render_rest_from_sheet(note)
  }
  [..render_note_from_sheet(note), ..render_tie_arcs_from_sheet(note.tie_arcs)]
}

///|
/// Render all notes, beams, and ottava from pre-computed SheetMeasure data
fn render_measure_notes(
  measure : @music.Measure,
  x : Double,
  y : Double,
  key : @music.KeySignature,
  time_signature : @music.TimeSignature,
  display_index : Int,
) -> Array[@luna_dom.DomNode] {
  let sheet = @music.compute_sheet_measure(
    measure, display_index, key, time_signature,
  )

  let note_nodes : Array[@luna_dom.DomNode] = sheet.notes
    .iter()
    .flat_map(fn(note) { render_sheet_note(note).iter() })
    .collect()

  let beam_nodes = render_beams_from_sheet(sheet.beam_groups)
  let ottava_nodes = match sheet.ottava {
    OttavaAlta => render_8va_marking(x, y, @music.MEASURE_WIDTH)
    OttavaBassa => render_8vb_marking(x, y, @music.MEASURE_WIDTH)
    OttavaNone => []
  }
  [..note_nodes, ..beam_nodes, ..ottava_nodes]
}

///|
/// Render a single measure with all its elements
fn render_measure(
  measure : @music.Measure,
  display_index : Int,
  playback_position : @signals.Signal[@music.Duration],
  key : @music.KeySignature,
  time_signature : @music.TimeSignature,
  is_outside_loop : () -> Bool,
) -> @luna_dom.DomNode {
  let (x, y) = @music.measure_position(display_index, key)
  let is_first_in_row = display_index % @music.MEASURES_PER_ROW == 0
  let is_first_measure = display_index == 0
  let measure_number = display_index + 1

  @luna_dom.svg_g(
    [
      render_measure_staff_lines(x, y, is_first_in_row, key),
      ..render_measure_clef(x, y, is_first_in_row, key),
      ..render_measure_key_signature(key, x, y, is_first_in_row),
      ..render_measure_time_signature(time_signature, x, y, is_first_measure),
      ..render_chord_symbol(measure, x, y),
      ..render_measure_notes(measure, x, y, key, time_signature, display_index),
      render_bar_line(x + @music.MEASURE_WIDTH, y),
      render_clickable_background(
        x, y, measure_number, measure, playback_position,
      ),
      @luna_dom.show(is_outside_loop, fn() {
        @luna_dom.svg_rect(
          x=x.to_string(),
          y=(y + MEASURE_CLICKABLE_TOP_OFFSET).to_string(),
          width=@music.MEASURE_WIDTH.to_string(),
          height=@music.ROW_HEIGHT.to_string(),
          fill="rgba(0,0,0,0.5)",
          stroke="none",
          attrs=[("pointer-events", @luna_dom.Attr::AttrString("none"))],
        )
      }),
    ],
  )
}
