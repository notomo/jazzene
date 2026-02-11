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
  on_drag_move : (Double) -> Unit,
  on_drag_end : () -> Unit,
) -> Unit =
  #|(canvas, onDragStart, onDragMove, onDragEnd) => {
  #|  function startDocumentListeners() {
  #|    const moveHandler = (e) => onDragMove(e.clientY);
  #|    const upHandler = () => {
  #|      onDragEnd();
  #|      document.removeEventListener('mousemove', moveHandler);
  #|      document.removeEventListener('mouseup', upHandler);
  #|    };
  #|    document.addEventListener('mousemove', moveHandler);
  #|    document.addEventListener('mouseup', upHandler);
  #|    const touchMoveHandler = (e) => {
  #|      if (e.touches.length > 0) {
  #|        e.preventDefault();
  #|        onDragMove(e.touches[0].clientY);
  #|      }
  #|    };
  #|    const touchEndHandler = () => {
  #|      onDragEnd();
  #|      document.removeEventListener('touchmove', touchMoveHandler);
  #|      document.removeEventListener('touchend', touchEndHandler);
  #|      document.removeEventListener('touchcancel', touchEndHandler);
  #|    };
  #|    document.addEventListener('touchmove', touchMoveHandler, { passive: false });
  #|    document.addEventListener('touchend', touchEndHandler);
  #|    document.addEventListener('touchcancel', touchEndHandler);
  #|  }
  #|  canvas.addEventListener('mousedown', (e) => {
  #|    if (e.button === 0) { onDragStart(e); startDocumentListeners(); }
  #|  });
  #|  canvas.addEventListener('touchstart', (e) => {
  #|    if (e.touches.length > 0) {
  #|      onDragStart({ clientY: e.touches[0].clientY });
  #|      startDocumentListeners();
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
  let on_drag_move : (Double) -> Unit = fn(client_y) {
    match (drag_start_y.val, drag_start_position_ms.val) {
      (Some(start_y), Some(start_pos)) => {
        let delta_y = client_y - start_y
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
  let on_drag_end : () -> Unit = fn() {
    drag_start_y.val = None
    drag_start_position_ms.val = None
  }

  add_drag_listeners_notes(canvas, on_drag_start, on_drag_move, on_drag_end)
}
