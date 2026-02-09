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
  let on_mousedown : @luna_dom.MouseHandler = fn(e) {
    drag_start_x.val = Some(e.clientX)
    drag_start_value.val = signal.get()
  }
  let on_mousemove : @luna_dom.MouseHandler = fn(e) {
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
  let on_mouseup : @luna_dom.MouseHandler = fn(_) { drag_start_x.val = None }
  let btn_class = "bg-slate-700 hover:bg-slate-600 rounded px-2 py-1 text-sm text-white cursor-pointer select-none"
  @luna_dom.div(
    class="flex items-center gap-1",
    on=@luna_dom.events().mousemove(on_mousemove).mouseup(on_mouseup),
    [
      @luna_dom.span(class="text-sm text-slate-400 mr-1", [
        @luna_dom.text(label + ":"),
      ]),
      @luna_dom.span(
        class="text-white text-sm select-none cursor-ew-resize min-w-[3ch] text-center",
        attrs=[("aria-label", @luna_dom.Attr::AttrString(query_param))],
        on=@luna_dom.events().wheel(on_wheel).mousedown(on_mousedown),
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
