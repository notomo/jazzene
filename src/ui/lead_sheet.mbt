///|
/// Render lead sheet component (chord input + buttons)
pub fn render_lead_sheet(
  chord_input : @signal.Signal[String],
  on_generate : () -> Unit,
  on_play : () -> Unit,
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
    class="lead-sheet bg-slate-800 p-8 rounded-xl shadow-2xl border border-slate-700",
    [
      @dom.h2(class="text-2xl font-bold mb-6 text-blue-400", [
        @dom.text("Lead Sheet"),
      ]),
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
                "flex-1 px-6 py-3 bg-gray-600 text-white rounded-lg font-semibold shadow-lg cursor-not-allowed"
              } else {
                "flex-1 px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
              }
            },
            on=@dom.events().click(fn(_) {
              if not(is_playing.get()) {
                on_play()
              }
            }),
            [
              @dom.text_dyn(fn() {
                if is_playing.get() {
                  "Playing..."
                } else {
                  "Play"
                }
              }),
            ],
          ),
        ]),
      ]),
    ],
  )
}
