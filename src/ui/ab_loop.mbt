///|
fn clamp_int(min : Int, value : Int, max : Int) -> Int {
  @cmp.minimum(@cmp.maximum(value, min), max)
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

  let btn_base = "w-9 h-10 flex items-center justify-center bg-blue-900/60 hover:bg-blue-800/70 text-blue-200 transition-colors text-lg font-mono select-none cursor-pointer"
  let btn_left = btn_base + " rounded-l-lg"
  let btn_right = btn_base + " rounded-r-lg"
  let value_class = "w-9 h-10 flex items-center justify-center bg-slate-800 text-slate-100 text-sm tabular-nums"
  @luna_dom.div(class="flex items-center gap-3 text-sm text-slate-400", [
    @luna_dom.span(class="text-slate-400 text-sm select-none", [
      @luna_dom.text("Loop:"),
    ]),
    @luna_dom.div(class="flex rounded-lg border border-slate-600", [
      @luna_dom.button(
        class=btn_left,
        on=@luna_dom.events().click(fn(_) { on_a_change(-1) }),
        [@luna_dom.text("\u{2212}")],
      ),
      @luna_dom.span(
        class=value_class,
        attrs=[("aria-label", @luna_dom.Attr::AttrString("loop_a"))],
        [@luna_dom.text_dyn(fn() { loop_a_measure.get().to_string() })],
      ),
      @luna_dom.button(
        class=btn_right,
        on=@luna_dom.events().click(fn(_) { on_a_change(1) }),
        [@luna_dom.text("+")],
      ),
    ]),
    @luna_dom.span(class="text-xl text-slate-200", [@luna_dom.text("~")]),
    @luna_dom.div(class="flex rounded-lg border border-slate-600", [
      @luna_dom.button(
        class=btn_left,
        on=@luna_dom.events().click(fn(_) { on_b_change(-1) }),
        [@luna_dom.text("\u{2212}")],
      ),
      @luna_dom.span(
        class=value_class,
        attrs=[("aria-label", @luna_dom.Attr::AttrString("loop_b"))],
        [
          @luna_dom.text_dyn(fn() {
            loop_b_measure.get().unwrap_or(measure_count()).to_string()
          }),
        ],
      ),
      @luna_dom.button(
        class=btn_right,
        on=@luna_dom.events().click(fn(_) { on_b_change(1) }),
        [@luna_dom.text("+")],
      ),
    ]),
  ])
}
