///|
const WHEEL_SEEK_MS = 500.0

///|
const DRAG_SENSITIVITY = 10.0

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
/// Set up mouse wheel seeking on the note display canvas
fn setup_wheel_seek(
  canvas : @js_dom.HTMLCanvasElement,
  playback_position : @signal.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> Unit {
  let on_wheel : (@js_dom.WheelEvent) -> Unit = fn(e) {
    e.preventDefault()
    let current_pos = playback_position.get().to_milliseconds()
    let new_position_ms = if e.deltaY > 0.0 {
      current_pos + WHEEL_SEEK_MS
    } else {
      current_pos - WHEEL_SEEK_MS
    }
    let clamped_position = @cmp.maximum(
      0.0,
      @cmp.minimum(new_position_ms, total_duration().to_milliseconds()),
    )
    playback_position.set(@music.Duration::from_milliseconds(clamped_position))
  }
  add_wheel_listener_notes(canvas, on_wheel)
}

///|
/// Set up drag-to-seek on the note display canvas
fn setup_drag_seek(
  canvas : @js_dom.HTMLCanvasElement,
  playback_position : @signal.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> Unit {
  let drag_start_y : Ref[Double?] = { val: None }
  let drag_start_position_ms : Ref[Double?] = { val: None }
  let on_drag_start : (@js_dom.MouseEvent) -> Unit = fn(e) {
    drag_start_y.val = Some(e.clientY)
    drag_start_position_ms.val = Some(playback_position.get().to_milliseconds())
  }
  let on_drag_move : (@js_dom.MouseEvent) -> Unit = fn(e) {
    match (drag_start_y.val, drag_start_position_ms.val) {
      (Some(start_y), Some(start_pos)) => {
        let delta_y = e.clientY - start_y
        let new_position_ms = start_pos + delta_y * DRAG_SENSITIVITY
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
}
