///|
/// Sheet music layout computation
/// Converts music data into pre-computed layout data for rendering.

///|
/// Ottava marking state for a measure
pub(all) enum OttavaMarking {
  OttavaNone
  OttavaAlta
  OttavaBassa
} derive(Eq, Show)

///|
/// Pre-computed tie arc layout data
pub(all) struct SheetTieArc {
  start_x : Double
  end_x : Double
  note_y : Double
  stem_up : Bool
} derive(Show)

///|
/// Pre-computed note layout data
pub(all) struct SheetNote {
  x : Double
  y : Double
  duration : NoteDuration
  accidental : Accidental?
  tie : Tie?
  is_rest : Bool
  stem_up : Bool
  beamed : Bool
  diatonic_step : Int
  on_line : Bool
  tie_arcs : Array[SheetTieArc]
  midi : Int?
} derive(Show)

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
  duration : NoteDuration
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
/// Pre-computed measure layout data
pub(all) struct SheetMeasure {
  x : Double
  y : Double
  width : Double
  notes : Array[SheetNote]
  beam_groups : Array[SheetBeamGroup]
  ottava : OttavaMarking
  is_first_in_row : Bool
} derive(Show)

// --- Staff position functions ---

///|
/// Calculate diatonic steps from E4 (bottom line of treble clef)
fn midi_to_diatonic_step(midi : Int, key : KeySignature) -> Int {
  let pitch_class = midi % 12
  let octave = midi / 12 - 1
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = key.pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = key.pitch_class_to_diatonic_step(e4_pitch_class)
  (octave - e4_octave) * 7 + (note_diatonic_step - e4_diatonic_step)
}

///|
/// Convert MIDI number to Y position on staff
pub fn midi_to_staff_y(
  midi : Int,
  staff_y : Double,
  key : KeySignature,
) -> Double {
  let total_diatonic_steps = midi_to_diatonic_step(midi, key)
  let offset = total_diatonic_steps.to_double() * -(STAFF_LINE_SPACING / 2.0)
  staff_y + STAFF_LINE_SPACING * (STAFF_LINES - 1).to_double() + offset
}

///|
/// Generate ledger line steps for notes below the staff
pub fn ledger_steps_below(step : Int) -> Array[Int] {
  if step >= 0 {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (FIRST_LEDGER_LINE_BELOW_STEP - end_step) / 2 + 1
  Array::makei(count, fn(i) { FIRST_LEDGER_LINE_BELOW_STEP - i * 2 })
}

///|
/// Generate ledger line steps for notes above the staff
pub fn ledger_steps_above(step : Int) -> Array[Int] {
  if step <= UPPER_LEDGER_LINE_THRESHOLD {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (end_step - FIRST_LEDGER_LINE_ABOVE_STEP) / 2 + 1
  Array::makei(count, fn(i) { FIRST_LEDGER_LINE_ABOVE_STEP + i * 2 })
}

// --- Ottava functions ---

///|
/// Returns true if any pitched note in the measure has MIDI >= threshold
fn should_apply_8va(positioned : Array[(Double, MeasureNote)]) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => midi >= OTTAVA_ALTA_THRESHOLD_MIDI
      None => false
    }
  })
}

///|
/// Returns true if any pitched note needs >= threshold ledger lines below the staff
fn should_apply_8vb(
  positioned : Array[(Double, MeasureNote)],
  key : KeySignature,
) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => {
        let step = midi_to_diatonic_step(midi, key)
        ledger_steps_below(step).length() >= OTTAVA_BASSA_LEDGER_LINE_THRESHOLD
      }
      None => false
    }
  })
}

