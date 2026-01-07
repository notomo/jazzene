///|
extern "js" fn add_wheel_listener_notes(
  canvas : @js_dom.HTMLCanvasElement,
  handler : (@js_dom.WheelEvent) -> Unit,
) -> Unit =
  #|(canvas, handler) => { canvas.addEventListener('wheel', handler); }

///|
extern "js" fn add_drag_listeners_notes(
  canvas : @js_dom.HTMLCanvasElement,
  on_drag_start : (@js_dom.MouseEvent) -> Unit,
  on_drag_move : (@js_dom.MouseEvent) -> Unit,
  on_drag_end : (@js_dom.MouseEvent) -> Unit,
) -> Unit =
  #|(canvas, onDragStart, onDragMove, onDragEnd) => {
  #|  // Mouse events
  #|  canvas.addEventListener('mousedown', onDragStart);
  #|  canvas.addEventListener('mousemove', onDragMove);
  #|  canvas.addEventListener('mouseup', onDragEnd);
  #|  canvas.addEventListener('mouseleave', onDragEnd);
  #|
  #|  // Touch events for tablets/mobile
  #|  canvas.addEventListener('touchstart', (e) => {
  #|    if (e.touches.length > 0) {
  #|      const touch = e.touches[0];
  #|      onDragStart({ clientY: touch.clientY });
  #|    }
  #|  });
  #|  canvas.addEventListener('touchmove', (e) => {
  #|    if (e.touches.length > 0) {
  #|      e.preventDefault(); // Prevent scrolling while dragging
  #|      const touch = e.touches[0];
  #|      onDragMove({ clientY: touch.clientY });
  #|    }
  #|  }, { passive: false });
  #|  canvas.addEventListener('touchend', (e) => {
  #|    if (e.changedTouches.length > 0) {
  #|      const touch = e.changedTouches[0];
  #|      onDragEnd({ clientY: touch.clientY });
  #|    }
  #|  });
  #|  canvas.addEventListener('touchcancel', (e) => {
  #|    if (e.changedTouches.length > 0) {
  #|      const touch = e.changedTouches[0];
  #|      onDragEnd({ clientY: touch.clientY });
  #|    }
  #|  });
  #|}

