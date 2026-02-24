///|
const NOTE_DISPLAY_WINDOW_MS = 3000.0

///|
const NOTE_DISPLAY_BG_COLOR = "#0f172a"

///|
const NOTE_PLAYING_COLOR = "#3b82f6"

///|
const NOTE_DEFAULT_COLOR = "#60a5fa"

///|
const BACKING_PLAYING_COLOR = "#6b7280"

///|
const BACKING_DEFAULT_COLOR = "#9ca3af"

///|
/// Gap in pixels between consecutive notes to visually separate them
const NOTE_GAP_PX = 2.0

///|
const OCTAVE_LINE_COLOR = "rgba(255, 255, 255, 0.4)"

///|
const KEY_LINE_COLOR = "rgba(255, 255, 255, 0.15)"

///|
const MEASURE_LINE_COLOR = "rgba(255, 255, 255, 0.3)"

///|
priv struct NotePosition {
  midi : Int
  start_ms : Double
  duration_ms : Double
  tone_origin : @music.ToneOrigin?
}

///|
/// A time-segmented region showing which pitch classes are in the chord scale
priv struct ScaleBand {
  start_ms : Double
  end_ms : Double
  scale_pitch_classes : Array[Int] // 0-11 pitch classes in scale
}

///|
/// Compute scale bands from measures (one band per measure chord)
fn compute_scale_bands(
  measures : Array[@music.Measure],
  bpm : Int,
) -> Array[ScaleBand] {
  let beat_duration_ms = @music.ms_per_beat(bpm)
  measures
  .iter()
  .flat_map(fn(measure) {
    let measure_start_ms = measure.start_time.to_milliseconds()
    let n_chords = measure.chords.length()
    if n_chords == 0 {
      return [].iter()
    }
    // Estimate beats per measure from note count or use 4.0 as default
    // Assign equal chord slots within the measure
    // Use the measure notes to determine total beats
    let total_beats = measure.beats.length().to_double()
    let beats_per_chord = if n_chords > 0 {
      total_beats / n_chords.to_double()
    } else {
      total_beats
    }
    measure.chords
    .iter()
    .mapi(fn(i, chord) {
      let chord_start_ms = measure_start_ms +
        i.to_double() * beats_per_chord * beat_duration_ms
      let chord_end_ms = measure_start_ms +
        (i + 1).to_double() * beats_per_chord * beat_duration_ms
      let chord_scale = chord.quality.chord_scale()
      let root_pc = chord.root.midi() % 12
      let scale_pcs = chord_scale
        .intervals()
        .map(fn(interval) { (root_pc + interval) % 12 })
      ScaleBand::{
        start_ms: chord_start_ms,
        end_ms: chord_end_ms,
        scale_pitch_classes: scale_pcs,
      }
    })
  })
  .collect()
}

///|
/// Draw approach tone arrows: small chevrons on approach/enclosure notes
/// indicating the resolution direction toward the next note
fn draw_approach_arrows(
  ctx : @canvas.CanvasRenderingContext2D,
  height : Double,
  note_positions : Array[NotePosition],
  current_pos : Double,
  key_areas : Array[KeyArea],
) -> Unit {
  let n = note_positions.length()
  for i = 0; i < n - 1; i = i + 1 {
    let note = note_positions[i]
    let is_approach = match note.tone_origin {
      Some(ApproachTone | Enclosure) => true
      _ => false
    }
    if not(is_approach) {
      continue
    }
    let start_offset = note.start_ms - current_pos
    if start_offset > NOTE_DISPLAY_WINDOW_MS ||
      note.start_ms + note.duration_ms < current_pos {
      continue
    }
    let next_note = note_positions[i + 1]
    let direction_up = next_note.midi > note.midi
    let key_index = note.midi - KEYBOARD_MIN_KEY
    if key_index < 0 || key_index >= key_areas.length() {
      continue
    }
    let area = key_areas[key_index]
    let bottom_percent = 100.0 - start_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let end_offset = note.start_ms + note.duration_ms - current_pos
    let top_percent = 100.0 - end_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let bottom_y = height * bottom_percent / 100.0
    let top_y = height * top_percent / 100.0
    let note_width = area.rect.width
    let note_height = bottom_y - top_y

    // Scale arrow to fit inside note dimensions
    let max_by_width = note_width * 0.8
    let max_by_height = note_height * 0.4
    let max_size = if max_by_width < max_by_height {
      max_by_width
    } else {
      max_by_height
    }
    let arrow_size = if max_size < 10.0 { max_size } else { 10.0 }
    if arrow_size < 2.0 {
      continue
    }
    let center_x = area.rect.left + note_width / 2.0
    let arrow_padding = 2.0

    // Draw a horizontal triangle at the top edge of the note, inside it
    ctx.fillStyle = "#ffffff"
    ctx.beginPath()
    let arrow_mid_y = top_y + arrow_padding + arrow_size / 2.0
    if direction_up {
      // ▶ pointing right (toward higher pitch)
      let base_x = center_x - arrow_size / 2.0
      let tip_x = center_x + arrow_size / 2.0
      ctx.moveTo(base_x, arrow_mid_y - arrow_size / 2.0)
      ctx.lineTo(base_x, arrow_mid_y + arrow_size / 2.0)
      ctx.lineTo(tip_x, arrow_mid_y)
    } else {
      // ◀ pointing left (toward lower pitch)
      let base_x = center_x + arrow_size / 2.0
      let tip_x = center_x - arrow_size / 2.0
      ctx.moveTo(base_x, arrow_mid_y - arrow_size / 2.0)
      ctx.lineTo(base_x, arrow_mid_y + arrow_size / 2.0)
      ctx.lineTo(tip_x, arrow_mid_y)
    }
    ctx.closePath()
    ctx.fill()
  }
}

