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
  volume : @signal.Signal[Double],
  is_muted : @signal.Signal[Bool],
  tempo : @signal.Signal[Int],
) -> @dom.DomNode {
  let on_input : @dom.InputHandler = fn(e) {
    let target = e.target()
    let value = target.nodeValue()
    match value {
      Some(x) => chord_input.set(x)
      None => ()
    }
  }
  let on_volume_change : @dom.InputHandler = fn(e) {
    let target = e.target()
    match target.nodeValue() {
      Some(value_str) =>
        match @js_global.parseFloat(value_str) {
          Some(percent) => volume.set(percent / 100.0)
          None => ()
        }
      None => ()
    }
  }
  let on_tempo_change : @dom.InputHandler = fn(e) {
    let target = e.target()
    match target.nodeValue() {
      Some(value_str) =>
        match @js_global.parseInt(value_str) {
          Some(bpm) => if bpm >= 30 && bpm <= 300 { tempo.set(bpm) }
          None => ()
        }
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
          @dom.button(
            dyn_class=fn() {
              if is_muted.get() {
                "px-4 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
              } else {
                "px-4 py-3 bg-slate-600 hover:bg-slate-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
              }
            },
            on=@dom.events().click(fn(_) { is_muted.update(fn(x) { !x }) }),
            [
              @dom.text_dyn(fn() {
                if is_muted.get() {
                  "Unmute"
                } else {
                  "Mute"
                }
              }),
            ],
          ),
          @dom.input(
            type_="range",
            class="flex-1 h-2 bg-slate-700 rounded-lg cursor-pointer accent-blue-500 self-center",
            attrs=[
              ("min", @dom.Attr::AttrInt(0)),
              ("max", @dom.Attr::AttrInt(100)),
              ("step", @dom.Attr::AttrInt(1)),
            ],
            dyn_value=fn() { (volume.get() * 100.0).to_int().to_string() },
            on=@dom.events().input(on_volume_change),
          ),
        ]),
        // Tempo input and seekbar
        @dom.div(class="flex gap-4 items-center", [
          @dom.div(class="flex items-center gap-2", [
            @dom.label(class="text-sm text-slate-400", [@dom.text("BPM:")]),
            @dom.input(
              type_="number",
              class="w-20 px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-center",
              attrs=[
                ("min", @dom.Attr::AttrInt(30)),
                ("max", @dom.Attr::AttrInt(300)),
              ],
              dyn_value=fn() { tempo.get().to_string() },
              on=@dom.events().input(on_tempo_change),
            ),
          ]),
          @dom.div(class="flex-1", [
            render_seekbar(playback_state, generated_notes, on_seek),
          ]),
        ]),
      ]),
    ],
  )
}
