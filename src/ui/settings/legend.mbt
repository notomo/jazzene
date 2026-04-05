///|
/// Technique color legend entry: (label, color, description)
let legend_entries : Array[(String, String, String)] = [
  ("●", @theme.COLOR_CHORD_TONE, "Chord Tone (1, 3, 5, 7)"),
  ("●", @theme.COLOR_TENSION, "Tension (9, 11, 13)"),
  ("●", @theme.COLOR_APPROACH, "Chromatic Approach"),
  ("●", @theme.COLOR_PASSING_TONE, "Bebop Passing Tone"),
  ("●", @theme.COLOR_ENCLOSURE, "Enclosure"),
  ("●", @theme.COLOR_NEIGHBOR, "Neighbor Tone"),
  ("●", @theme.COLOR_COMPING, "Comping"),
  ("●", @theme.COLOR_MIDI_ACTIVE, "MIDI Input"),
  ("●", @theme.COLOR_MIDI_IMPORTED, "MIDI Imported"),
]

///|
fn legend_section(
  show_technique_hints : @signals.Signal[Bool],
) -> @luna_dom.DomNode {
  settings_section("Legend", [
    toggle_switch(
      label="Technique Hints",
      value=fn() { show_technique_hints.get() },
      on_toggle=fn() { show_technique_hints.update(fn(v) { !v }) },
    ),
    @luna_dom.div(
      class="flex flex-col gap-1",
      legend_entries.map(fn(entry) {
        let (dot, color, label) = entry
        @luna_dom.div(class="flex items-center gap-1.5", [
          @luna_dom.span(
            dyn_class=fn() { "text-xs leading-none" },
            dyn_attrs=[
              (
                "style",
                @luna_dom.AttrValue::Dynamic(fn() {
                  let c = if show_technique_hints.get() ||
                    color == @theme.COLOR_COMPING ||
                    color == @theme.COLOR_MIDI_ACTIVE ||
                    color == @theme.COLOR_MIDI_IMPORTED {
                    color
                  } else {
                    @theme.COLOR_CHORD_TONE
                  }
                  "color: " + c
                }),
              ),
            ],
            [@luna_dom.text(dot)],
          ),
          @luna_dom.span(class="text-xs text-slate-200", [@luna_dom.text(label)]),
        ])
      }),
    ),
  ])
}
