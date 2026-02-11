///|
fn clamp(
  min : @music.Duration,
  value : @music.Duration,
  max : @music.Duration,
) -> @music.Duration {
  @cmp.minimum(@cmp.maximum(value, min), max)
}

///|
/// Render A-B loop control UI
fn ab_loop(
  loop_enabled : @signal.Signal[Bool],
  loop_a_time : @signal.Signal[@music.Duration],
  loop_b_time : @signal.Signal[@music.Duration?],
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  let on_enabled_checkbox_input : @luna_dom.InputHandler = fn(e) {
    let checked = get_checkbox_checked(e)
    loop_enabled.set(checked)
    set_query_param("loop", checked.to_string())
  }

  let on_a_time_input : @luna_dom.InputHandler = fn(e) {
    match @music.Duration::parse(get_input_value(e)) {
      Some(new_a) => {
        let b = loop_b_time.get().unwrap_or(total_duration())
        let max_a = @cmp.minimum(b, total_duration())
        let zero = @music.Duration::from_milliseconds(0.0)
        let clamped = clamp(zero, new_a, max_a)
        loop_a_time.set(clamped)
        set_query_param("loop_a", clamped.format())
      }
      None => ()
    }
  }

  let on_b_time_input : @luna_dom.InputHandler = fn(e) {
    match @music.Duration::parse(get_input_value(e)) {
      Some(new_b) => {
        let zero = @music.Duration::from_milliseconds(0.0)
        let min_b = @cmp.maximum(loop_a_time.get(), zero)
        let clamped = clamp(min_b, new_b, total_duration())
        loop_b_time.set(Some(clamped))
        set_query_param("loop_b", clamped.format())
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
        type_="text",
        class="w-16 px-1 py-0.5 bg-slate-900 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("A loop time")),
          ("placeholder", @luna_dom.Attr::AttrString("0:00")),
        ],
        dyn_value=fn() { loop_a_time.get().format() },
        on=@luna_dom.events().input(on_a_time_input),
      ),
    ]),
    @luna_dom.label(class="flex gap-1 items-center", [
      @luna_dom.text("B:"),
      @luna_dom.input(
        type_="text",
        class="w-16 px-1 py-0.5 bg-slate-900 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("B loop time")),
          ("placeholder", @luna_dom.Attr::AttrString("0:00")),
        ],
        dyn_value=fn() {
          let b = loop_b_time.get().unwrap_or(total_duration())
          b.format()
        },
        on=@luna_dom.events().input(on_b_time_input),
      ),
    ]),
  ])
}
