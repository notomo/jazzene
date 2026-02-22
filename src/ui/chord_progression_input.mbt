///|
/// Jazz chord progression presets: (name, chord string)
let chord_presets : Array[(String, String)] = [
  ("Custom", ""),
  ("II-V-I (C)", "IIm7 | V7 | Imaj7 | Imaj7"),
  (
    "Blues (F)", "I7 | IV7 | I7 | I7 | IV7 | IV7 | I7 | VIm7 IIm7 | V7 | V7 | I7 V7 | I7",
  ),
  ("Rhythm Changes A", "Imaj7 VIm7 | IIm7 V7 | IIIm7 VIm7 | IIm7 V7"),
  ("Autumn Leaves", "IIm7 | V7 | Imaj7 | IVmaj7 | VIIm7b5 | III7 | VIm7 | VIm7"),
]

///|
/// Render chord input with preset dropdown
fn chord_progression_input(
  raw_chord_progression : @signals.Signal[String],
  parse_error : () -> String?,
) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    let value = get_input_value(e)
    raw_chord_progression.set(value)
    set_query_param("chords", value, default=default_chords)
  }

  let preset_options = chord_presets.map(fn(p) { p.0 })

  let on_preset_change : (String) -> Unit = fn(name) {
    let chords_opt = chord_presets
      .iter()
      .filter_map(fn(p) {
        let (preset_name, preset_chords) = p
        if preset_name == name && preset_chords != "" {
          Some(preset_chords)
        } else {
          None
        }
      })
      .next()
    match chords_opt {
      Some(chords) => {
        raw_chord_progression.set(chords)
        set_query_param("chords", chords, default=default_chords)
      }
      None => ()
    }
  }

  @luna_dom.div(class="flex flex-col min-w-0 flex-1 gap-0.5", [
    @luna_dom.div(class="flex gap-1 lg:gap-2 min-w-0 flex-1 items-center", [
      @luna_dom.create_element(
        "select",
        [
          (
            "class",
            @luna_dom.AttrValue::Static(
              "shrink-0 px-1 lg:px-2 py-1 lg:py-2 bg-slate-900 text-white text-xs lg:text-sm rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
            ),
          ),
          (
            "aria-label",
            @luna_dom.AttrValue::Static("chord progression preset"),
          ),
          (
            "change",
            @luna_dom.AttrValue::Handler(fn(e) {
              on_preset_change(get_event_target_value(e))
            }),
          ),
        ],
        preset_options.map(fn(name) {
          @luna_dom.create_element(
            "option",
            [("value", @luna_dom.AttrValue::Static(name))],
            [@luna_dom.text(name)],
          )
        }),
      ),
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
