///|
const NOTE_DISPLAY_WINDOW_MS = 3000.0

///|
const NOTE_DISPLAY_BG_COLOR = "#0f172a"

///|
const NOTE_PLAYING_COLOR = "#3b82f6"

///|
const NOTE_DEFAULT_COLOR = "#60a5fa"

///|
const NOTE_BORDER_COLOR = "#1e293b"

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

    // Determine color based on playing state
    let is_playing = current_pos >= note.start_ms &&
      current_pos < note.start_ms + note.duration_ms
    ctx.fillStyle = if is_playing {
      NOTE_PLAYING_COLOR
    } else {
      NOTE_DEFAULT_COLOR
    }
    ctx.fillRect(
      key_area.rect.left,
      top_y,
      key_area.rect.width,
      bottom_y - top_y,
    )

    // Draw border to distinguish consecutive notes
    ctx.strokeStyle = NOTE_BORDER_COLOR
    ctx.lineWidth = 1.0
    ctx.strokeRect(
      key_area.rect.left,
      top_y,
      key_area.rect.width,
      bottom_y - top_y,
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
) -> Unit {
  let measure_ms = @music.ms_per_measure(bpm)
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
/// Orchestrator: draw all note display elements
fn draw_notes(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  note_positions : Array[NotePosition],
  current_pos : Double,
  bpm : Int,
) -> Unit {
  draw_notes_background(ctx, width, height)
  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, KEYBOARD_MIN_KEY, KEYBOARD_MAX_KEY)
  draw_falling_notes(ctx, height, note_positions, current_pos, key_areas)
  draw_key_grid_lines(ctx, height, key_areas)
  draw_measure_lines(ctx, width, height, current_pos, bpm)
}
