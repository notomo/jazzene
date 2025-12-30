///|
/// Format milliseconds as "M:SS"
fn format_time(ms : Int) -> String {
  let total_seconds = ms / 1000
  let minutes = total_seconds / 60
  let seconds = total_seconds % 60
  minutes.to_string() +
  ":" +
  (if seconds < 10 { "0" } else { "" }) +
  seconds.to_string()
}

///|
/// Render seekbar UI component
pub fn render_seekbar(
  playback_state : @signal.Signal[@playback_state.PlaybackState],
  generated_notes : @signal.Signal[Array[@core.Note]],
  on_seek : (Double) -> Unit,
) -> @dom.DomNode {
  @dom.div(class="p-4 bg-slate-800", [
    // Time display: "0:00 / 2:30"
    @dom.div(class="flex justify-between text-sm text-slate-400 mb-2", [
      @dom.text_dyn(fn() {
        let state = playback_state.get()
        format_time(state.playback_position_ms)
      }),
      @dom.text_dyn(fn() {
        let state = playback_state.get()
        format_time(state.total_duration_ms)
      }),
    ]),

    // Range slider with Tailwind styling
    @dom.input(
      type_="range",
      class="w-full h-2 bg-slate-700 rounded-lg cursor-pointer accent-blue-500 disabled:opacity-50 disabled:cursor-not-allowed",
      attrs=[
        ("min", @dom.Attr::AttrInt(0)),
        ("max", @dom.Attr::AttrInt(100)),
        ("step", @dom.Attr::AttrInt(1)),
      ],
      dyn_value=fn() {
        let state = playback_state.get()
        if state.total_duration_ms == 0 {
          "0"
        } else {
          let percent = state.playback_position_ms.to_double() /
            state.total_duration_ms.to_double() *
            100.0
          percent.to_int().to_string()
        }
      },
      dyn_disabled=fn() { generated_notes.get().length() == 0 },
      on=@dom.events().input(fn(e) {
        let target = e.target()
        match target.nodeValue() {
          Some(value_str) =>
            match @js_global.parseFloat(value_str) {
              Some(percent) => on_seek(percent)
              None => ()
            }
          None => ()
        }
      }),
    ),
  ])
}