///|
/// Render falling notes display component using Canvas API
pub fn note_display(
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  let canvas_elem = @js_dom.document().createElement("canvas")
  let canvas = cast_to_canvas(canvas_elem)
  set_canvas_style_width(canvas, "100%")
  set_canvas_style_height(canvas, "100%")
  let ctx = get_context_2d(canvas)

  // Pre-calculate note positions (immutable list with start times)
  let note_positions = @signal.memo(fn() {
    let sound_list = sounds.get()
    let mut current_pos = 0.0
    let positions : Array[(Int, Double, Double)] = [] // (midi, start_ms, duration_ms)
    for sound in sound_list {
      let duration_ms = sound.duration.to_milliseconds()
      // Only track positions for actual notes (rests are invisible gaps)
      match sound.note_value {
        Note(midi=midi_val, ..) =>
          positions.push((midi_val.value, current_pos, duration_ms))
        Rest(..) => () // Rests don't render but advance timing
      }
      current_pos = current_pos + duration_ms
    }
    positions
  })

  // Add wheel event listener for seeking
  let on_wheel : (@js_dom.WheelEvent) -> Unit = fn(e) {
    if sounds.get().length() == 0 {
      return
    }
    e.preventDefault()
    let current_pos = playback_position.get().to_milliseconds()
    let seek_amount = 500.0 // milliseconds per wheel tick
    let new_position_ms = if e.deltaY > 0.0 {
      current_pos + seek_amount
    } else {
      current_pos - seek_amount
    }
    let clamped_position = @cmp.maximum(
      0.0,
      @cmp.minimum(new_position_ms, total_duration().to_milliseconds()),
    )
    playback_position.set(@music.Duration::from_milliseconds(clamped_position))
  }
  add_wheel_listener_notes(canvas, on_wheel)

  // Add drag event listeners for seeking
  let drag_start_y : Ref[Double?] = { val: None }
  let drag_start_position_ms : Ref[Double?] = { val: None }
  let on_drag_start : (@js_dom.MouseEvent) -> Unit = fn(e) {
    if sounds.get().length() == 0 {
      return
    }
    drag_start_y.val = Some(e.clientY)
    drag_start_position_ms.val = Some(playback_position.get().to_milliseconds())
  }
  let on_drag_move : (@js_dom.MouseEvent) -> Unit = fn(e) {
    match (drag_start_y.val, drag_start_position_ms.val) {
      (Some(start_y), Some(start_pos)) => {
        let current_y = e.clientY
        let delta_y = current_y - start_y

        // Calculate seek amount based on drag distance
        // 10 pixels = 100ms (adjustable sensitivity)
        let seek_amount = delta_y * 10.0
        let new_position_ms = start_pos + seek_amount
        let clamped_position = @cmp.maximum(
          0.0,
          @cmp.minimum(new_position_ms, total_duration().to_milliseconds()),
        )
        playback_position.set(
          @music.Duration::from_milliseconds(clamped_position),
        )
      }
      _ => ()
    }
  }
  let on_drag_end : (@js_dom.MouseEvent) -> Unit = fn(_e) {
    drag_start_y.val = None
    drag_start_position_ms.val = None
  }
  add_drag_listeners_notes(canvas, on_drag_start, on_drag_move, on_drag_end)

  // Redraw when position or notes change
  let _ = @signal.effect(fn() {
    let pos = playback_position.get().to_milliseconds()
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
      bpm.get(),
    )
  })

  // Convert canvas to DomNode using ToDomNode trait
  let canvas_dom_node = @luna_dom.ToDomNode::to_dom_node(canvas.as_node())

  // Wrap in div with aria-label for E2E tests
  @luna_dom.div(class="h-full flex flex-col", [
    @luna_dom.div(
      class="relative flex-1 bg-slate-900",
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
  note_positions : Array[(Int, Double, Double)],
  current_pos : Double,
  bpm : Int,
) -> Unit {
  // Clear canvas
  ctx.clearRect(0.0, 0.0, width, height)

  // Background
  ctx.fillStyle = "#0f172a"
  ctx.fillRect(0.0, 0.0, width, height)
  let rect = { left: 0.0, top: 0.0, width, height }
  let key_areas = calc_key_areas(rect, 36, 96)
  let window_ms = 3000.0

  // Draw notes
  for note_data in note_positions {
    let (midi, start_ms, duration_ms) = note_data
    let end_ms = start_ms + duration_ms
    let start_offset = start_ms - current_pos
    let end_offset = end_ms - current_pos

    // Check if note is visible in 3-second window
    if end_offset < 0.0 || start_offset > window_ms {
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
    let bottom_percent = 100.0 - start_offset / window_ms * 100.0
    let top_percent = 100.0 - end_offset / window_ms * 100.0
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

  // Draw horizontal lines for each measure
  // In 4/4 time, one measure = 4 quarter notes
  let measure_ms = (60000 * 4 / bpm).to_double() // (60000ms/BPM) * 4 beats

  // Find the first measure line visible in the window
  let first_measure = (current_pos / measure_ms).to_int()
  let last_measure = ((current_pos + window_ms) / measure_ms).to_int() + 1
  for i = first_measure; i <= last_measure; i = i + 1 {
    let measure_pos_ms = i.to_double() * measure_ms
    let offset = measure_pos_ms - current_pos

    // Check if this measure line is visible
    if offset >= 0.0 && offset <= window_ms {
      // Calculate y position (inverted: future at top, now at bottom)
      let percent = 100.0 - offset / window_ms * 100.0
      let y = height * percent / 100.0
      ctx.fillStyle = "rgba(255, 255, 255, 0.3)"
      ctx.fillRect(0.0, y, width, 1.0)
    }
  }
}