///|
/// Creates a copy with all MIDI values shifted down by OTTAVA_SHIFT
fn shift_for_8va(
  positioned : Array[(Double, MeasureNote)],
) -> Array[(Double, MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m - OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}

///|
/// Creates a copy with all MIDI values shifted up by OTTAVA_SHIFT
fn shift_for_8vb(
  positioned : Array[(Double, MeasureNote)],
) -> Array[(Double, MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m + OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}

// --- Measure position ---

///|
/// Calculate the width of the key signature rendering area
pub fn key_signature_layout_width(key : KeySignature) -> Double {
  let count = key.altered_steps.length()
  if count == 0 {
    0.0
  } else {
    count.to_double() * KEY_SIG_SYMBOL_SPACING + 5.0
  }
}

///|
/// Calculate measure position in the layout grid
pub fn measure_position(
  measure_index : Int,
  key : KeySignature,
) -> (Double, Double) {
  let col = measure_index % MEASURES_PER_ROW
  let row = measure_index / MEASURES_PER_ROW
  let clef_offset = CLEF_SPACE_WIDTH + key_signature_layout_width(key)
  let x = MEASURE_START_X + clef_offset + col.to_double() * MEASURE_WIDTH
  let y = STAFF_TOP + row.to_double() * ROW_HEIGHT
  (x, y)
}

// --- Note spacing ---

///|
/// Visual weight for duration-proportional spacing
fn duration_visual_weight(duration : NoteDuration) -> Double {
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
/// Calculate minimum spacing between note at index i and its predecessor.
fn note_min_spacing(
  i : Int,
  positioned : Array[(Double, MeasureNote)],
  beamed_indices : Map[Int, Bool],
) -> Double {
  let (_, note) = positioned[i]
  let (_, prev_note) = positioned[i - 1]
  let prev_has_flag = if beamed_indices.contains(i - 1) {
    false
  } else {
    match prev_note.duration {
      Eighth | DottedEighth | EighthTriplet => true
      _ => false
    }
  }
  let has_accidental_space = note.accidental is Some(_) &&
    not(beamed_indices.contains(i))
  MIN_NOTE_SPACING +
  (if prev_has_flag { FLAGGED_EIGHTH_EXTRA_SPACING } else { 0.0 }) +
  (if has_accidental_space { ACCIDENTAL_EXTRA_SPACING } else { 0.0 })
}

///|
/// Compute x positions for all notes in a measure
fn compute_note_positions(
  positioned : Array[(Double, MeasureNote)],
  measure_x : Double,
  beamed_indices : Map[Int, Bool],
) -> Array[Double] {
  let n = positioned.length()
  if n == 0 {
    return []
  }
  let note_area_start = measure_x + NOTE_AREA_START_OFFSET
  let note_area_width = MEASURE_WIDTH - NOTE_AREA_PADDING
  let cumulative_weights : Array[Double] = Array::make(n, 0.0)
  let mut total_weight = 0.0
  for i = 0; i < n; i = i + 1 {
    cumulative_weights[i] = total_weight
    total_weight = total_weight +
      duration_visual_weight(positioned[i].1.duration)
  }
  let positions : Array[Double] = []
  for i, pair in positioned {
    let (_, note) = pair
    let proportional_x = match (note.midi, note.duration) {
      (None, Whole) => measure_x + MEASURE_WIDTH / 2.0
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
  compress_overflow(
    positions,
    positioned,
    beamed_indices,
    note_area_start + note_area_width,
  )
  positions
}

///|
/// Compress positions that overflow the available area
fn compress_overflow(
  positions : Array[Double],
  positioned : Array[(Double, MeasureNote)],
  beamed_indices : Map[Int, Bool],
  right_edge : Double,
) -> Unit {
  let n = positions.length()
  guard n > 1 && positions[n - 1] > right_edge else { return }
  let first_pos = positions[0]
  let available_span = right_edge - first_pos
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

// --- Beam geometry ---

///|
/// Determine stem direction for a beam group.
fn beam_stem_up(
  group : Array[Int],
  positioned : Array[(Double, MeasureNote)],
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
  positioned : Array[(Double, MeasureNote)],
  staff_y : Double,
  key : KeySignature,
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

// --- Stem x/y helpers ---

///|
/// Calculate stem x offset from note center
fn stem_x_offset(stem_up : Bool) -> Double {
  let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
  if stem_up {
    rx * COS_NOTE_HEAD_ROTATION
  } else {
    -(rx * COS_NOTE_HEAD_ROTATION)
  }
}

///|
/// Calculate stem y offset from note center
fn stem_y_offset(stem_up : Bool) -> Double {
  let rx = STAFF_LINE_SPACING * NOTE_HEAD_RX_RATIO
  if stem_up {
    -(rx * SIN_NOTE_HEAD_ROTATION)
  } else {
    rx * SIN_NOTE_HEAD_ROTATION
  }
}

// --- Beam group layout computation ---

///|
/// Find first_x and last_x for a beam group (stem x positions of first/last pitched notes)
fn find_beam_x_range(
  group : Array[Int],
  positioned : Array[(Double, MeasureNote)],
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
  positioned : Array[(Double, MeasureNote)],
  note_positions : Array[Double],
  staff_y : Double,
  key : KeySignature,
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

// --- Tie arc layout ---

///|
fn compute_tie_arcs(
  tie : Tie?,
  note_x : Double,
  midi : Int,
  staff_y : Double,
  measure_x : Double,
  key : KeySignature,
  prev_note_x : Double?,
  next_note_x : Double?,
) -> Array[SheetTieArc] {
  let note_y = midi_to_staff_y(midi, staff_y, key)
  let stem_up = midi < STEM_DIRECTION_MIDI_THRESHOLD
  let measure_start_x = measure_x
  let measure_end_x = measure_x + MEASURE_WIDTH
  match tie {
    Some(TieStart) => {
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [SheetTieArc::{ start_x: note_x, end_x, note_y, stem_up }]
    }
    Some(TieEnd) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      [SheetTieArc::{ start_x, end_x: note_x, note_y, stem_up }]
    }
    Some(TieBoth) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [
        SheetTieArc::{ start_x, end_x: note_x, note_y, stem_up },
        SheetTieArc::{ start_x: note_x, end_x, note_y, stem_up },
      ]
    }
    None => []
  }
}

// --- Main API ---

///|
/// Compute complete layout data for a measure
pub fn compute_sheet_measure(
  measure : Measure,
  measure_index : Int,
  key : KeySignature,
  time_signature : TimeSignature,
) -> SheetMeasure {
  let (x, y) = measure_position(measure_index, key)
  let is_first_in_row = measure_index % MEASURES_PER_ROW == 0

  // Get positioned notes and apply ottava
  let positioned = measure.positioned_notes()
  let apply_8va = should_apply_8va(positioned)
  let apply_8vb = not(apply_8va) && should_apply_8vb(positioned, key)
  let ottava = if apply_8va {
    OttavaAlta
  } else if apply_8vb {
    OttavaBassa
  } else {
    OttavaNone
  }
  let display = match ottava {
    OttavaAlta => shift_for_8va(positioned)
    OttavaBassa => shift_for_8vb(positioned)
    OttavaNone => positioned
  }

  // Beam grouping
  let beam_groups_indices = find_beam_groups(display, time_signature)
  let beamed_indices : Map[Int, Bool] = {}
  beam_groups_indices.each(fn(group) {
    group.each(fn(idx) { beamed_indices[idx] = true })
  })

  // Note x positions
  let note_positions = compute_note_positions(display, x, beamed_indices)

  // Build SheetNote array
  let notes : Array[SheetNote] = display
    .iter()
    .mapi(fn(i, pair) {
      let (_, note) = pair
      let note_x = note_positions[i]
      let is_beamed = beamed_indices.contains(i)
      let is_rest = note.midi is None
      let (note_y, stem_up, diatonic_step, on_line) = match note.midi {
        Some(midi) => {
          let ny = midi_to_staff_y(midi, y, key)
          let step = midi_to_diatonic_step(midi, key)
          (ny, midi < STEM_DIRECTION_MIDI_THRESHOLD, step, step % 2 == 0)
        }
        None => (y + STAFF_LINE_SPACING * 2.0, true, 0, false)
      }
      // Tie arcs
      let prev_note_x : Double? = match note.tie {
        Some(TieEnd | TieBoth) =>
          if i > 0 {
            Some(note_positions[i - 1])
          } else {
            None
          }
        _ => None
      }
      let next_note_x : Double? = match note.tie {
        Some(TieStart | TieBoth) =>
          if i + 1 < display.length() {
            Some(note_positions[i + 1])
          } else {
            None
          }
        _ => None
      }
      let tie_arcs = match note.midi {
        Some(midi) =>
          compute_tie_arcs(
            note.tie,
            note_x,
            midi,
            y,
            x,
            key,
            prev_note_x,
            next_note_x,
          )
        None => []
      }
      SheetNote::{
        x: note_x,
        y: note_y,
        duration: note.duration,
        accidental: note.accidental,
        tie: note.tie,
        is_rest,
        stem_up,
        beamed: is_beamed,
        diatonic_step,
        on_line,
        tie_arcs,
        midi: note.midi,
      }
    })
    .collect()

  // Build SheetBeamGroup array
  let beam_groups = beam_groups_indices.map(fn(group) {
    compute_beam_group(group, display, note_positions, y, key)
  })

  SheetMeasure::{
    x,
    y,
    width: MEASURE_WIDTH,
    notes,
    beam_groups,
    ottava,
    is_first_in_row,
  }
}
