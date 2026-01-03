///|
/// Render piano keyboard component using Canvas API
pub fn render_keyboard_canvas(
  note_values : @signal.Signal[Array[@music.NoteValue]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  let canvas_elem = @js_dom.document().createElement("canvas")
  let canvas = cast_to_canvas(canvas_elem)
  set_canvas_style_width(canvas, "100%")
  set_canvas_style_height(canvas, "100%")
  let ctx = get_context_2d(canvas)

  // Calculate currently playing notes
  let playing_notes = @signal.memo(fn() {
    let pos = match mode.get() {
      Stopped(position_ms=p) => p
      Playing(position_ms=p) => p
    }
    let note_value_list = note_values.get()
    let tempo_val = tempo.get()
    let mut current_pos = 0
    let active_midi_notes : Array[Int] = []
    for note_value in note_value_list {
      let duration_ms = note_value.duration().to_ms(tempo_val)
      let start_ms = current_pos
      let end_ms = current_pos + duration_ms

      // Check if note is currently playing (rests never highlight keys)
      match note_value {
        Note(midi=midi_val, ..) =>
          if pos >= start_ms && pos < end_ms {
            active_midi_notes.push(midi_val.value)
          }
        Rest(..) => () // Rests don't highlight any keys
      }
      current_pos = current_pos + duration_ms
    }
    active_midi_notes
  })

  // Redraw when playing notes change
  let _ = @signal.effect(fn() {
    let active_notes = playing_notes()

    // Update canvas width to match displayed width
    let client_width = canvas.clientWidth()
    if client_width > 0 {
      canvas.width = client_width
    }
    draw_keyboard(
      ctx,
      canvas.width.to_double(),
      canvas.height.to_double(),
      active_notes,
    )
  })

  // Convert canvas to DomNode using ToDomNode trait
  let canvas_dom_node = @luna_dom.ToDomNode::to_dom_node(canvas.as_node())

  // Wrap in div with aria-label for E2E tests
  @luna_dom.div(
    class="w-full",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("keyboard canvas"))],
    [canvas_dom_node],
  )
}

///|
/// Draw keyboard on canvas
fn draw_keyboard(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  playing_notes : Array[Int],
) -> Unit {
  // Clear canvas
  ctx.clearRect(0.0, 0.0, width, height)

  // Background
  ctx.fillStyle = "#0f172a"
  ctx.fillRect(0.0, 0.0, width, height)
  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, 36, 96)

  // Draw white keys first (background layer)
  for area in key_areas {
    if not(area.is_black) {
      let is_playing = playing_notes.contains(area.midi)
      ctx.fillStyle = if is_playing { "#60a5fa" } else { "#ffffff" }
      ctx.fillRect(
        area.rect.left,
        area.rect.top,
        area.rect.width,
        area.rect.height,
      )

      // Border
      ctx.strokeStyle = "#d1d5db"
      ctx.strokeRect(
        area.rect.left,
        area.rect.top,
        area.rect.width,
        area.rect.height,
      )
    }
  }

  // Draw black keys on top (foreground layer)
  for area in key_areas {
    if area.is_black {
      let is_playing = playing_notes.contains(area.midi)
      ctx.fillStyle = if is_playing { "#3b82f6" } else { "#1f2937" }
      let black_key_height = height * 0.6
      ctx.fillRect(
        area.rect.left,
        area.rect.top,
        area.rect.width,
        black_key_height,
      )
    }
  }
}
