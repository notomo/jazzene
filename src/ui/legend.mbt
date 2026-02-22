///|
/// Legend panel for technique highlight colors

///|
/// Technique color legend entry: (label, color, description)
let legend_entries : Array[(String, String, String)] = [
  ("●", "#60a5fa", "Chord Tone (1, 3, 5, 7)"),
  ("●", "#4ade80", "Tension (9, 11, 13)"),
  ("●", "#fb923c", "Approach / Enclosure"),
  ("●", "#fbbf24", "Scale Tone"),
  ("●", "#c084fc", "Guide Tone (3rd/7th)"),
  ("●", "#f472b6", "Motif Replay"),
]

///|
/// Render the legend panel with technique color explanations
pub fn legend_panel(visible : @signals.Signal[Bool]) -> @luna_dom.DomNode {
  let on_toggle = fn(_) { visible.update(fn(v) { not(v) }) }

  @luna_dom.div(class="relative", [
    @luna_dom.button(
      dyn_class=fn() {
        cn([
          "px-2 py-1 text-xs rounded border transition-colors",
          if visible.get() {
            "bg-blue-900 border-blue-500 text-white"
          } else {
            "bg-slate-800 border-slate-600 text-slate-300 hover:border-slate-400"
          },
        ])
      },
      attrs=[("title", @luna_dom.Attr::AttrString("Toggle legend"))],
      on=@luna_dom.events().click(on_toggle),
      [@luna_dom.text("Legend")],
    ),
    @luna_dom.show(fn() { visible.get() }, fn() {
      @luna_dom.fragment([
        @luna_dom.div(
          class="fixed inset-0 z-[9]",
          on=@luna_dom.events().click(fn(_) { visible.set(false) }),
          [],
        ),
        @luna_dom.div(
          class="absolute bottom-full right-0 mb-1 bg-slate-800 border border-slate-600 rounded-lg p-2 lg:p-3 text-xs whitespace-nowrap z-10 shadow-xl",
          [
            @luna_dom.div(class="font-semibold text-slate-300 mb-1.5", [
              @luna_dom.text("Improvisation Techniques"),
            ]),
            @luna_dom.div(
              class="flex flex-col gap-1",
              legend_entries.map(fn(entry) {
                let (dot, color, label) = entry
                @luna_dom.div(class="flex items-center gap-1.5", [
                  @luna_dom.span(
                    class="text-base leading-none",
                    attrs=[
                      ("style", @luna_dom.Attr::AttrString("color: " + color)),
                    ],
                    [@luna_dom.text(dot)],
                  ),
                  @luna_dom.span(class="text-slate-200", [@luna_dom.text(label)]),
                ])
              }),
            ),
            @luna_dom.div(
              class="mt-2 pt-1.5 border-t border-slate-600 text-slate-400",
              [@luna_dom.text("━ Guide tones (3rd/7th) in piano roll")],
            ),
          ],
        ),
      ])
    }),
  ])
}
