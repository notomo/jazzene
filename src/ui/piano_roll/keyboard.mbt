///|
const WHITE_KEY_COLOR = "#ffffff"

///|
const BLACK_KEY_COLOR = "#1f2937"

///|
const WHITE_KEY_PLAYING_COLOR = "#60a5fa"

///|
const BLACK_KEY_PLAYING_COLOR = "#3b82f6"

///|
const WHITE_KEY_BACKING_COLOR = "#9ca3af"

///|
const BLACK_KEY_BACKING_COLOR = "#6b7280"

///|
const KEY_BORDER_COLOR = "#d1d5db"

///|
const BLACK_KEY_HEIGHT_RATIO = 0.6

///|
/// Render piano keyboard component using Canvas API
pub fn keyboard(
  sounds : () -> Array[@music.NoteValueSound],
  backing_sounds : () -> Array[@music.NoteValueSound],
  playback_position : @signals.Signal[@music.Duration],
) -> @luna_dom.DomNode {
  let { canvas, ctx } = create_canvas_context()
  let resize_trigger = create_resize_trigger(canvas)

  // Calculate currently playing notes
  let playing_notes = @signals.memo(fn() {
    @music.calculate_playing_notes(sounds(), playback_position.get())
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  })

  // Calculate currently playing backing notes
  let backing_playing_notes = @signals.memo(fn() {
    @music.calculate_playing_notes(backing_sounds(), playback_position.get())
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  })

  // Redraw when playing notes or canvas size change
  let _ = @signals.effect(fn() {
    let _ = resize_trigger.get()
    let (width, height) = update_canvas_dpi(canvas, ctx)
    draw_keyboard(ctx, width, height, playing_notes(), backing_playing_notes())
  })
  @luna_dom.div(
    class="w-full h-[15%] min-h-10 shrink",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("keyboard canvas"))],
    [canvas_to_dom_node(canvas)],
  )
}

///|
/// Draw keyboard on canvas
fn draw_keyboard(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  playing_notes : Array[Int],
  backing_playing_notes : Array[Int],
) -> Unit {
  ctx.clearRect(0.0, 0.0, width, height)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, width, height)

  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, KEYBOARD_MIN_KEY, KEYBOARD_MAX_KEY)

  // Draw white keys first (background layer)
  key_areas
  .iter()
  .filter(fn(a) { not(a.is_black) })
  .each(fn(area) {
    let is_playing = playing_notes.contains(area.midi)
    let is_backing = backing_playing_notes.contains(area.midi)
    ctx.fillStyle = if is_playing {
      WHITE_KEY_PLAYING_COLOR
    } else if is_backing {
      WHITE_KEY_BACKING_COLOR
    } else {
      WHITE_KEY_COLOR
    }
    ctx.fillRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      area.rect.height,
    )
    ctx.strokeStyle = KEY_BORDER_COLOR
    ctx.strokeRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      area.rect.height,
    )
  })

  // Draw black keys on top (foreground layer)
  key_areas
  .iter()
  .filter(fn(a) { a.is_black })
  .each(fn(area) {
    let is_playing = playing_notes.contains(area.midi)
    let is_backing = backing_playing_notes.contains(area.midi)
    ctx.fillStyle = if is_playing {
      BLACK_KEY_PLAYING_COLOR
    } else if is_backing {
      BLACK_KEY_BACKING_COLOR
    } else {
      BLACK_KEY_COLOR
    }
    ctx.fillRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      height * BLACK_KEY_HEIGHT_RATIO,
    )
  })
}
