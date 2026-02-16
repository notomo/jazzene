///|
const ACCIDENTAL_X_OFFSET_RATIO = 1.2

///|
const HOLLOW_NOTE_SCALE_DIVISOR = 50.0

///|
const FLAG_SCALE_DIVISOR = 32.0

///|
const NOTE_HEAD_ROTATION = -25.0

///|
/// Render accidental symbol to the left of the note
fn render_note_accidental(
  accidental : @music.Accidental?,
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode? {
  accidental.map(fn(acc) {
    let accidental_x = note_x -
      @music.STAFF_LINE_SPACING * ACCIDENTAL_X_OFFSET_RATIO
    render_accidental(acc, accidental_x, note_y)
  })
}

///|
/// Render filled note head (for quarter and eighth notes)
fn render_filled_note_head(
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode {
  let rx = @music.STAFF_LINE_SPACING * @music.NOTE_HEAD_RX_RATIO
  let ry = @music.STAFF_LINE_SPACING * @music.NOTE_HEAD_RY_RATIO
  @luna_dom.svg_ellipse(
    cx=note_x.to_string(),
    cy=note_y.to_string(),
    rx=rx.to_string(),
    ry=ry.to_string(),
    stroke="none",
    attrs=[("transform", Rotate(NOTE_HEAD_ROTATION, note_x, note_y).to_attr())],
  )
}

///|
/// Render hollow note head (for half and whole notes)
fn render_hollow_note_head(
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode {
  let scale = @music.STAFF_LINE_SPACING / HOLLOW_NOTE_SCALE_DIVISOR
  @luna_dom.svg_path(
    d="m 11.9799,-28.044092 a 25.42448,37.894733 65 0 0 -22.724708,5.001244 25.42448,37.894733 65 0 0 -23.599593,39.057558 25.42448,37.894733 65 0 0 45.089241,7.02748 25.42448,37.894733 65 0 0 23.59959,-39.05756 25.42448,37.894733 65 0 0 -22.36453,-12.028722 z m -11.9801455354,5.461682 a 16.280342,22.582411 0 0 1 16.2806555354,22.58208337714 16.280342,22.582411 0 0 1 -16.2806555354,22.58259662286 16.280342,22.582411 0 0 1 -16.2801434646,-22.58259662286 16.280342,22.582411 0 0 1 16.2801434646,-22.58208337714 z",
    stroke="none",
    attrs=[("transform", scale_translate(scale, note_x, note_y))],
  )
}

///|
/// Render note head based on duration
fn render_note_head(
  duration : @music.NoteDuration,
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode {
  match duration {
    Eighth | DottedEighth | Quarter | DottedQuarter | EighthTriplet =>
      render_filled_note_head(note_x, note_y)
    Half | DottedHalf | Whole => render_hollow_note_head(note_x, note_y)
  }
}

///|
/// Calculate stem position from SheetNote data
fn calculate_stem(
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> (Double, Double, Double) {
  let stem_height = @music.STAFF_LINE_SPACING * @music.STEM_HEIGHT_SPACES
  let x_off = if stem_up {
    @music.STAFF_LINE_SPACING *
    @music.NOTE_HEAD_RX_RATIO *
    @music.COS_NOTE_HEAD_ROTATION
  } else {
    -(@music.STAFF_LINE_SPACING *
    @music.NOTE_HEAD_RX_RATIO *
    @music.COS_NOTE_HEAD_ROTATION)
  }
  let y_off = if stem_up {
    -(@music.STAFF_LINE_SPACING *
    @music.NOTE_HEAD_RX_RATIO *
    @music.SIN_NOTE_HEAD_ROTATION)
  } else {
    @music.STAFF_LINE_SPACING *
    @music.NOTE_HEAD_RX_RATIO *
    @music.SIN_NOTE_HEAD_ROTATION
  }
  let stem_x = note_x + x_off
  let y1 = note_y + y_off
  let y2 = if stem_up { y1 - stem_height } else { y1 + stem_height }
  (stem_x, y1, y2)
}

///|
/// Render stem line
fn render_stem_line(
  stem_x : Double,
  y1 : Double,
  y2 : Double,
) -> @luna_dom.DomNode {
  @luna_dom.svg_line(
    x1=stem_x.to_string(),
    y1=y1.to_string(),
    x2=stem_x.to_string(),
    y2=y2.to_string(),
    stroke_width="1.5",
  )
}

///|
/// Render flag for eighth notes
fn render_flag(
  stem_x : Double,
  stem_y2 : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  let scale = @music.STAFF_LINE_SPACING / FLAG_SCALE_DIVISOR
  @luna_dom.svg_path(
    d="m 0.1322915,0.20079656 v 29.17519544 c 0,0 0.94525,1.04738 2.86031,2.860314 2.96256,2.804577 11.7267205,11.463111 16.3037905,16.875851 4.32124,5.11019 8.60276,12.11629 9.13525,19.19871 0.53655,7.13637 -1.14271,16.58785 -4.70907,26.52439 -1.9313,5.380953 -3.62376,8.222963 -3.06452,8.587383 0.79714,0.51945 2.7385,-2.97941 6.4668,-10.625733 6.32003,-12.96167 7.43952,-25.40692 6.55264,-34.62269 -1.15046,-11.95469 -2.28519,-23.402003 -9.94627,-35.007151 -6.79549,-10.293932 -14.7193405,-17.7092604 -19.5333005,-20.7143534 -2.59687,-1.62108305 -4.06563,-2.25191604 -4.06563,-2.25191604 z",
    stroke="none",
    attrs=[
      (
        "transform",
        if stem_up {
          scale_translate(scale, stem_x, stem_y2)
        } else {
          compose([
            ScaleXY(scale, -scale),
            Translate(stem_x / scale, -stem_y2 / scale),
          ])
        },
      ),
    ],
  )
}

///|
/// Render stem and optional flag based on duration (for non-beamed notes)
fn render_stem_and_flag(
  duration : @music.NoteDuration,
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> Array[@luna_dom.DomNode] {
  match duration {
    Whole => []
    Eighth | DottedEighth | EighthTriplet => {
      let (stem_x, y1, y2) = calculate_stem(note_x, note_y, stem_up)
      [render_stem_line(stem_x, y1, y2), render_flag(stem_x, y2, stem_up)]
    }
    Quarter | DottedQuarter | Half | DottedHalf => {
      let (stem_x, y1, y2) = calculate_stem(note_x, note_y, stem_up)
      [render_stem_line(stem_x, y1, y2)]
    }
  }
}

///|
/// Render a note from pre-computed SheetNote data
fn render_note_from_sheet(note : @music.SheetNote) -> Array[@luna_dom.DomNode] {
  let note_x = note.x
  let note_y = note.y
  [
    ..render_note_accidental(note.accidental, note_x, note_y),
    ..render_ledger_lines_from_sheet(note),
    render_note_head(note.duration, note_x, note_y),
    ..if note.beamed {
      []
    } else {
      render_stem_and_flag(note.duration, note_x, note_y, note.stem_up)
    },
    ..render_duration_dot(note.duration, note_x, note_y, on_line=note.on_line),
  ]
}

///|
/// Render a rest from pre-computed SheetNote data
fn render_rest_from_sheet(note : @music.SheetNote) -> Array[@luna_dom.DomNode] {
  render_rest_symbol_with_dot(note.duration, note.x, note.y)
}
