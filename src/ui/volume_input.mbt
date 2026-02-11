///|
/// Render volume control as a spinbox (0–100%)
fn volume_input(volume : @signal.Signal[Double]) -> @luna_dom.DomNode {
  let drag_start_x : Ref[Double?] = Ref::new(None)
  let drag_start_value : Ref[Int] = Ref::new(0)
  let min = 0
  let max = 100
  let step = 5

  fn clamp(value : Int) -> Int {
    @cmp.maximum(min, @cmp.minimum(max, value))
  }

  fn percent() -> Int {
    (volume.get() * 100.0).to_int()
  }

  fn update_value(new_percent : Int) -> Unit {
    let clamped = clamp(new_percent)
    volume.set(clamped.to_double() / 100.0)
  }

  let on_decrement : @luna_dom.MouseHandler = fn(_) {
    update_value(percent() - step)
  }
  let on_increment : @luna_dom.MouseHandler = fn(_) {
    update_value(percent() + step)
  }

  let on_wheel : @luna_dom.WheelHandler = fn(e) {
    e.preventDefault()
    let delta_y = e.deltaY
    if delta_y < 0.0 {
      update_value(percent() + step)
    } else if delta_y > 0.0 {
      update_value(percent() - step)
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
    drag_start_value.val = percent()
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
        [@luna_dom.text("Volume:")],
      ),
      @luna_dom.span(
        class="text-white text-base select-none cursor-ew-resize min-w-[3ch] text-center",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("volume"))],
        [@luna_dom.text_dyn(fn() { percent().to_string() })],
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
