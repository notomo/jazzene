///|
fn clamp_int(min : Int, value : Int, max : Int) -> Int {
  @cmp.minimum(@cmp.maximum(value, min), max)
}

///|
/// Render A-B loop control UI
fn ab_loop(
  loop_enabled : @signal.Signal[Bool],
  loop_a_measure : @signal.Signal[Int],
  loop_b_measure : @signal.Signal[Int?],
  measure_count : () -> Int,
) -> @luna_dom.DomNode {
  let on_enabled_checkbox_input : @luna_dom.InputHandler = fn(e) {
    let checked = get_checkbox_checked(e)
    loop_enabled.set(checked)
    set_query_param("loop", checked.to_string())
  }

  let on_a_input : @luna_dom.InputHandler = fn(e) {
    match @js_global.parseInt(get_input_value(e)) {
      Some(new_a) => {
        let max_a = loop_b_measure.get().unwrap_or(measure_count())
        let clamped = clamp_int(1, new_a, max_a)
        loop_a_measure.set(clamped)
        set_query_param("loop_a", clamped.to_string())
      }
      None => ()
    }
  }

  let on_b_input : @luna_dom.InputHandler = fn(e) {
    match @js_global.parseInt(get_input_value(e)) {
      Some(new_b) => {
        let clamped = clamp_int(loop_a_measure.get(), new_b, measure_count())
        loop_b_measure.set(Some(clamped))
        set_query_param("loop_b", clamped.to_string())
      }
      None => ()
    }
  }

  @luna_dom.div(class="flex gap-2 items-center text-sm text-slate-400", [
    @luna_dom.input(
      type_="checkbox",
      class="w-4 h-4 accent-blue-500 cursor-pointer",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("enable A-B loop"))],
      dyn_checked=fn() { loop_enabled.get() },
      on=@luna_dom.events().input(on_enabled_checkbox_input),
    ),
    @luna_dom.label(class="flex gap-1 items-center", [
      @luna_dom.text("A:"),
      @luna_dom.input(
        type_="number",
        class="w-16 px-1 py-0.5 bg-slate-900 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("A loop measure")),
          ("min", @luna_dom.Attr::AttrString("1")),
        ],
        dyn_value=fn() { loop_a_measure.get().to_string() },
        on=@luna_dom.events().input(on_a_input),
      ),
    ]),
    @luna_dom.label(class="flex gap-1 items-center", [
      @luna_dom.text("B:"),
      @luna_dom.input(
        type_="number",
        class="w-16 px-1 py-0.5 bg-slate-900 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("B loop measure")),
          ("min", @luna_dom.Attr::AttrString("1")),
        ],
        dyn_value=fn() {
          loop_b_measure.get().unwrap_or(measure_count()).to_string()
        },
        on=@luna_dom.events().input(on_b_input),
      ),
    ]),
  ])
}
