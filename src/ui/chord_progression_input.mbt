///|
/// Render chord text input with error display
fn chord_progression_input(
  raw_chord_progression : @signals.Signal[String],
  parse_error : () -> String?,
) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    let value = get_input_value(e)
    raw_chord_progression.set(value)
    set_query_param("chords", value, default=default_chords)
  }

  @luna_dom.div(class="flex flex-col min-w-0 flex-1 gap-0.5", [
    @luna_dom.div(class="flex gap-1 lg:gap-2 min-w-0 flex-1 items-center", [
      @luna_dom.input(
        type_="text",
        dyn_class=fn() {
          cn([
            "min-w-0 flex-1 px-2 lg:px-4 py-1 lg:py-2 bg-slate-900 text-white rounded-lg border focus:outline-none text-sm lg:text-lg font-mono",
            match parse_error() {
              Some(_) => "border-red-500"
              None => "border-slate-600 focus:border-blue-500"
            },
          ])
        },
        on=@luna_dom.events().input(on_input),
        dyn_value=fn() { raw_chord_progression.get() },
        placeholder="Enter chord progression (e.g., IIm7 V7 | Imaj7 | IVmaj7)",
      ),
    ]),
    @luna_dom.show(fn() { parse_error() is Some(_) }, fn() {
      @luna_dom.div(class="flex items-center gap-1 text-red-400 text-xs", [
        @luna_dom.text(
          "⚠ Invalid chord: use Roman numerals (e.g., IIm7 V7 | Imaj7). Qualities: maj7, m7, 7, m7b5, dim7, sus4",
        ),
      ])
    }),
  ])
}
