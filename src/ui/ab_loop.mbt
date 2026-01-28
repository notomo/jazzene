///|
/// State management for A-B loop
pub struct LoopState {
  enabled : @signal.Signal[Bool]
  a_time : @signal.Signal[@music.Duration]
  b_time : @signal.Signal[@music.Duration?]
}

///|
/// Create loop state with default values
pub fn create_loop_state() -> LoopState {
  LoopState::{
    enabled: @signal.signal(false),
    a_time: @signal.signal(@music.Duration::from_milliseconds(0.0)),
    b_time: @signal.signal(None),
  }
}

///|
/// Render A-B loop control UI
fn ab_loop(
  loop_state : LoopState,
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  let on_enabled_checkbox_input : @luna_dom.InputHandler = fn(e) {
    loop_state.enabled.set(get_checkbox_checked(e))
  }

  // Text input handler for A time
  let on_a_time_input : @luna_dom.InputHandler = fn(e) {
    match parse_time(get_input_value(e)) {
      Some(new_a) => {
        // Clamp to [0, min(b_time, total_duration)]
        let b = loop_state.b_time.get().unwrap_or(total_duration())
        let max_a = @cmp.minimum(b, total_duration())
        let clamped = @cmp.minimum(
          @cmp.maximum(new_a, @music.Duration::from_milliseconds(0.0)),
          max_a,
        )
        loop_state.a_time.set(clamped)
      }
      None => ()
    }
  }

  // Text input handler for B time
  let on_b_time_input : @luna_dom.InputHandler = fn(e) {
    match parse_time(get_input_value(e)) {
      Some(new_b) => {
        // Clamp to [max(a_time, 0), total_duration]
        let min_b = @cmp.maximum(
          loop_state.a_time.get(),
          @music.Duration::from_milliseconds(0.0),
        )
        let clamped = @cmp.minimum(@cmp.maximum(new_b, min_b), total_duration())
        loop_state.b_time.set(Some(clamped))
      }
      None => ()
    }
  }
  @luna_dom.div(class="flex gap-2 items-center text-sm text-slate-300", [
    @luna_dom.input(
      type_="checkbox",
      class="w-4 h-4 accent-blue-500 cursor-pointer",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("enable A-B loop"))],
      dyn_checked=fn() { loop_state.enabled.get() },
      on=@luna_dom.events().input(on_enabled_checkbox_input),
    ),
    @luna_dom.label(class="flex gap-1 items-center", [
      @luna_dom.text("A:"),
      @luna_dom.input(
        type_="text",
        class="w-16 px-1 py-0.5 bg-slate-700 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("A loop time")),
          ("placeholder", @luna_dom.Attr::AttrString("0:00")),
        ],
        dyn_value=fn() {
          format_time(loop_state.a_time.get().to_milliseconds())
        },
        on=@luna_dom.events().input(on_a_time_input),
      ),
    ]),
    @luna_dom.label(class="flex gap-1 items-center", [
      @luna_dom.text("B:"),
      @luna_dom.input(
        type_="text",
        class="w-16 px-1 py-0.5 bg-slate-700 text-slate-100 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("B loop time")),
          ("placeholder", @luna_dom.Attr::AttrString("0:00")),
        ],
        dyn_value=fn() {
          let b = loop_state.b_time.get().unwrap_or(total_duration())
          format_time(b.to_milliseconds())
        },
        on=@luna_dom.events().input(on_b_time_input),
      ),
    ]),
  ])
}
