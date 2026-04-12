///|
let presets : Array[(String, () -> @music.JazzStyle)] = [
  ("Straight", @music.JazzStyle::straight),
  ("Simple", @music.JazzStyle::simple),
  ("Default", @music.JazzStyle::default),
]

///|
fn preset_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
  settings_section("Preset", [
    @luna_dom.div(
      class="flex flex-wrap gap-1 w-full",
      presets.map(fn(pair) {
        let (label, make_preset) = pair
        @luna_dom.button(
          class="flex-1 text-center px-2 py-0.5 text-xs rounded border bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700 hover:border-slate-400 transition-colors",
          on=@luna_dom.events().click(fn(_) { jazz_style.set(make_preset()) }),
        ) <| [
          @luna_dom.text(label),
        ]
      }),
    ),
  ])
}
