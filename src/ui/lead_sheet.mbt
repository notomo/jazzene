///|
/// Render lead sheet component (chord input + controls + seekbar)
pub fn render_lead_sheet(
  chord_input : @signal.Signal[String],
  on_play_pause : () -> Unit,
  on_seek : (Double) -> Unit,
  is_playing : @signal.Signal[Bool],
  position_ms : @signal.Signal[Int],
  total_duration_ms : @signal.Signal[Int],
  has_notes : @signal.Signal[Bool],
  tempo : @signal.Signal[Int],
  volume : @signal.Signal[Double],
  is_muted : @signal.Signal[Bool],
) -> @dom.DomNode {
  let on_input : @dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    chord_input.set(value)
  }
  @dom.div(
    class="lead-sheet bg-slate-800 p-8 rounded-xl shadow-2xl border-2 border-slate-700",
    [
      @dom.div(class="space-y-4", [
        // Chord input textarea
        @dom.input(
          type_="text",
          class="w-full px-4 py-3 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-lg font-mono",
          on=@dom.events().input(on_input),
          dyn_value=fn() { chord_input.get() },
          placeholder="Enter chord progression (e.g., Cm7 F7 Bbmaj7 Ebmaj7)",
        ),

        // Playback controls
        render_controls(on_play_pause, is_playing, volume, is_muted, tempo),

        // Seekbar
        @dom.div(class="flex-1", [
          render_seekbar(position_ms, total_duration_ms, has_notes, on_seek),
        ]),
      ]),
    ],
  )
}
