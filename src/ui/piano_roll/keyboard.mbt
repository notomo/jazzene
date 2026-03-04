///|
const WHITE_KEY_COLOR = "#ffffff"

///|
const BLACK_KEY_COLOR = "#1f2937"

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
  sounds : () -> Array[@music.ScheduledSound],
  backing_sounds : () -> Array[@music.ScheduledSound],
  measures : () -> Array[@music.Measure],
  bpm : @signals.Signal[Int],
  playback_position : @signals.Signal[@music.Duration],
  show_legend : () -> Bool,
) -> @luna_dom.DomNode {
  let { canvas, ctx } = create_canvas_context()
  let resize_trigger = create_resize_trigger(canvas)

  let chord_labels = @signals.memo(fn() {
    compute_chord_labels(measures(), bpm.get())
  })

  // Calculate currently playing notes with technique-based colors (MIDI index → color)
  let playing_notes = @signals.memo(fn() {
    let set : Array[String?] = Array::make(128, None)
    @music.calculate_playing_notes(sounds(), playback_position.get()).each(fn(
      s,
    ) {
      match s.midi() {
        Some(m) =>
          set[m.value] = Some(
            match s.tone_origin {
              Some(origin) =>
                if show_legend() {
                  @theme.tone_origin_playing_color(origin)
                } else {
                  @theme.PLAYING_COLOR_CHORD_TONE
                }
              None => NOTE_PLAYING_COLOR
            },
          )
        None => ()
      }
    })
    set
  })

  // Calculate currently playing backing notes as a boolean lookup array (O(1) key lookup)
  let backing_playing_notes = @signals.memo(fn() {
    let set = Array::make(128, false)
    @music.calculate_playing_notes(backing_sounds(), playback_position.get())
    .filter_map(fn(s) { s.midi() })
    .each(fn(m) { set[m.value] = true })
    set
  })

  // Redraw when playing notes or canvas size change
  let _ = @signals.effect(fn() {
    let _ = resize_trigger.get()
    let (width, height) = update_canvas_dpi(canvas, ctx)
    let current_pos = playback_position.get().to_milliseconds()
    let current_chord = chord_labels()
      .iter()
      .filter(fn(l) { l.start_ms <= current_pos && current_pos < l.end_ms })
      .map(fn(l) { @music.format_chord(l.chord) })
      .next()
    draw_keyboard(
      ctx,
      width,
      height,
      playing_notes(),
      backing_playing_notes(),
      current_chord,
    )
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
  playing_notes : Array[String?],
  backing_playing_notes : Array[Bool],
  current_chord : String?,
) -> Unit {
  ctx.clearRect(0.0, 0.0, width, height)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, width, height)

  let label_width = calc_label_width(width)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, label_width, height)
  ctx.strokeStyle = MEASURE_LINE_COLOR
  ctx.lineWidth = 1.0
  ctx.strokeRect(0.5, 0.5, label_width - 1.0, height - 1.0)
  match current_chord {
    Some(chord_text) if height >= 20.0 => {
      ctx.save()
      ctx.translate(label_width / 2.0, height / 2.0)
      ctx.rotate(-1.5707963267948966)
      ctx.font = "bold 16px sans-serif"
      ctx.fillStyle = "#ffffff"
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      ctx.fillText(chord_text, 0.0, 0.0, max_width=height - 8.0)
      ctx.restore()
    }
    _ => ()
  }
  let rect = { left: label_width, top: 0.0, width: width - label_width, height }
  let key_areas = calc_key_areas(rect, KEYBOARD_MIN_KEY, KEYBOARD_MAX_KEY)

  // Draw white keys first (background layer)
  key_areas
  .iter()
  .filter(fn(a) { not(a.is_black) })
  .each(fn(area) {
    ctx.fillStyle = match
      (playing_notes[area.midi], backing_playing_notes[area.midi]) {
      (Some(color), _) => color
      (None, true) => WHITE_KEY_BACKING_COLOR
      (None, false) => WHITE_KEY_COLOR
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
    ctx.fillStyle = match
      (playing_notes[area.midi], backing_playing_notes[area.midi]) {
      (Some(color), _) => color
      (None, true) => BLACK_KEY_BACKING_COLOR
      (None, false) => BLACK_KEY_COLOR
    }
    ctx.fillRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      height * BLACK_KEY_HEIGHT_RATIO,
    )
  })
}