///|
/// Draw scale band overlays: dim non-scale keys in the background
fn draw_scale_bands(
  ctx : @canvas.CanvasRenderingContext2D,
  height : Double,
  scale_bands : Array[ScaleBand],
  current_pos : Double,
  key_areas : Array[KeyArea],
) -> Unit {
  scale_bands
  .iter()
  .filter(fn(band) {
    let end_offset = band.end_ms - current_pos
    let start_offset = band.start_ms - current_pos
    end_offset >= 0.0 && start_offset <= NOTE_DISPLAY_WINDOW_MS
  })
  .each(fn(band) {
    let start_offset = band.start_ms - current_pos
    let end_offset = band.end_ms - current_pos
    let bottom_percent = 100.0 - start_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let top_percent = 100.0 - end_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let bottom_y = height * bottom_percent / 100.0
    let top_y = height * top_percent / 100.0
    let band_height = bottom_y - top_y

    // Highlight scale tones with a subtle glow
    key_areas
    .iter()
    .filter(fn(area) {
      let pc = area.midi % 12
      band.scale_pitch_classes.iter().any(fn(scale_pc) { scale_pc == pc })
    })
    .each(fn(area) {
      ctx.fillStyle = "rgba(255, 255, 255, 0.06)"
      ctx.fillRect(area.rect.left, top_y, area.rect.width, band_height)
    })
  })
}

///|
/// Draw the note display background
fn draw_notes_background(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
) -> Unit {
  ctx.clearRect(0.0, 0.0, width, height)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, width, height)
}

///|
/// Draw falling note rectangles
fn draw_falling_notes(
  ctx : @canvas.CanvasRenderingContext2D,
  height : Double,
  note_positions : Array[NotePosition],
  current_pos : Double,
  key_areas : Array[KeyArea],
  playing_color : String,
  default_color : String,
) -> Unit {
  note_positions
  .iter()
  .filter(fn(note) {
    let end_offset = note.start_ms + note.duration_ms - current_pos
    let start_offset = note.start_ms - current_pos
    let key_index = note.midi - KEYBOARD_MIN_KEY
    end_offset >= 0.0 &&
    start_offset <= NOTE_DISPLAY_WINDOW_MS &&
    key_index >= 0 &&
    key_index < key_areas.length()
  })
  .each(fn(note) {
    let start_offset = note.start_ms - current_pos
    let end_offset = note.start_ms + note.duration_ms - current_pos
    let key_area = key_areas[note.midi - KEYBOARD_MIN_KEY]

    // Calculate vertical position (inverted: future at top, now at bottom)
    let bottom_percent = 100.0 - start_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let top_percent = 100.0 - end_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let bottom_y = height * bottom_percent / 100.0
    let top_y = height * top_percent / 100.0

    // Determine color: use technique color when available, fall back to defaults
    let is_playing = current_pos >= note.start_ms &&
      current_pos < note.start_ms + note.duration_ms
    ctx.fillStyle = match (note.tone_origin, is_playing) {
      (Some(origin), true) => @theme.tone_origin_playing_color(origin)
      (Some(origin), false) => @theme.tone_origin_color(origin)
      (None, true) => playing_color
      (None, false) => default_color
    }
    // Add gap at bottom to separate consecutive same-pitch notes
    let note_height = bottom_y - top_y
    let gap = if note_height > NOTE_GAP_PX * 2.0 { NOTE_GAP_PX } else { 0.0 }
    ctx.fillRect(
      key_area.rect.left,
      top_y,
      key_area.rect.width,
      note_height - gap,
    )
  })
}

