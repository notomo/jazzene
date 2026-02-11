///|
extern "js" fn add_document_drag_listeners(
  on_move : (Double) -> Unit,
  on_up : () -> Unit,
) -> Unit =
  #|(onMove, onUp) => {
  #|  const moveHandler = (e) => onMove(e.clientX);
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
  #|      onMove(e.touches[0].clientX);
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
/// Reusable spinbox component for tablet-friendly numeric input.
/// Displays `{label}: {value} [-][+]` with wheel and drag support.
fn spinbox(
  label~ : String,
  signal : @signal.Signal[Int],
  query_param~ : String,
  min~ : Int,
  max~ : Int,
  step~ : Int,
) -> @luna_dom.DomNode {
  let drag_start_x : Ref[Double?] = Ref::new(None)
  let drag_start_value : Ref[Int] = Ref::new(0)

  fn clamp(value : Int) -> Int {
    @cmp.maximum(min, @cmp.minimum(max, value))
  }

  fn update_value(new_value : Int) -> Unit {
    let clamped = clamp(new_value)
    signal.set(clamped)
    set_query_param(query_param, clamped.to_string())
  }

  let on_decrement : @luna_dom.MouseHandler = fn(_) {
    update_value(signal.get() - step)
  }
  let on_increment : @luna_dom.MouseHandler = fn(_) {
    update_value(signal.get() + step)
  }

  let on_wheel : @luna_dom.WheelHandler = fn(e) {
    e.preventDefault()
    let delta_y = e.deltaY
    if delta_y < 0.0 {
      update_value(signal.get() + step)
    } else if delta_y > 0.0 {
      update_value(signal.get() - step)
    }
  }
  let on_drag_move : (Double) -> Unit = fn(client_x) {
    match drag_start_x.val {
      Some(start_x) => {
        let delta = client_x - start_x
        let steps = (delta / 20.0).to_int()
        let new_value = drag_start_value.val + steps * step
        update_value(new_value)
      }
      None => ()
    }
  }
  let on_drag_end : () -> Unit = fn() { drag_start_x.val = None }

  fn start_drag(client_x : Double) -> Unit {
    drag_start_x.val = Some(client_x)
    drag_start_value.val = signal.get()
    add_document_drag_listeners(on_drag_move, on_drag_end)
  }

  let on_mousedown : @luna_dom.MouseHandler = fn(e) { start_drag(e.clientX) }
  let on_touchstart : @luna_dom.TouchHandler = fn(e) {
    if e.touches.length() > 0 {
      start_drag(e.touches[0].clientX)
    }
  }

  let btn_class = "bg-blue-900/60 hover:bg-blue-800/70 border border-blue-700/50 rounded-lg w-9 py-1 text-lg text-blue-200 text-center cursor-pointer select-none"

  @luna_dom.div(
    class="flex items-center gap-2",
    on=@luna_dom.events()
      .wheel(on_wheel)
      .mousedown(on_mousedown)
      .touchstart(on_touchstart),
    [
      @luna_dom.span(
        class="text-base text-slate-400 mr-1 select-none cursor-ew-resize",
        [@luna_dom.text(label + ":")],
      ),
      @luna_dom.span(
        class="text-white text-base select-none cursor-ew-resize min-w-[3ch] text-center",
        attrs=[("aria-label", @luna_dom.Attr::AttrString(query_param))],
        [@luna_dom.text_dyn(fn() { signal.get().to_string() })],
      ),
      @luna_dom.button(
        class=btn_class,
        on=@luna_dom.events().click(on_decrement),
        [@luna_dom.text("-")],
      ),
      @luna_dom.button(
        class=btn_class,
        on=@luna_dom.events().click(on_increment),
        [@luna_dom.text("+")],
      ),
    ],
  )
}
