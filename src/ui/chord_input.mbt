///|
/// Render chord input textarea
pub fn render_chord_input(chord_input : @signal.Signal[String]) -> @dom.DomNode {
  let on_input : @dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    chord_input.set(value)
  }
  @dom.input(
    type_="text",
    class="w-full px-4 py-3 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-lg font-mono",
    on=@dom.events().input(on_input),
    dyn_value=fn() { chord_input.get() },
    placeholder="Enter chord progression (e.g., Cm7 F7 Bbmaj7 Ebmaj7)",
  )
}
