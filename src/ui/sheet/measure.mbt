///|
/// Measure assembly - combines all musical notation elements

///|
const STAFF_TOP = 120.0

///|
const MEASURES_PER_ROW = 4

///|
const MEASURE_WIDTH = 320.0

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
const NOTE_AREA_START_OFFSET = 40.0

///|
const NOTE_AREA_PADDING = 75.0

///|
const MIN_NOTE_SPACING = 32.0

///|
const FLAGGED_EIGHTH_EXTRA_SPACING = 15.0

///|
const ACCIDENTAL_EXTRA_SPACING = 14.0

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
/// Calculate minimum spacing between note at index i and its predecessor.
fn note_min_spacing(
  i : Int,
  positioned : Array[(Double, @music.MeasureNote)],
  beamed_indices : Map[Int, Bool],
) -> Double {
  let (_, note) = positioned[i]
  let (_, prev_note) = positioned[i - 1]
  // An eighth note has a flag only when not beamed
  let prev_has_flag = if beamed_indices.contains(i - 1) {
    false
  } else {
    match prev_note.duration {
      Eighth | DottedEighth | EighthTriplet => true
      _ => false
    }
  }
  // Skip accidental extra spacing for beamed notes (accidental fits within beam spacing)
  let has_accidental_space = note.accidental is Some(_) &&
    not(beamed_indices.contains(i))
  MIN_NOTE_SPACING +
  (if prev_has_flag { FLAGGED_EIGHTH_EXTRA_SPACING } else { 0.0 }) +
  (if has_accidental_space { ACCIDENTAL_EXTRA_SPACING } else { 0.0 })
}

///|
/// Compute x positions for all notes in a measure, enforcing minimum spacing
/// to prevent overlapping note heads for shorter durations.
fn duration_visual_weight(duration : @music.NoteDuration) -> Double {
  // Precomputed beats^0.585 (log2(1.5)) — gives ~1.5x space when duration doubles
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
  // Build cumulative visual weights for duration-proportional spacing
  let cumulative_weights : Array[Double] = Array::make(n, 0.0)
  let mut total_weight = 0.0
  for i = 0; i < n; i = i + 1 {
    cumulative_weights[i] = total_weight
    total_weight = total_weight +
      duration_visual_weight(positioned[i].1.duration)
  }
  // Compute positions using visual weights with minimum spacing enforcement
  let positions : Array[Double] = []
  for i, pair in positioned {
    let (_, note) = pair
    let proportional_x = match (note.midi, note.duration) {
      (None, @music.Whole) => measure_x + MEASURE_WIDTH / 2.0
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

  // If rightmost position exceeds the available area, compress only the extra
  // space beyond minimum spacing so that accidental gaps are preserved.
  let right_edge = note_area_start + note_area_width
  if n > 1 && positions[n - 1] > right_edge {
    let first_pos = positions[0]
    let available_span = right_edge - first_pos
    // Collect minimum spacing and extra space for each gap
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
      // Compress only the extra space beyond minimums
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
      // Not enough space for all minimums: preserve critical gaps (flagged eighths),
      // compress flexible gaps proportionally to fill remaining space.
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
  time_signature : @music.TimeSignature,
) -> Array[@luna_dom.DomNode] {
  let positioned = measure.positioned_notes()
  let apply_8va = should_apply_8va(positioned)
  let display = if apply_8va {
    shift_for_ottava(positioned)
  } else {
    positioned
  }
  let beam_groups = @music.find_beam_groups(display, time_signature)
  let beamed_indices : Map[Int, Bool] = {}
  beam_groups.each(fn(group) {
    group.each(fn(idx) { beamed_indices[idx] = true })
  })

  let note_positions = compute_note_positions(display, x, beamed_indices)
  let note_nodes : Array[@luna_dom.DomNode] = display
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
              if i + 1 < display.length() {
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

  let beam_nodes = render_beams(beam_groups, display, note_positions, y, key)
  let ottava_nodes = if apply_8va {
    render_8va_marking(x, y, MEASURE_WIDTH)
  } else {
    []
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
      ..render_measure_notes(measure, x, y, key, time_signature),
      render_bar_line(x + MEASURE_WIDTH, y),
      render_clickable_background(
        x, y, measure_number, measure, playback_position,
      ),
      @luna_dom.show(is_outside_loop, fn() {
        @luna_dom.svg_rect(
          x=x.to_string(),
          y=(y + MEASURE_CLICKABLE_TOP_OFFSET).to_string(),
          width=MEASURE_WIDTH.to_string(),
          height=ROW_HEIGHT.to_string(),
          fill="rgba(0,0,0,0.5)",
          stroke="none",
          attrs=[("pointer-events", @luna_dom.Attr::AttrString("none"))],
        )
      }),
    ],
  )
}
