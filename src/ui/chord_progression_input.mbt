///|
/// Render chord input textarea
fn chord_progression_input(
  raw_chord_progression : @signal.Signal[String],
  parse_error : @signal.Signal[String?],
) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    let value = get_input_value(e)
    raw_chord_progression.set(value)
    set_query_param("chords", value)
  }

  @luna_dom.input(
    type_="text",
    dyn_class=fn() {
      cn([
        "w-full px-4 py-2 bg-slate-900 text-white rounded-lg border focus:outline-none text-lg font-mono",
        match parse_error.get() {
          Some(_) => "border-red-500"
          None => "border-slate-600 focus:border-blue-500"
        },
      ])
    },
    on=@luna_dom.events().input(on_input),
    dyn_value=fn() { raw_chord_progression.get() },
    placeholder="Enter chord progression (e.g., IIm7 V7 | Imaj7 | IVmaj7)",
  )
}
