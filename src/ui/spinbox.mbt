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
  get_value~ : () -> Int,
  on_change~ : (Int, Int) -> Unit,
  min~ : Int,
  max~ : Int,
  step~ : Int,
  aria_label? : String = "",
) -> @luna_dom.DomNode {
  let drag_start_x : Ref[Double?] = Ref::new(None)
  let drag_start_value : Ref[Int] = Ref::new(0)

  fn clamp(value : Int) -> Int {
    @cmp.maximum(min, @cmp.minimum(max, value))
  }

  fn update_value(new_value : Int) -> Unit {
    let old_value = get_value()
    let clamped = clamp(new_value)
    if clamped != old_value {
      on_change(clamped, old_value)
    }
  }

  let on_decrement : @luna_dom.MouseHandler = fn(_) {
    update_value(get_value() - step)
  }
  let on_increment : @luna_dom.MouseHandler = fn(_) {
    update_value(get_value() + step)
  }

  let on_wheel : @luna_dom.WheelHandler = fn(e) {
    e.preventDefault()
    let delta_y = e.deltaY
    if delta_y < 0.0 {
      update_value(get_value() + step)
    } else if delta_y > 0.0 {
      update_value(get_value() - step)
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
    drag_start_value.val = get_value()
    add_document_drag_listeners(on_drag_move, on_drag_end)
  }

  let on_mousedown : @luna_dom.MouseHandler = fn(e) { start_drag(e.clientX) }
  let on_touchstart : @luna_dom.TouchHandler = fn(e) {
    if e.touches.length() > 0 {
      start_drag(e.touches[0].clientX)
    }
  }

  let aria = if aria_label == "" { label } else { aria_label }
  let btn_class = "bg-blue-900/60 hover:bg-blue-800/70 border border-blue-700/50 rounded-lg w-7 lg:w-9 py-1 text-base lg:text-lg text-blue-200 text-center cursor-pointer select-none"

  @luna_dom.div(
    class="flex items-center gap-1 lg:gap-2 shrink min-w-0",
    on=@luna_dom.events()
      .wheel(on_wheel)
      .mousedown(on_mousedown)
      .touchstart(on_touchstart),
    [
      @luna_dom.span(
        class="text-sm lg:text-base text-slate-400 select-none cursor-ew-resize whitespace-nowrap",
        [@luna_dom.text(label + ":")],
      ),
      @luna_dom.span(
        class="text-white text-sm lg:text-base select-none cursor-ew-resize min-w-[2ch] lg:min-w-[3ch] text-center",
        attrs=[("aria-label", @luna_dom.Attr::AttrString(aria))],
        [@luna_dom.text_dyn(fn() { get_value().to_string() })],
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
