///|
extern "js" fn add_document_drag_listeners(
  on_move : (@js_dom.MouseEvent) -> Unit,
  on_up : (@js_dom.MouseEvent) -> Unit,
) -> Unit =
  #|(onMove, onUp) => {
  #|  const moveHandler = (e) => onMove(e);
  #|  const upHandler = (e) => {
  #|    onUp(e);
  #|    document.removeEventListener('mousemove', moveHandler);
  #|    document.removeEventListener('mouseup', upHandler);
  #|  };
  #|  document.addEventListener('mousemove', moveHandler);
  #|  document.addEventListener('mouseup', upHandler);
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
  let on_mousemove : (@js_dom.MouseEvent) -> Unit = fn(e) {
    match drag_start_x.val {
      Some(start_x) => {
        let delta = e.clientX - start_x
        let steps = (delta / 20.0).to_int()
        let new_value = drag_start_value.val + steps * step
        update_value(new_value)
      }
      None => ()
    }
  }
  let on_mouseup : (@js_dom.MouseEvent) -> Unit = fn(_) {
    drag_start_x.val = None
  }

  let on_mousedown : @luna_dom.MouseHandler = fn(e) {
    drag_start_x.val = Some(e.clientX)
    drag_start_value.val = signal.get()
    add_document_drag_listeners(on_mousemove, on_mouseup)
  }

  let btn_class = "bg-blue-900/60 hover:bg-blue-800/70 border border-blue-700/50 rounded-lg w-9 py-1 text-lg text-blue-200 text-center cursor-pointer select-none"

  @luna_dom.div(
    class="flex items-center gap-2",
    on=@luna_dom.events().wheel(on_wheel).mousedown(on_mousedown),
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
