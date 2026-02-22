///|
/// Compute the unified measure width needed across all measures
pub fn compute_unified_measure_width(
  measures : Array[@music.Measure],
  time_signature : @music.TimeSignature,
) -> Double {
  let max_ideal = measures
    .iter()
    .fold(init=0.0, fn(acc, measure) {
      let positioned = measure.positioned_notes()
      let beam_groups_indices = @music.find_beam_groups(
        positioned, time_signature,
      )
      let beamed_indices : Map[Int, Bool] = {}
      beam_groups_indices.each(fn(group) {
        group.each(fn(idx) { beamed_indices[idx] = true })
      })
      @cmp.maximum(acc, compute_ideal_measure_width(positioned, beamed_indices))
    })
  @cmp.maximum(MIN_MEASURE_WIDTH, max_ideal)
}

///|
/// Compute complete layout data for a measure
pub fn compute_sheet_measure(
  measure : @music.Measure,
  measure_index : Int,
  key : @music.KeySignature,
  time_signature : @music.TimeSignature,
  measure_width? : Double = MIN_MEASURE_WIDTH,
) -> SheetMeasure {
  let (x, y) = measure_position(measure_index, key, measure_width~)
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
  let beam_groups_indices = @music.find_beam_groups(display, time_signature)
  let beamed_indices : Map[Int, Bool] = {}
  beam_groups_indices.each(fn(group) {
    group.each(fn(idx) { beamed_indices[idx] = true })
  })

  // Note x positions
  let note_positions = compute_note_positions(
    display,
    x,
    beamed_indices,
    measure_width~,
  )

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
            measure_width~,
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
        tone_origin: note.tone_origin,
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
    width: measure_width,
    notes,
    beam_groups,
    ottava,
    is_first_in_row,
  }
}
