///|
const WHEEL_SEEK_MS = 500.0

///|
const DRAG_SENSITIVITY = 10.0

///|
/// Friction factor applied per frame to decelerate inertial scrolling
const FRICTION = 0.90

///|
/// Minimum velocity (px/ms) below which inertia animation stops
const MIN_VELOCITY = 0.1

///|
/// Exponential moving average smoothing factor for velocity tracking
const VELOCITY_SMOOTHING = 0.3

///|
extern "js" fn add_wheel_listener_notes(
  canvas : @js_dom.HTMLCanvasElement,
  handler : (@js_dom.WheelEvent) -> Unit,
) -> Unit =
  #|(canvas, handler) => { canvas.addEventListener('wheel', handler); }

///|
/// Register document-level drag listeners for vertical (Y-axis) drag.
/// Call this from a mousedown/touchstart handler to track the drag until release.
extern "js" fn add_document_drag_listeners_y(
  on_move : (Double) -> Unit,
  on_up : () -> Unit,
) -> Unit =
  #|(onMove, onUp) => {
  #|  const moveHandler = (e) => onMove(e.clientY);
  #|  const upHandler = () => {
  #|    onUp();
  #|    document.removeEventListener('mousemove', moveHandler);
  #|    document.removeEventListener('mouseup', upHandler);
  #|  };
  #|  document.addEventListener('mousemove', moveHandler);
  #|  document.addEventListener('mouseup', upHandler);
  #|  const touchMoveHandler = (e) => {
  #|    if (e.touches.length > 0) {
  #|      e.preventDefault();
  #|      onMove(e.touches[0].clientY);
  #|    }
  #|  };
  #|  const touchEndHandler = () => {
  #|    onUp();
  #|    document.removeEventListener('touchmove', touchMoveHandler);
  #|    document.removeEventListener('touchend', touchEndHandler);
  #|    document.removeEventListener('touchcancel', touchEndHandler);
  #|  };
  #|  document.addEventListener('touchmove', touchMoveHandler, { passive: false });
  #|  document.addEventListener('touchend', touchEndHandler);
  #|  document.addEventListener('touchcancel', touchEndHandler);
  #|}

///|
/// Attach mousedown/touchstart listeners to a canvas element.
/// Calls on_start with the clientY coordinate when drag begins.
extern "js" fn add_canvas_drag_start_listeners(
  canvas : @js_dom.HTMLCanvasElement,
  on_start : (Double) -> Unit,
) -> Unit =
  #|(canvas, onStart) => {
  #|  canvas.addEventListener('mousedown', (e) => {
  #|    if (e.button === 0) { onStart(e.clientY); }
  #|  });
  #|  canvas.addEventListener('touchstart', (e) => {
  #|    if (e.touches.length > 0) { onStart(e.touches[0].clientY); }
  #|  });
  #|}

///|
extern "js" fn performance_now() -> Double =
  #|() => performance.now()

///|
/// Set up mouse wheel seeking on the note display canvas
fn setup_wheel_seek(
  canvas : @js_dom.HTMLCanvasElement,
  playback_position : @signals.Signal[@music.Duration],
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
fn clamp_position_ms(
  position_ms : Double,
  total_duration : () -> @music.Duration,
) -> Double {
  @cmp.maximum(
    0.0,
    @cmp.minimum(position_ms, total_duration().to_milliseconds()),
  )
}

///|
/// Set up drag-to-seek on the note display canvas with inertial scrolling
fn setup_drag_seek(
  canvas : @js_dom.HTMLCanvasElement,
  playback_position : @signals.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> Unit {
  let drag_start_y : Ref[Double?] = { val: None }
  let drag_start_position_ms : Ref[Double?] = { val: None }
  let last_y : Ref[Double] = { val: 0.0 }
  let last_time : Ref[Double] = { val: 0.0 }
  let smoothed_velocity : Ref[Double] = { val: 0.0 }
  let inertia_frame_id : Ref[Int?] = { val: None }

  let cancel_inertia : () -> Unit = fn() {
    match inertia_frame_id.val {
      Some(id) => {
        @js_dom.window().cancelAnimationFrame(id)
        inertia_frame_id.val = None
      }
      None => ()
    }
  }

  let on_drag_move : (Double) -> Unit = fn(client_y) {
    match (drag_start_y.val, drag_start_position_ms.val) {
      (Some(start_y), Some(start_pos)) => {
        let now = performance_now()
        let dt = now - last_time.val
        if dt > 0.0 {
          let raw_velocity = (client_y - last_y.val) / dt
          smoothed_velocity.val = VELOCITY_SMOOTHING * raw_velocity +
            (1.0 - VELOCITY_SMOOTHING) * smoothed_velocity.val
        }
        last_y.val = client_y
        last_time.val = now
        let delta_y = client_y - start_y
        let new_position_ms = start_pos + delta_y * DRAG_SENSITIVITY
        let clamped = clamp_position_ms(new_position_ms, total_duration)
        playback_position.set(@music.Duration::from_milliseconds(clamped))
      }
      _ => ()
    }
  }
  let on_drag_end : () -> Unit = fn() {
    let velocity = smoothed_velocity.val
    drag_start_y.val = None
    drag_start_position_ms.val = None
    if velocity.abs() > MIN_VELOCITY {
      let current_velocity : Ref[Double] = { val: velocity }
      let prev_time : Ref[Double?] = { val: None }
      fn inertia_step(timestamp : Double) -> Unit {
        let dt = match prev_time.val {
          Some(t) => timestamp - t
          None => {
            prev_time.val = Some(timestamp)
            inertia_frame_id.val = Some(
              @js_dom.window().requestAnimationFrame(inertia_step),
            )
            return
          }
        }
        prev_time.val = Some(timestamp)
        current_velocity.val = current_velocity.val * FRICTION
        if current_velocity.val.abs() < MIN_VELOCITY {
          inertia_frame_id.val = None
          return
        }
        let current_ms = playback_position.get().to_milliseconds()
        let delta_ms = current_velocity.val * dt * DRAG_SENSITIVITY
        let new_ms = clamp_position_ms(current_ms + delta_ms, total_duration)
        playback_position.set(@music.Duration::from_milliseconds(new_ms))
        if new_ms == current_ms {
          inertia_frame_id.val = None
          return
        }
        inertia_frame_id.val = Some(
          @js_dom.window().requestAnimationFrame(inertia_step),
        )
      }

      inertia_frame_id.val = Some(
        @js_dom.window().requestAnimationFrame(inertia_step),
      )
    }
  }

  add_canvas_drag_start_listeners(canvas, fn(client_y) {
    cancel_inertia()
    drag_start_y.val = Some(client_y)
    drag_start_position_ms.val = Some(playback_position.get().to_milliseconds())
    last_y.val = client_y
    last_time.val = performance_now()
    smoothed_velocity.val = 0.0
    add_document_drag_listeners_y(on_drag_move, on_drag_end)
  })
}
