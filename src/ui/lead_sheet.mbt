///|
/// Render lead sheet component (chord input + buttons + seekbar)
pub fn render_lead_sheet(
  chord_input : @signal.Signal[String],
  on_generate : () -> Unit,
  on_play_pause : () -> Unit,
  on_seek : (Double) -> Unit,
  playback_state : @signal.Signal[@playback_state.PlaybackState],
  generated_notes : @signal.Signal[Array[@core.Note]],
  is_playing : @signal.Signal[Bool],
) -> @dom.DomNode {
  let on_input : @dom.InputHandler = fn(e) {
    let target = e.target()
    let value = target.nodeValue()
    match value {
      Some(x) => chord_input.set(x)
      None => ()
    }
  }
  @dom.div(
    class="lead-sheet bg-slate-800 p-8 rounded-xl shadow-2xl border-2 border-slate-700",
    [
      @dom.div(class="space-y-4", [
        @dom.input(
          type_="text",
          class="w-full px-4 py-3 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-lg font-mono",
          on=@dom.events().input(on_input),
          dyn_value=fn() { chord_input.get() },
          placeholder="Enter chord progression (e.g., Cm7 F7 Bbmaj7 Ebmaj7)",
        ),
        @dom.div(class="flex gap-4", [
          @dom.button(
            class="flex-1 px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-colors shadow-lg",
            on=@dom.events().click(fn(_) { on_generate() }),
            [@dom.text("Generate Improvisation")],
          ),
          @dom.button(
            dyn_class=fn() {
              if is_playing.get() {
                "flex-1 px-6 py-3 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
              } else {
                "flex-1 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
              }
            },
            on=@dom.events().click(fn(_) { on_play_pause() }),
            [
              @dom.text_dyn(fn() {
                if is_playing.get() {
                  "Pause"
                } else {
                  let state = playback_state.get()
                  if state.current_note_index > 0 {
                    "Resume"
                  } else {
                    "Play"
                  }
                }
              }),
            ],
          ),
        ]),
        // Seekbar below buttons
        render_seekbar(playback_state, generated_notes, on_seek),
      ]),
    ],
  )
}
