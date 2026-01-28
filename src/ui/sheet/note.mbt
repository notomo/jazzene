///|
let accidental_x_offset_ratio = 1.2

///|
let hollow_note_scale_divisor = 50.0

///|
let stem_height_spaces = 3.0

///|
let flag_scale_divisor = 32.0

///|
/// Render accidental symbol to the left of the note
fn render_note_accidental(
  accidental : @music.Accidental?,
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode? {
  accidental.map(fn(acc) {
    let accidental_x = note_x - staff_line_spacing * accidental_x_offset_ratio
    render_accidental(acc, accidental_x, note_y)
  })
}

///|
/// Render filled note head (for quarter and eighth notes)
fn render_filled_note_head(
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode {
  let rx = staff_line_spacing * note_head_rx_ratio
  let ry = staff_line_spacing * note_head_ry_ratio
  let transform = "rotate(\{note_head_rotation}, \{note_x}, \{note_y})"
  @luna_dom.svg_ellipse(
    cx=note_x.to_string(),
    cy=note_y.to_string(),
    rx=rx.to_string(),
    ry=ry.to_string(),
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform))],
  )
}

///|
/// Render hollow note head (for half and whole notes)
fn render_hollow_note_head(
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / hollow_note_scale_divisor
  let transform_str = "scale(\{scale}) translate(\{note_x / scale} \{note_y / scale})"
  @luna_dom.svg_path(
    d="m 11.9799,-28.044092 a 25.42448,37.894733 65 0 0 -22.724708,5.001244 25.42448,37.894733 65 0 0 -23.599593,39.057558 25.42448,37.894733 65 0 0 45.089241,7.02748 25.42448,37.894733 65 0 0 23.59959,-39.05756 25.42448,37.894733 65 0 0 -22.36453,-12.028722 z m -11.9801455354,5.461682 a 16.280342,22.582411 0 0 1 16.2806555354,22.58208337714 16.280342,22.582411 0 0 1 -16.2806555354,22.58259662286 16.280342,22.582411 0 0 1 -16.2801434646,-22.58259662286 16.280342,22.582411 0 0 1 16.2801434646,-22.58208337714 z",
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
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
    Eighth | DottedEighth | Quarter | DottedQuarter =>
      render_filled_note_head(note_x, note_y)
    Half | DottedHalf | Whole => render_hollow_note_head(note_x, note_y)
  }
}

///|
/// Stem direction and position information
priv struct StemInfo {
  x : Double
  y1 : Double
  y2 : Double
  up : Bool
}

///|
/// Calculate stem position and direction
fn calculate_stem_info(
  midi : Int,
  note_x : Double,
  note_y : Double,
) -> StemInfo {
  let stem_height = staff_line_spacing * stem_height_spaces
  let stem_up = midi < stem_direction_midi_threshold
  let rx = staff_line_spacing * note_head_rx_ratio
  let cos_25 = cos_note_head_rotation
  let sin_25 = sin_note_head_rotation
  let (stem_x_offset, stem_y_offset) = if stem_up {
    (rx * cos_25, -(rx * sin_25))
  } else {
    (-(rx * cos_25), rx * sin_25)
  }
  let y1 = note_y + stem_y_offset
  {
    x: note_x + stem_x_offset,
    y1,
    y2: if stem_up {
      y1 - stem_height
    } else {
      y1 + stem_height
    },
    up: stem_up,
  }
}

///|
/// Render stem line
fn render_stem(stem : StemInfo) -> @luna_dom.DomNode {
  @luna_dom.svg_line(
    x1=stem.x.to_string(),
    y1=stem.y1.to_string(),
    x2=stem.x.to_string(),
    y2=stem.y2.to_string(),
    stroke=color_foreground,
    stroke_width="1.5",
  )
}

///|
/// Render flag for eighth notes
fn render_flag(stem : StemInfo) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / flag_scale_divisor
  let flag_transform = if stem.up {
    "scale(\{scale}) translate(\{stem.x / scale} \{stem.y2 / scale})"
  } else {
    "scale(\{scale} \{-scale}) translate(\{stem.x / scale} \{-stem.y2 / scale})"
  }
  @luna_dom.svg_path(
    d="m 0.1322915,0.20079656 v 29.17519544 c 0,0 0.94525,1.04738 2.86031,2.860314 2.96256,2.804577 11.7267205,11.463111 16.3037905,16.875851 4.32124,5.11019 8.60276,12.11629 9.13525,19.19871 0.53655,7.13637 -1.14271,16.58785 -4.70907,26.52439 -1.9313,5.380953 -3.62376,8.222963 -3.06452,8.587383 0.79714,0.51945 2.7385,-2.97941 6.4668,-10.625733 6.32003,-12.96167 7.43952,-25.40692 6.55264,-34.62269 -1.15046,-11.95469 -2.28519,-23.402003 -9.94627,-35.007151 -6.79549,-10.293932 -14.7193405,-17.7092604 -19.5333005,-20.7143534 -2.59687,-1.62108305 -4.06563,-2.25191604 -4.06563,-2.25191604 z",
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(flag_transform))],
  )
}

///|
/// Render stem and optional flag based on duration
fn render_stem_and_flag(
  duration : @music.NoteDuration,
  midi : Int,
  note_x : Double,
  note_y : Double,
) -> Array[@luna_dom.DomNode] {
  match duration {
    Whole => []
    Eighth | DottedEighth => {
      let stem = calculate_stem_info(midi, note_x, note_y)
      [render_stem(stem), render_flag(stem)]
    }
    Quarter | DottedQuarter | Half | DottedHalf => {
      let stem = calculate_stem_info(midi, note_x, note_y)
      [render_stem(stem)]
    }
  }
}

///|
/// Render duration dot for dotted notes
fn render_duration_dot(
  duration : @music.NoteDuration,
  note_x : Double,
  note_y : Double,
) -> @luna_dom.DomNode? {
  match duration {
    DottedEighth | DottedQuarter | DottedHalf => {
      let dot_radius = staff_line_spacing * dot_radius_ratio
      let dot_x = note_x + staff_line_spacing * dot_x_offset_ratio
      Some(
        @luna_dom.svg_circle(
          cx=dot_x.to_string(),
          cy=note_y.to_string(),
          r=dot_radius.to_string(),
          fill=color_foreground,
        ),
      )
    }
    _ => None
  }
}

///|
/// Render a single note with all its elements
fn render_note(
  note : @music.MeasureNote,
  note_x : Double,
  staff_y : Double,
) -> Array[@luna_dom.DomNode] {
  match note.midi {
    Some(midi) => {
      let note_y = midi_to_staff_y(midi, staff_y)
      let accidental = render_note_accidental(note.accidental, note_x, note_y)
      let ledger_lines = render_ledger_lines(midi, note_x, staff_y)
      let note_head = render_note_head(note.duration, note_x, note_y)
      let stem_and_flag = render_stem_and_flag(
        note.duration,
        midi,
        note_x,
        note_y,
      )
      let duration_dot = render_duration_dot(note.duration, note_x, note_y)
      let accidental_nodes : Array[_] = match accidental {
        Some(n) => [n]
        None => []
      }
      let dot_nodes : Array[_] = match duration_dot {
        Some(n) => [n]
        None => []
      }
      [accidental_nodes, ledger_lines, [note_head], stem_and_flag, dot_nodes].flatten()
    }
    None => []
  }
}
