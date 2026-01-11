///|
/// Render chord input textarea
pub fn chord_progression_input(
  raw_chord_progression : @signal.Signal[String],
  parse_error : @signal.Signal[String?],
) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    raw_chord_progression.set(value)
  }
  @luna_dom.input(
    type_="text",
    dyn_class=fn() {
      let base_class = "w-full px-4 py-2 bg-slate-900 text-white rounded-lg border focus:outline-none text-lg font-mono"
      match parse_error.get() {
        Some(_) => base_class + " border-red-500"
        None => base_class + " border-slate-600 focus:border-blue-500"
      }
    },
    on=@luna_dom.events().input(on_input),
    dyn_value=fn() { raw_chord_progression.get() },
    placeholder="Enter chord progression (e.g., Cm7 F7 Bbmaj7 Ebmaj7)",
  )
}
