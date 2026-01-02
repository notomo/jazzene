///|
fn cast_to_canvas_notes(elem : @js_dom.Element) -> @js_dom.HTMLCanvasElement = "%identity"

///|
extern "js" fn get_context_2d_notes(
  canvas : @js_dom.HTMLCanvasElement,
) -> @canvas.CanvasRenderingContext2D =
  #|(canvas) => canvas.getContext("2d")

///|
extern "js" fn set_canvas_style_width_notes(
  canvas : @js_dom.HTMLCanvasElement,
  width : String,
) -> Unit =
  #|(canvas, width) => { canvas.style.width = width; }

///|
extern "js" fn add_wheel_listener_notes(
  canvas : @js_dom.HTMLCanvasElement,
  handler : (@js_dom.WheelEvent) -> Unit,
) -> Unit =
  #|(canvas, handler) => { canvas.addEventListener('wheel', handler); }

///|
/// Render falling notes display component using Canvas API
pub fn render_falling_notes_canvas(
  note_values : @signal.Signal[Array[@music.NoteValue]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
  frame_count : @signal.Signal[Int],
  audio_ctx : @web_audio.AudioContext,
) -> @luna_dom.DomNode {
  // Create canvas element
  let canvas_elem = @js_dom.document().createElement("canvas")
  let canvas = cast_to_canvas_notes(canvas_elem)

  // Set canvas to fill width
  set_canvas_style_width_notes(canvas, "100%")
  canvas.height = 600

  // Get 2D context
  let ctx = get_context_2d_notes(canvas)

  // Calculate current playback position
  let position_ms = @signal.memo(fn() {
    let _ = frame_count.get()
    match mode.get() {
      Stopped(position_ms=pos) => pos
      Playing(started_at_ms=started_at, started_from_position=started_from, ..) => {
        let now_ms = @date.Date::now()
        started_from + (now_ms - started_at)
      }
    }
  })

  // Pre-calculate note positions (immutable list with start times)
  let note_positions = @signal.memo(fn() {
    let note_value_list = note_values.get()
    let tempo_val = tempo.get()
    let mut current_pos = 0
    let positions : Array[(Int, Int, Int)] = [] // (midi, start_ms, duration_ms)
    for note_value in note_value_list {
      let duration_ms = note_value.duration().to_ms(tempo_val)
      // Only track positions for actual notes (rests are invisible gaps)
      match note_value {
        Note(midi=midi_val, ..) =>
          positions.push((midi_val.value, current_pos, duration_ms))
        Rest(..) => () // Rests don't render but advance timing
      }
      current_pos = current_pos + duration_ms
    }
    positions
  })

  // Calculate total duration
  let total_duration_ms = @signal.memo(fn() {
    if note_values.get().length() > 0 {
      @audio.calculate_total_duration(note_values.get(), tempo.get())
    } else {
      0
    }
  })

  // Add wheel event listener for seeking
  let on_wheel : (@js_dom.WheelEvent) -> Unit = fn(e) {
    if note_values.get().length() == 0 {
      return
    }
    e.preventDefault()
    let current_pos = position_ms()
    let seek_amount = 500 // milliseconds per wheel tick
    let new_position_ms = if e.deltaY > 0.0 {
      // Wheel down: move forward
      current_pos + seek_amount
    } else {
      // Wheel up: move backward
      current_pos - seek_amount
    }
    // Clamp position to valid range
    let clamped_position = if new_position_ms < 0 {
      0
    } else if new_position_ms > total_duration_ms() {
      total_duration_ms()
    } else {
      new_position_ms
    }
    // Update mode
    match mode.get() {
      Stopped(..) => mode.set(PlaybackMode::stopped(clamped_position))
      Playing(..) => {
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        mode.set(PlaybackMode::playing(now_ms, clamped_position, audio_start))
      }
    }
  }
  add_wheel_listener_notes(canvas, on_wheel)

  // Redraw on frame count change
  let _ = @signal.effect(fn() {
    let _ = frame_count.get()
    let pos = position_ms()
    let positions = note_positions()

    // Update canvas width to match displayed width
    let client_width = canvas.clientWidth()
    if client_width > 0 {
      canvas.width = client_width
    }
    draw_notes(
      ctx,
      canvas.width.to_double(),
      canvas.height.to_double(),
      positions,
      pos,
    )
  })

  // Convert canvas to DomNode using ToDomNode trait
  let canvas_dom_node = @luna_dom.ToDomNode::to_dom_node(canvas.as_node())

  // Wrap in div with aria-label for E2E tests
  @luna_dom.div(class="flex-1 flex flex-col", [
    @luna_dom.div(
      class="relative flex-1 bg-slate-900 overflow-hidden",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("falling notes"))],
      [canvas_dom_node],
    ),
  ])
}

///|
/// Draw falling notes on canvas
fn draw_notes(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  note_positions : Array[(Int, Int, Int)],
  current_pos : Int,
) -> Unit {
  // Clear canvas
  ctx.clearRect(0.0, 0.0, width, height)

  // Background
  ctx.fillStyle = "#0f172a"
  ctx.fillRect(0.0, 0.0, width, height)
  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, 36, 96)
  let window_ms = 3000

  // Draw notes
  for note_data in note_positions {
    let (midi, start_ms, duration_ms) = note_data
    let end_ms = start_ms + duration_ms
    let start_offset = start_ms - current_pos
    let end_offset = end_ms - current_pos

    // Check if note is visible in 3-second window
    if end_offset < 0 || start_offset > window_ms {
      continue
    }

    // Find key area for this MIDI note
    let key_index = midi - 36
    if key_index < 0 || key_index >= key_areas.length() {
      continue
    }
    let key_area = key_areas[key_index]

    // Calculate vertical position (inverted: future at top, now at bottom)
    // bottom is where the note starts (closer to now)
    // top is where the note ends (further from now)
    let bottom_percent = 100.0 -
      start_offset.to_double() / window_ms.to_double() * 100.0
    let top_percent = 100.0 -
      end_offset.to_double() / window_ms.to_double() * 100.0
    let bottom_y = height * bottom_percent / 100.0
    let top_y = height * top_percent / 100.0

    // Determine color based on playing state
    let is_playing = current_pos >= start_ms && current_pos < end_ms
    ctx.fillStyle = if is_playing { "#3b82f6" } else { "#60a5fa" }

    // Draw note rectangle
    ctx.fillRect(
      key_area.rect.left,
      top_y,
      key_area.rect.width,
      bottom_y - top_y,
    )
  }

  // Draw vertical lines for white keys (after notes, so they're visible)
  for key_area in key_areas {
    if key_area.is_black {
      // Skip black keys
      ()
    } else {
      // White key - check if it's an octave line (C)
      let note_in_octave = key_area.midi % 12
      let color = if note_in_octave == 0 {
        "rgba(255, 255, 255, 0.4)" // Octave lines are darker
      } else {
        "rgba(255, 255, 255, 0.15)" // Regular white key lines
      }
      ctx.fillStyle = color
      ctx.fillRect(key_area.rect.left, 0.0, 1.0, height)
    }
  }
}