///|
/// Draw vertical grid lines aligned to white keys
fn draw_key_grid_lines(
  ctx : @canvas.CanvasRenderingContext2D,
  height : Double,
  key_areas : Array[KeyArea],
) -> Unit {
  key_areas
  .iter()
  .filter(fn(a) { not(a.is_black) })
  .each(fn(area) {
    ctx.fillStyle = match area.midi % 12 {
      0 => OCTAVE_LINE_COLOR
      _ => KEY_LINE_COLOR
    }
    ctx.fillRect(area.rect.left, 0.0, 1.0, height)
  })
}

///|
/// Draw horizontal measure lines
fn draw_measure_lines(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  current_pos : Double,
  bpm : Int,
  beats_per_measure : Double,
) -> Unit {
  let measure_ms = @music.ms_per_measure(bpm, beats_per_measure~)
  let first_measure = (current_pos / measure_ms).to_int()
  let last_measure = ((current_pos + NOTE_DISPLAY_WINDOW_MS) / measure_ms).to_int() +
    1

  for i = first_measure; i <= last_measure; i = i + 1 {
    let measure_pos_ms = i.to_double() * measure_ms
    let offset = measure_pos_ms - current_pos
    if offset >= 0.0 && offset <= NOTE_DISPLAY_WINDOW_MS {
      let percent = 100.0 - offset / NOTE_DISPLAY_WINDOW_MS * 100.0
      let y = height * percent / 100.0
      ctx.fillStyle = MEASURE_LINE_COLOR
      ctx.fillRect(0.0, y, width, 1.0)
    }
  }
}

///|
/// Draw semi-transparent overlay for time regions outside the loop range
fn draw_loop_overlay(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  current_pos : Double,
  bpm : Int,
  beats_per_measure : Double,
  loop_a_measure : Int,
  loop_b_measure : Int,
) -> Unit {
  let measure_ms = @music.ms_per_measure(bpm, beats_per_measure~)
  let loop_start_ms = (loop_a_measure - 1).to_double() * measure_ms
  let loop_end_ms = loop_b_measure.to_double() * measure_ms
  ctx.fillStyle = "rgba(0,0,0,0.5)"

  // Overlay for region before loop start
  let before_offset = loop_start_ms - current_pos
  if before_offset > 0.0 && before_offset < NOTE_DISPLAY_WINDOW_MS {
    let percent = 100.0 - before_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let y = height * percent / 100.0
    ctx.fillRect(0.0, y, width, height - y)
  } else if current_pos < loop_start_ms {
    // Entire visible window is before loop start
    ctx.fillRect(0.0, 0.0, width, height)
  }

  // Overlay for region after loop end
  let after_offset = loop_end_ms - current_pos
  if after_offset >= 0.0 && after_offset < NOTE_DISPLAY_WINDOW_MS {
    let percent = 100.0 - after_offset / NOTE_DISPLAY_WINDOW_MS * 100.0
    let y = height * percent / 100.0
    ctx.fillRect(0.0, 0.0, width, y)
  } else if current_pos >= loop_end_ms {
    // Entire visible window is after loop end
    ctx.fillRect(0.0, 0.0, width, height)
  }
}

///|
/// Orchestrator: draw all note display elements
fn draw_notes(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  note_positions : Array[NotePosition],
  backing_positions : Array[NotePosition],
  scale_bands : Array[ScaleBand],
  current_pos : Double,
  bpm : Int,
  beats_per_measure : Double,
  loop_a_measure : Int,
  loop_b_measure : Int,
) -> Unit {
  draw_notes_background(ctx, width, height)
  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, KEYBOARD_MIN_KEY, KEYBOARD_MAX_KEY)
  draw_scale_bands(ctx, height, scale_bands, current_pos, key_areas)
  draw_falling_notes(
    ctx,
    height,
    backing_positions,
    current_pos,
    key_areas,
    BACKING_PLAYING_COLOR,
    BACKING_DEFAULT_COLOR,
  )
  draw_falling_notes(
    ctx,
    height,
    note_positions,
    current_pos,
    key_areas,
    NOTE_PLAYING_COLOR,
    NOTE_DEFAULT_COLOR,
  )
  draw_approach_arrows(ctx, height, note_positions, current_pos, key_areas)
  draw_key_grid_lines(ctx, height, key_areas)
  draw_measure_lines(ctx, width, height, current_pos, bpm, beats_per_measure)
  draw_loop_overlay(
    ctx, width, height, current_pos, bpm, beats_per_measure, loop_a_measure, loop_b_measure,
  )
}
