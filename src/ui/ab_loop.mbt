///|
fn clamp_int(min : Int, value : Int, max : Int) -> Int {
  @cmp.minimum(@cmp.maximum(value, min), max)
}

///|
fn ab_loop_spinbox(
  on_change : (Int) -> Unit,
  get_value : () -> Int,
  aria_label : String,
) -> @luna_dom.DomNode {
  let drag_start_x : Ref[Double?] = Ref::new(None)
  let drag_start_value : Ref[Int] = Ref::new(0)
  let on_drag_move : (Double) -> Unit = fn(client_x) {
    match drag_start_x.val {
      Some(start_x) => {
        let steps = ((client_x - start_x) / 20.0).to_int()
        on_change(drag_start_value.val + steps - get_value())
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

  let on_wheel : @luna_dom.WheelHandler = fn(e) {
    e.preventDefault()
    let delta_y = e.deltaY
    if delta_y < 0.0 {
      on_change(1)
    } else if delta_y > 0.0 {
      on_change(-1)
    }
  }
  let on_mousedown : @luna_dom.MouseHandler = fn(e) { start_drag(e.clientX) }
  let on_touchstart : @luna_dom.TouchHandler = fn(e) {
    if e.touches.length() > 0 {
      start_drag(e.touches[0].clientX)
    }
  }
  let btn_base = "w-9 flex items-center justify-center bg-blue-900/60 hover:bg-blue-800/70 text-blue-200 transition-colors text-lg font-mono select-none cursor-pointer"
  let btn_left = btn_base + " rounded-l-lg"
  let btn_right = btn_base + " rounded-r-lg"
  let value_class = "w-9 flex items-center justify-center bg-slate-800 text-slate-100 text-base tabular-nums select-none cursor-ew-resize"
  @luna_dom.div(
    class="flex rounded-lg border border-slate-600",
    on=@luna_dom.events()
      .wheel(on_wheel)
      .mousedown(on_mousedown)
      .touchstart(on_touchstart),
    [
      @luna_dom.button(
        class=btn_left,
        on=@luna_dom.events().click(fn(_) { on_change(-1) }),
        [@luna_dom.text("\u{2212}")],
      ),
      @luna_dom.span(
        class=value_class,
        attrs=[("aria-label", @luna_dom.Attr::AttrString(aria_label))],
        [@luna_dom.text_dyn(fn() { get_value().to_string() })],
      ),
      @luna_dom.button(
        class=btn_right,
        on=@luna_dom.events().click(fn(_) { on_change(1) }),
        [@luna_dom.text("+")],
      ),
    ],
  )
}

///|
/// Render A-B loop control UI
fn ab_loop(
  loop_a_measure : @signal.Signal[Int],
  loop_b_measure : @signal.Signal[Int?],
  measure_count : () -> Int,
) -> @luna_dom.DomNode {
  let on_a_change = fn(delta : Int) {
    let max_a = loop_b_measure.get().unwrap_or(measure_count())
    let clamped = clamp_int(1, loop_a_measure.get() + delta, max_a)
    loop_a_measure.set(clamped)
    set_query_param("loop_a", clamped.to_string())
  }

  let on_b_change = fn(delta : Int) {
    let clamped = clamp_int(
      loop_a_measure.get(),
      loop_b_measure.get().unwrap_or(measure_count()) + delta,
      measure_count(),
    )
    loop_b_measure.set(Some(clamped))
    set_query_param("loop_b", clamped.to_string())
  }

  @luna_dom.div(class="flex items-center gap-3 text-base text-slate-400", [
    @luna_dom.span(class="text-slate-400 text-base select-none", [
      @luna_dom.text("Loop:"),
    ]),
    ab_loop_spinbox(on_a_change, fn() { loop_a_measure.get() }, "loop_a"),
    @luna_dom.span(class="text-xl text-slate-200", [@luna_dom.text("~")]),
    ab_loop_spinbox(
      on_b_change,
      fn() { loop_b_measure.get().unwrap_or(measure_count()) },
      "loop_b",
    ),
  ])
}
