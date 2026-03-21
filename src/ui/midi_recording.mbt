///|
/// MIDI input recording controls.
/// Shows a record toggle button and a list of completed recorded lines,
/// each with Off/Silent/On mode buttons and a delete button.

///|
let recorded_line_mode_options : Array[(String, @music.MelodyMode)] = [
  ("Off", @music.Off),
  ("Silent", @music.Silent),
  ("On", @music.On),
]

///|
pub fn midi_recording(
  is_recording : @signals.Signal[Bool],
  recorded_lines : @signals.Signal[Array[RecordedLine]],
) -> @luna_dom.DomNode {
  @luna_dom.div(class="flex flex-col gap-1.5", [
    // Record toggle button
    @luna_dom.button(
      dyn_class=fn() {
        let base = "flex items-center justify-center gap-1.5 w-full px-2 py-1 text-xs rounded border transition-colors"
        if is_recording.get() {
          base + " bg-cyan-900 border-cyan-500 text-cyan-300"
        } else {
          base +
          " bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700"
        }
      },
      on=@luna_dom.events().click(fn(_) { is_recording.update(not) }),
      attrs=[("aria-label", @luna_dom.Attr::AttrString("toggle recording"))],
      [
        @luna_dom.span(
          dyn_class=fn() {
            if is_recording.get() {
              "text-cyan-400 text-sm leading-none"
            } else {
              "text-slate-500 text-sm leading-none"
            }
          },
          [@luna_dom.text("●")],
        ),
        @luna_dom.span(class="text-xs", [
          @luna_dom.text_dyn(fn() {
            if is_recording.get() {
              "Stop Recording"
            } else {
              "Start Recording"
            }
          }),
        ]),
      ],
    ),
    // Recorded line list
    @luna_dom.for_each(fn() { recorded_lines.get() }, fn(line, i) {
      @luna_dom.div(class="flex items-center gap-1", [
        // Line label with MIDI_ACTIVE color
        @luna_dom.span(
          class="text-xs shrink-0",
          attrs=[
            (
              "style",
              @luna_dom.Attr::AttrString("color: " + @theme.COLOR_MIDI_ACTIVE),
            ),
          ],
          [@luna_dom.text("● Rec \{i + 1}")],
        ),
        // Off/Silent/On mode buttons
        segmented_buttons(
          recorded_line_mode_options,
          fn() { line.mode.get() },
          fn(v) { line.mode.set(v) },
        ),
        // Delete button
        @luna_dom.button(
          class="p-0.5 text-xs text-slate-500 hover:text-red-400 shrink-0",
          on=@luna_dom.events().click(fn(_) {
            let id = line.id
            recorded_lines.update(fn(lines) {
              lines.filter(fn(l) { l.id != id })
            })
          }),
          attrs=[
            ("aria-label", @luna_dom.Attr::AttrString("delete recorded line")),
          ],
          [@luna_dom.text("✕")],
        ),
      ])
    }),
  ])
}
